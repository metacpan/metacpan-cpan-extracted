package Class::Anonymous::Instance;

use strict;
use warnings;
use Carp ();

sub AUTOLOAD {
  my $self = $_[0];
  my ($name) = our $AUTOLOAD =~ /::(\w+)$/;
  my $func = $self->($name) or Carp::croak "Instance of anonymous class has no method $name";
  goto $func;
}

sub DESTROY { }

sub can { $_[0]->($_[1]) }

sub isa { goto $_[0]->('isa') }

1;

