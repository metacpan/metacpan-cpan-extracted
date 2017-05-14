package CLI::Var;
use CLI::Base;
@ISA = ("CLI::Base");

use Carp;
use CLI   qw(INTEGER FLOAT STRING SSTRING TIME DEGREE
             BOOLEAN parse_string );
use Astro::Time qw(turn2str str2turn);

use strict;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $name = shift;
  my $type = shift;
  my $value = shift;
  my $hash = shift;

  my $self  = {
	       NAME => $name,
	       TYPE => $type,
	       VALUE => $value,
	       FUNC => undef,
	       MIN => undef,
	       MAX => undef,
	      };

  bless ($self, $class);

  $self->function($hash->{function}) if (defined $hash->{function});
  $self->min($hash->{min}) if (defined $hash->{min});
  $self->max($hash->{max}) if (defined $hash->{max});

  return $self;
}

sub TIESCALAR {
  return new(@_);
}

sub value {
  my $self = shift;

  if (@_) { 
    my $value = shift;
    my $oldvalue = $self->{VALUE};
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
      $self->{VALUE} = $value;
      if (defined $self->function()) {
	my $type = $self->type();
	if ($type == STRING || $type == SSTRING) {
	  if ($oldvalue ne $value) {
	    &{$self->function()}($self->{VALUE}, $oldvalue, $self);
	  }

	} else {
	  if ($oldvalue != $value) {
	    &{$self->function()}($self->{VALUE}, $oldvalue, $self);
	  }
	}
      }
    }
  }
  return $self->{VALUE};
}

sub FETCH {
  return shift->{VALUE};
}

sub STORE {
  my $self = shift;
  $self->value(shift);
  #print "Saved $self->{NAME} as $self->{VALUE}\n";
}

sub svalue {
  my $self = shift;
  my $type = $self->{TYPE};
  if ($type == TIME) {
    return turn2str($self->value(), 'H', 2);
  } elsif ($type == DEGREE) {
    return turn2str($self->value(), 'D', 2);
  } else {
    return $self->value();
  }
}

sub parse {
  my $self = shift;
  my $string = shift;
  my $type = $self->type();

  if (defined $string) {
    my $value = parse_string($type, $string);

    if (! defined $value) {
      carp "Bad value \"$string\" for type $type\n";
      return;
    }
    if (defined $string) { # String should be undef if only one value was passed
      carp "Did not understand \"$string\n";
      return;
    }

    $self->value($value);
  } else {
    if (defined $self->svalue()) {
      print '  ',$self->svalue(),"\n";
    } else {
      print " undef\n";
    }
  }
}

1;

