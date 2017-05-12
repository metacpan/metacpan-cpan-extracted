use strict;
use warnings;
package Device::SerialPort;

# Copyright 2012 Mark Hindess

sub TIEHANDLE {
  bless { calls => [], args => \@_ }, __PACKAGE__;
}

sub DESTROY {
}

sub args {
  my $self = shift;
  $self->{args};
}

sub calls {
  my $self = shift;
  $self->{calls};
}

sub AUTOLOAD {
  my $self = shift;
  our $AUTOLOAD;
  push @{$self->{calls}}, [$AUTOLOAD, @_];
}

1;
