#
# Apache::Auth::User::Basic
# An Apache basic authentication user class.
#
# (C) 2003-2007 Julian Mehnle <julian@mehnle.net>
# $Id: Basic.pm 31 2007-09-18 01:39:14Z julian $
#
##############################################################################

package Apache::Auth::User::Basic;

use version; our $VERSION = qv('0.120');

use warnings;
use strict;

use base qw(Apache::Auth::User);

use Carp;

# Constants:
##############################################################################

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

use constant crypt_salt_characters  => ('.', '/', '0'..'9', 'A'..'Z', 'a'..'z');

# Interface:
##############################################################################

sub signature;
sub password;

# Implementation:
##############################################################################

sub signature {
    my ($self) = @_;
    return $self->name;
}

sub password {
    my ($self, @value) = @_;
    if (@value) {
        $self->{password} = $value[0];
        $self->{password_digest} = $self->_build_password_digest
            if defined($self->{password});
    }
    return $self->{password};
}

sub _build_password_digest {
    my ($self) = @_;
    
    croak("Unable to build password digest from incomplete data")
        if not defined($self->{password});
    
    return crypt(
        $self->{password},
        join('', ($self->crypt_salt_characters)[rand(64), rand(64)])
    );
}

TRUE;
