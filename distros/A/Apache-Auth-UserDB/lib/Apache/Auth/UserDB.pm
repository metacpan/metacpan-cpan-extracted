#
# Apache::Auth::UserDB
# An Apache user database manager class.
#
# (C) 2003-2007 Julian Mehnle <julian@mehnle.net>
# $Id: UserDB.pm 31 2007-09-18 01:39:14Z julian $
#
##############################################################################

package Apache::Auth::UserDB;

=head1 NAME

Apache::Auth::UserDB - Manipulation of Apache user authentication databases

=cut

use version; our $VERSION = qv('0.120');

use warnings;
use strict;

use Carp;

# Constants:
##############################################################################

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

# Interface:
##############################################################################

sub new;

sub clear;
sub commit;
sub users;

sub get_user;
sub search_users;
sub add_user;
sub delete_user;

# Implementation:
##############################################################################

sub new {
    my ($class, %options) = @_;
    
    my $self = bless(
        {
            users       => [],
            %options
        },
        $class
    );
    
    return $self;
}

sub clear {
    my ($self) = @_;
    $self->{users} = [];
    return $self;
}

sub commit {
    my ($self) = @_;
    return $self->_write();
}

sub users {
    my ($self) = @_;
    return @{ $self->{users} };
}

sub get_user {
    my ($self, %params) = @_;
    
    my @users = $self->search_users(%params);
    if (@users > 1) {
        carp(
            "There are multiple users matching your search criteria, returning *none*" .
            "for safety purposes. Fix your selection criteria or use search_users()!"
        );
        return undef;
    }
    elsif (@users == 0) {
        return undef;
    }
    else {
        return $users[0];
    }
}

sub search_users {
    my ($self, %params) = @_;
    
    my @users;
    foreach my $user (@{$self->{users}}) {
        my $match = TRUE;
        foreach my $field (keys(%params)) {
            my $pattern = $params{$field};
            $match = FALSE
                if (
                    ref($pattern) eq 'Regexp' ?
                        $user->$field() !~ $pattern
                    :   $user->$field() ne $pattern
                );
        }
        push(@users, $user) if $match;
    }
    
    return @users;
}

sub add_user {
    my ($self, $user) = @_;
    
    # Delete existing old user first:
    foreach my $old_user (@{$self->{users}}) {
        if ($user eq $old_user) {
            $self->delete_user($old_user);
            last;
        }
    }
    
    # Add new user:
    push(@{$self->{users}}, $user);
    
    return $self;
}

sub delete_user {
    my ($self, $user) = @_;
    $self->{users} = [ grep($_ ne $user, @{$self->{users}}) ]
        if $user;
    return $self;
}

TRUE;
