#
# Apache::Auth::User
# An Apache authentication user class.
#
# (C) 2003-2007 Julian Mehnle <julian@mehnle.net>
# $Id: User.pm 31 2007-09-18 01:39:14Z julian $
#
##############################################################################

package Apache::Auth::User;

use version; our $VERSION = qv('0.120');

use warnings;
use strict;

use overload
    '""'        => 'signature',
    fallback    => 1;

# Constants:
##############################################################################

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

# Interface:
##############################################################################

sub new;

sub name;
sub password;
sub password_digest;

# Implementation:
##############################################################################

sub new {
    my ($class, %options) = @_;
    my $self = bless(\%options, $class);
    return $self;
}

sub name {
    my ($self, @value) = @_;
    $self->{name} = $value[0] if @value;
    return $self->{name};
}

sub password {
    my ($self, @value) = @_;
    if (@value) {
        $self->{password} = $value[0];
        $self->{password_digest} = undef;
    }
    return $self->{password};
}

sub password_digest {
    my ($self, @value) = @_;
    if (@value) {
        $self->{password_digest} = $value[0];
    }
    elsif (not defined($self->{password_digest})) {
        $self->{password_digest} = $self->_build_password_digest();
    }
    return $self->{password_digest};
}

TRUE;
