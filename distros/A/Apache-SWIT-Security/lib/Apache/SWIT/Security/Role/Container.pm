use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Security::Role::Container::Item;
use base 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(id name));

package Apache::SWIT::Security::Role::Container;
use Carp;
use Data::Dumper;

sub new {
	my ($class, $roles) = @_;
	my %roles;
	while (my ($id, $v) = each %$roles) {
		$roles{$id} = Apache::SWIT::Security::Role::Container::Item
				->new({ id => $id, name => $v });
	}
	return bless { _roles => \%roles }, $class;
}

sub find_role_by_id {
	my ($self, $role_id) = @_;
	my $res = $self->{_roles}->{ $role_id }
		or confess "Unable to find $role_id in " . Dumper($self);
	return $res;
}

sub find_role_by_name {
	my ($self, $name) = @_;
	my ($res) = grep { $_->name eq $name } values %{ $self->{_roles} };
	return $res;
}

sub roles_list {
	my $self = shift;
	my @res;
	while (my ($n, $v) = each %{ $self->{_roles} }) {
		push @res, [ $n, $v->name ];
	}
	return sort { $a->[0] <=> $b->[0] } @res;
}

1;
