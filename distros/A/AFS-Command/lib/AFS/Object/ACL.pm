#
# $Id$
#
# (c) 2003-2004 Morgan Stanley and Co.
# See ..../src/LICENSE for terms of distribution.
#

package AFS::Object::ACL;

use strict;

our @ISA = qw(AFS::Object);
our $VERSION = '1.99';

sub getPrincipals {
    my $self = shift;
    return unless ref $self->{_principals};
    return keys %{$self->{_principals}};
}

sub getRights {
    my $self = shift;
    my $principal = shift;
    return unless ref $self->{_principals};
    return $self->{_principals}->{lc($principal)};
}

sub getEntries {
    my $self = shift;
    return unless ref $self->{_principals};
    return %{$self->{_principals}};
}

sub _addEntry {
    my $self = shift;
    my $principal = shift;
    my $rights = shift;
    return $self->{_principals}->{$principal} = $rights;
}

1;
