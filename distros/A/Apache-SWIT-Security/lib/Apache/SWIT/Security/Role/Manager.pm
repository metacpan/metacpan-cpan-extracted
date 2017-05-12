use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Security::Role::Manager;
use Carp;

use constant ALL => 9999;

sub new {
	my ($class, $url_data, $rule_perms, $caps) = @_;
	my $acc = 'Apache::SWIT::Security::Role::Manager::Accessor';
	my @rules;
	for my $r (@$rule_perms) {
		my $re = shift @$r;
		push @rules, [ qr#$re#, $acc->new({ perms => $r }) ];
	}

	my %urls;
	while (my ($n, $v) = each %$url_data) {
		for my $r (reverse @rules) {
			unshift @{ $v->{perms} }, @{ $r->[1]->{_perms} }
					if ($n =~ $r->[0] && $r->[1]);
		}
		$urls{$n} = $acc->new($v);
	}

	$caps ||= {};
	my %caps = map { ($_, $acc->new({ perms => $caps->{$_} })) }
			keys %$caps;
	return bless({ _urls => \%urls, _rules => \@rules
			, _capabilities => \%caps }, $class);
}

sub access_control {
	my ($self, $url) = @_;
	my $res = $self->{_urls}->{$url};
	return $res if $res;

	for my $r (@{ $self->{_rules} }) {
		return $r->[1] if $url =~ $r->[0];
	}
	return undef;
}

sub capability_control {
	my ($self, $cap) = @_;
	my $res = $self->{_capabilities}->{$cap} 
		or confess "# Unknown capability $cap";
	return $res;
}

sub add_uri_access_control {
	my ($self, $url, $param) = @_;
	$self->{_urls}->{$url} =
		Apache::SWIT::Security::Role::Manager::Accessor->new($param);
}

package Apache::SWIT::Security::Role::Manager::Accessor;

sub new {
	my ($class, $uentry) = @_;
	my $perms = $uentry->{perms};
	return unless (($perms && @$perms) || $uentry->{hook_func});
	return bless({ _perms => $perms
		, _hook_class => $uentry->{hook_class}
		, _hook_func => $uentry->{hook_func}
	}, $class);
}

sub check_user {
	my ($self, $user, $req) = @_;
	my %gids = map { ($_, 1) } ($user ? $user->role_ids : ());
	my $res;
	for my $p (@{ $self->{_perms} }) {
		last if ($p == -1*Apache::SWIT::Security::Role::Manager::ALL);
		if ($p == Apache::SWIT::Security::Role::Manager::ALL) {
			$res = 1;
			last;
		}
		next unless $gids{ abs($p) };
		$res = 1 if $p > 0;
		last;
	}
	return $res if $res;
	my $hf = $self->{_hook_func} or return;
	return $self->{_hook_class}->$hf($req);
}

1;
