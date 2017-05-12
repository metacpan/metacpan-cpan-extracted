# Copyright (c) 2015 Jerry Lundström <lundstrom.jerry@gmail.com>
# Copyright (c) 2015 .SE (The Internet Infrastructure Foundation)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package Crypt::PKCS11::Attribute::AttributeArray;

use common::sense;
use Carp;
use Scalar::Util qw(blessed);

use base qw(Crypt::PKCS11::Attribute);

sub push {
    my ($self) = CORE::shift;

    CORE::foreach (@_) {
        unless (blessed($_) and $_->isa('Crypt::PKCS11::Attribute')) {
            confess 'Value to push is not a Crypt::PKCS11::Attribute object';
        }
    }
    CORE::push(@{$self->{attributes}}, @_);

    return $self;
}

sub pop {
    return CORE::pop(@{$_[0]->{attributes}});
}

sub shift {
    return CORE::shift(@{$_[0]->{attributes}});
}

sub unshift {
    my ($self) = CORE::shift;

    CORE::foreach (@_) {
        unless (blessed($_) and $_->isa('Crypt::PKCS11::Attribute')) {
            confess 'Value to unshift is not a Crypt::PKCS11::Attribute object';
        }
    }
    CORE::unshift(@{$self->{attributes}}, @_);

    return $self;
}

sub foreach {
    my ($self, $cb) = @_;

    unless (ref($cb) eq 'CODE') {
        confess '$cb argument is not CODE';
    }
    CORE::foreach (@{$self->{attributes}}) {
        $cb->($_);
    }

    return $self;
}

sub toArray {
    my ($self) = @_;
    my @array;

    CORE::foreach (@{$self->{attributes}}) {
        CORE::push(@array, { type => $_->type, pValue => $_->pValue });
    }

    return \@array;
}

sub set {
    my $self = CORE::shift;

    foreach (@_) {
        unless (blessed($_) and $_->isa('Crypt::PKCS11::Attribute')) {
            confess 'Value to set is not a Crypt::PKCS11::Attribute object';
        }
    }

    $self->{attributes} = [ @_ ];

    return $self;
}

sub pValue {
    return $_[0]->toArray;
}

1;

__END__
