#
# $Id$
#
# (c) 2003-2004 Morgan Stanley and Co.
# See ..../src/LICENSE for terms of distribution.
#

package AFS::Object;

use strict;
use Carp;

our $AUTOLOAD = "";
our $VERSION = '1.99';

our %Carp =
  (
   carp		=> \&Carp::carp,
   croak	=> \&Carp::croak,
  );

sub _setCarp {
    my $class = shift;
    my (%args) = @_;
    foreach my $key ( keys %args ) {
	$Carp{$key} = $args{$key};
    }
    return 1;
}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = { _attrs	=> { @_ } };
    return bless $self, $class;
}

sub listAttributes {
    my $self = shift;
    return keys %{$self->{_attrs}};
}

sub getAttribute {
    my $self = shift;
    my $attr = shift;
    return $self->{_attrs}->{$attr};
}

sub getAttributes {
    my $self = shift;
    my $attr = shift;
    return %{$self->{_attrs}};
}

sub hasAttribute {
    my $self = shift;
    my $attr = shift;
    return exists $self->{_attrs}->{$attr};
}

sub _Carp {
    my $self = shift;
    $Carp{carp}->(@_);
}

sub _Croak {
    my $self = shift;
    $Carp{croak}->(@_);
}

sub _setAttribute {
    my $self = shift;
    my (%attrs) = @_;
    foreach my $attr ( keys %attrs ) {
	$self->{_attrs}->{$attr} = $attrs{$attr};
    }
    return 1;
}

sub DESTROY {}

sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;
    $attr =~ s/.*:://;
    return $self->{_attrs}->{$attr};
}

1;
