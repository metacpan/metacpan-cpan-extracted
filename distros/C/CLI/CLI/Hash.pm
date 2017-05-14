package CLI::Hash;
use CLI::Base;
@ISA = ("CLI::Base");

use Carp;
use CLI qw( SSTRING parse_string hashmatch );
use strict;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $name = shift;
  my @vars = @_;
  if (@vars<1) {  # We need some values to play with
    carp "CLI::Hash->new: No variables to add\n";
    return;
  }

  # Is the last value a hash reference?
  my $hash = pop @vars;
  if (!(ref($hash) eq 'HASH')) { # No then leave @vars how it was
    push @vars, $hash;
    $hash = undef;
  } else {
    if (@vars<1) {  # We need some values to play with
      carp "CLI::Hash->new: No variables to add\n";
      return;
    }
  }

  my $self  = {
	       NAME => $name,
	       TYPE => undef,
	       VALUE => undef,
	       FUNC => undef,
	       MIN => undef,
	       MAX => undef,
	       HASH => {},
	       VARS => [@vars]
	      };
  bless ($self, $class);

  $self->function($hash->{function}) if (defined $hash->{function});

  return $self;
}

sub hash {
  my $self = shift;
  return $self->{HASH};
}

sub vars {
  my $self = shift;
  if (@_) { $self->{VARS} = (@_) }
  return @{$self->{VARS}};
}

sub add {
  my $self = shift;
  my $name = shift;
  my @values = @_;
  if (@values) {
    my @newvalues = ();
    foreach ($self->vars()) {
      push @newvalues, shift @values;
    }
    $self->hash->{$name} = [@newvalues];
  } else {
    carp "CLI::Hash->add: No values to add\n";
    return;
  }
}

sub parse {
  my $self = shift;
  my $string = shift;

  if (!defined $string) { # No argument, print name of last value used
    if (defined $self->value()) {
      print ' ', $self->value(), "\n";
    } else {
      print "No value set\n";
    }
  } else {
    my $name = parse_string(SSTRING, $string);

    if (!defined $string) { # no values, extract values from the hash
      my @matches = $self->extract($name,0);
      if (!defined $matches[0]) {
	print "Unknown element $name\n";
      } elsif (@matches>1) {
	print "\"$name\" matches:\n\n";
	foreach (@matches) {
	  print "  $_\n";
	}
	print "\n";
      }
    } else { # New element
      my @values = ();
      foreach my $var ($self->vars()) {
	if (defined $string) {
	  my $val = parse_string($var->type(), $string);
	  if (defined $val) {
	    push @values, $val;
	  } else {
	    carp "Bad value \"$string\"\n";
	    return;
	  }
	} else {
	  push @values, $var->value();  # Save the current value
	}
      }
      $self->add($name, @values);
    }
  }
}

sub extract {
  my $self = shift;
  my $name = shift;
  my $quiet = shift;
  $quiet=0 if (!defined $quiet);

  my $hash = $self->hash();

  my @values = ();
  my @matches = ();
  my $hashmatch = hashmatch($name, $hash, @matches);
  if (defined $hashmatch) {    # Did we find a unique match
    $self->value($matches[0]); # Remember the name of the match
    @values = @{$hashmatch};   # Get the values from the hash

    # If no uniqe matches, try an (optional) custom function
  } elsif (defined $self->function()) {
    @values = &{$self->function()}($name);
    if (scalar(@values)) {
      $self->value($name); # Remember the name of the match
    }
  }

  if (@values) {
    # Got though each varable in the hash and update the value
    foreach my $var ($self->vars()) {
      my $value = shift @values;
      if (defined $value) {
	$var->value($value);
	print '    ', $var->name, ' = ', $var->svalue(), "\n" if (!$quiet);
      }
    }
    return $self->value();
  } else { # We didn't find any unique matches
    if (@matches) { # There WERE multiple matches from the standard method
      return @matches;
    } else {
      return undef;
    }
  }
}

1;

