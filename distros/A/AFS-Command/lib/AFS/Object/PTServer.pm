#
# $Id$
#
# (c) 2003-2004 Morgan Stanley and Co.
# See ..../src/LICENSE for terms of distribution.
#

package AFS::Object::PTServer;

use strict;

our @ISA = qw(AFS::Object);
our $VERSION = '1.99';

sub getGroupNames {
    my $self = shift;
    return unless ref $self->{_groups} && ref $self->{_groups}->{_byName};
    return keys %{$self->{_groups}->{_byName}};
}

sub getGroupIds {
    my $self = shift;
    return unless ref $self->{_groups} && ref $self->{_groups}->{_byId};
    return keys %{$self->{_groups}->{_byId}};
}

sub getGroups {
    my $self = shift;
    return unless ref $self->{_groups} && ref $self->{_groups}->{_byName};
    return values %{$self->{_groups}->{_byName}};
}

sub getGroupByName {
    my $self = shift;
    my $name = shift;
    return unless ref $self->{_groups} && ref $self->{_groups}->{_byName};
    return $self->{_groups}->{_byName}->{lc($name)};
}

sub getGroupById {
    my $self = shift;
    my $id = shift;
    return unless ref $self->{_groups} && ref $self->{_groups}->{_byId};
    return $self->{_groups}->{_byId}->{$id};
}

sub getGroup {

    my $self = shift;
    my (%args) = @_;

    if ( exists $args{id} && exists $args{name} ) {
	$self->_Carp("Invalid arguments: both of 'id' or 'name' may not be specified");
	return;
    }

    unless ( exists $args{id} || exists $args{name} )  {
	$self->_Carp("Invalid arguments: at least one of 'id' or 'name' must be specified");
	return;
    }

    if ( exists $args{id} ) {
	return unless ref $self->{_groups} && ref $self->{_groups}->{_byId};
	return $self->{_groups}->{_byId}->{$args{id}};
    }

    if ( exists $args{name} ) {
	return unless ref $self->{_groups} && ref $self->{_groups}->{_byName};
	return $self->{_groups}->{_byName}->{lc($args{name})};
    }

}

sub _addGroup {

    my $self = shift;
    my $group = shift;

    unless ( ref $group && $group->isa("AFS::Object::Group") ) {
	$self->_Croak("Invalid argument: must be an AFS::Object::Group object");
    }

    if ( $group->hasAttribute('name') ) {
	my $name = $group->name();
	$self->{_groups}->{_byName}->{$name} = $group;
    } else {
	$self->_Croak("Group has no name attribute!!\n" .
		      Data::Dumper->Dump([$group],['group']));
    }

    if ( $group->hasAttribute('id') ) {
	my $id = $group->id();
	$self->{_groups}->{_byId}->{$id} = $group;
    } else {
	$self->_Croak("Group has no id attribute!!\n" .
		      Data::Dumper->Dump([$group],['group']));
    }

    return 1;

}

sub getUserNames {
    my $self = shift;
    return unless ref $self->{_users} && ref $self->{_users}->{_byName};
    return keys %{$self->{_users}->{_byName}};
}

sub getUserIds {
    my $self = shift;
    return unless ref $self->{_users} && ref $self->{_users}->{_byId};
    return keys %{$self->{_users}->{_byId}};
}

sub getUsers {
    my $self = shift;
    return unless ref $self->{_users} && ref $self->{_users}->{_byName};
    return values %{$self->{_users}->{_byName}};
}

sub getUserByName {
    my $self = shift;
    my $name = shift;
    return unless ref $self->{_users} && ref $self->{_users}->{_byName};
    return $self->{_users}->{_byName}->{lc($name)};
}

sub getUserById {
    my $self = shift;
    my $id = shift;
    return unless ref $self->{_users} && ref $self->{_users}->{_byId};
    return $self->{_users}->{_byId}->{$id};
}

sub getUser {

    my $self = shift;
    my (%args) = @_;

    if ( exists $args{id} && exists $args{name} ) {
	$self->_Carp("Invalid arguments: both of 'id' or 'name' may not be specified");
	return;
    }

    unless ( exists $args{id} || exists $args{name} )  {
	$self->_Carp("Invalid arguments: at least one of 'id' or 'name' must be specified");
	return;
    }

    if ( exists $args{id} ) {
	return unless ref $self->{_users} && ref $self->{_users}->{_byId};
	return $self->{_users}->{_byId}->{$args{id}};
    }

    if ( exists $args{name} ) {
	return unless ref $self->{_users} && ref $self->{_users}->{_byName};
	return $self->{_users}->{_byName}->{lc($args{name})};
    }

}

sub _addUser {

    my $self = shift;
    my $user = shift;

    unless ( ref $user && $user->isa("AFS::Object::User") ) {
	$self->_Croak("Invalid argument: must be an AFS::Object::User object");
    }

    if ( $user->hasAttribute('name') ) {
	my $name = $user->name();
	$self->{_users}->{_byName}->{$name} = $user;
    } else {
	$self->_Croak("User has no name attribute!!\n" .
		      Data::Dumper->Dump([$user],['user']));
    }

    if ( $user->hasAttribute('id') ) {
	my $id = $user->id();
	$self->{_users}->{_byId}->{$id} = $user;
    } else {
	$self->_Croak("User has no id attribute!!\n" .
		      Data::Dumper->Dump([$user],['user']));
    }

    return 1;

}

1;
