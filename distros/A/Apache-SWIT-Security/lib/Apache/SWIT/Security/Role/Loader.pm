use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Security::Role::Loader;
use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(roles_container url_manager));

use Apache::SWIT::Security::Role::Container;
use Apache::SWIT::Security::Role::Manager;

sub load_role_container {
	my ($self, $roles) = @_;
	my $c = Apache::SWIT::Security::Role::Container->new($roles);
	$self->roles_container($c);
}

sub parse_permissions {
	my ($self, $perms) = @_;
	my @p;
	for (@$perms) {
		s/^([+-])//;
		my $sign = $1;
		my $id = $_ eq 'all' ?
			Apache::SWIT::Security::Role::Manager::ALL
			: $self->roles_container->find_role_by_name($_)->id;
		push @p, ($sign eq '-') ? -1*$id : $id;
	}
	return \@p;
}

sub load {
	my ($self, $tree) = @_;
	my %urls;
	$tree->for_each_url(sub {
		my ($url, $pname, $pentry, $ep) = @_; 
		my $ps = $ep->{permissions};
		$urls{$url}->{perms} = $self->parse_permissions($ps);
		$urls{$url}->{hook_class} = $pentry->{class};
		$urls{$url}->{hook_func} = $ep->{security_hook};
	});

	my @rps;
	for my $rp (@{ $tree->{rule_permissions} || [] }) {
		my @r = (shift @$rp);
		push @r, @{ $self->parse_permissions($rp) };
		push @rps, \@r;
	}
	my $cs = $tree->{capabilities} || {};
	my %caps = map { ($_, $self->parse_permissions($cs->{$_})) }
			keys %$cs;
	my $mgr = Apache::SWIT::Security::Role::Manager->new(\%urls, \@rps
			, \%caps);
	$self->url_manager($mgr);
}

1;
