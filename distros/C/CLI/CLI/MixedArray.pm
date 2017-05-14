package CLI::MixedArray;
use CLI::Base;
@ISA = ("CLI::Base");

use Carp;

use CLI qw(parse_string typeStr);
use CLI::Var;
use strict;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $name = shift;
  my $types = shift;
  my $vals = shift;

  my $self  = {
	       NAME => $name,
	       TYPE => undef,
	       VALUE => [],
	       FUNC => undef,
	       MIN => undef,
	       MAX => undef
	      };
  bless ($self, $class);

  foreach my $type (@$types) {
    push @{$self->{VALUE}}, new CLI::Var($name, $type, shift @{$vals});
  }

  return $self;
}

sub TIEARRAY {
  return new(@_);
}

sub value {
  my $self = shift;
  my $index = shift;
  my $value = shift;

  if (!defined $index) { # Return the whole lot as a list
    my @return = ();
    foreach (@{$self->{VALUE}}) {
      push @return, $_->value();
    }
    return @return;
  } else {
    # Verify the index value
    if ($index<0 || $index>=scalar(@{$self->{VALUE}})) {
      carp "Index $index out of range";
      return undef;
    }

    if  (!defined $value) { # Return a value
      return $self->{VALUE}[$index]->value();
    } else { # Save the value
      return $self->{VALUE}[$index]->value($value);
    }
  }
}

sub FETCH {
  return value(@_);
}

sub STORE {
  value(@_);
}

sub parse {
  my $self = shift;
  my $string = shift;

  if (defined $string) {
    my $value;
    foreach my $val (@{$self->{VALUE}}) {
      $value = parse_string($val->type(), $string);
      if (! defined $value) {
	carp "Bad value \"$string\" for type ", typeStr($val->type()), "\n";
	return;
      }

      $val->value($value);

      return if (!defined $string); # End of list
    }
  } else { # Print out the values in the list
    print $self->name();
    foreach my $val (@{$self->{VALUE}}) {
      print ' ', $val->svalue();
    }
    print "\n";
  }
  if (defined $string) { # Some characters left over
    carp "Ignoring \"$string\"\n";
  }
}

1;

