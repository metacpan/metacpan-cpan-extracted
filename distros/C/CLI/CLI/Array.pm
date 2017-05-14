package CLI::Array;
use CLI::Base;
@ISA = ("CLI::Base");

use Carp;

use CLI qw(parse_string typeStr string_value);
#use CLI::Var;
use strict;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $name = shift;
  my $type = shift;
  my $vals = shift; # List reference
  my $hash = shift;

  my $self  = {
	       NAME => $name,
	       TYPE => $type,
	       VALUE => [],
	       FUNC => undef,
	       MIN => undef,
	       MAX => undef
	      };
  bless ($self, $class);

  $self->function($hash->{function}) if (defined $hash->{function});
  $self->min($hash->{min}) if (defined $hash->{min});
  $self->max($hash->{max}) if (defined $hash->{max});

  my $i = 0;
  foreach my $val (@$vals) {
    $self->value($i, $val);
    $i++;
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
    return @{$self->{VALUE}};
  } else {
    # Verify the index value
    if ($index<0) {
      carp "Index $index out of range";
      return undef;
    }
    if  (!defined $value) { # Return a value
      return $self->{VALUE}[$index];
    } else { # Save the value
      my $oldvalue = $self->{VALUE}[$index];
      my $min = $self->min();
      my $max = $self->max();
      my $inrange = 1;

      # Is the value in range?
      if (defined $min) {
	if ($value<$min) {
	  warn " $value less than minimum ($min)\n";
	  $inrange = 0;
	  $max = undef; # Stop pathological case of complaining about min and max
	}
      }
      if (defined $max) {
	if ($value>$max) {
	  warn " $value greater than maximum ($max)\n";
	  $inrange = 0;
	}
      }

      if ($inrange) {
	$self->{VALUE}[$index] = $value;
	if (defined $self->function()) {
	  my $type = $self->type();
	  if ($type eq 'STRING' || $type eq 'SSTRING') {
	    if ($oldvalue ne $value) {
	      &{$self->function()}($self->{VALUE}, $index, $oldvalue, $self);
	  }
	  } else {
	    if ($oldvalue != $value) {
	      &{$self->function()}($self->{VALUE}, $index, $oldvalue, $self);
	    }
	  }
	}
      }
    }
    return $self->{VALUE}[$index];
  }
}

sub FETCH {
  return value(@_);
}

sub FETCHSIZE {
  return scalar(@{shift->{VALUE}});
}

sub POP {
  return pop @{shift->{VALUE}};
}

sub SHIFT {
  return shift @{shift->{VALUE}};
}

sub STORE {
  value(@_);
}

sub PUSH {
  my $self = shift;

  my $vals = $self->{VALUE};

  my $index;
  foreach (@_) {
    $index = scalar(@{$vals});
    $vals->[$index] = undef;
    $self->value($index, $_);
    if (!defined $vals->[$index]) { # The value was not accepted
      pop @{$vals};                 # so get rid of this element
    }
  }
}

sub UNSHIFT {
  my $self = shift;
  my $vals = $self->{VALUE};

  while (defined($_ = pop @_)) {
    unshift @{$vals}, undef;
    $self->value(0, $_);
    if (!defined $vals->[0]) { # The value was not accepted
      shift @{$vals};          # so get rid of this element
    }
  }
}

sub parse {
  my $self = shift;
  my $string = shift;

  my $type = $self->type();

  my @oldvals;
  if (defined $string) {
    if ($string =~ /^\s*unset\s*$/i) { # Magic undef command
      $self->{VALUE} = [];
    } else {
      my $vals;
      my $val;
      my $first = 1;
      my $nval = 0;
      while (defined $string && defined($val = parse_string($type, $string))) {
	if ($first) {
	  $first = 0;
	  $vals = $self->{VALUE} = [];
	  @oldvals = @$vals;  # Save in ase of error
	}
	$self->PUSH($val);
	$nval++;
      }
      if (scalar(@$vals)!=$nval) { # Something went wrong, such as exceeding max
	$vals = [@oldvals];
      }

      if (defined $string) {
	warn "Ignored \"$string\"\n";
      }
    }
  } else { # Print out the values in the list
    print $self->name(), ':';

    if (!defined $self->{VALUE} || scalar(@{$self->{VALUE}})==0) {
      print ' unset';
    }
    foreach my $val (@{$self->{VALUE}}) {
      print ' ', string_value($val, $type);
    }
    print "\n";
  }
}

1;

