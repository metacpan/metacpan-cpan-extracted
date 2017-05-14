package CLI;


BEGIN {
  use Exporter();
  use vars qw(@ISA @EXPORT);

  @ISA = qw(Exporter);
  @EXPORT = qw(VAR HASH COMMAND ARRAY MIXED ARRAY INTEGER FLOAT STRING
               SSTRING TIME DEGREE BOOLEAN 
               hashmatch parse_string typeStr string_value);
  use Astro::Time qw(turn2str str2turn);
  use Carp;
}

use constant VAR     => 1;
use constant HASH    => 2;
use constant COMMAND => 3;
use constant ARRAY   => 4;
use constant MIXEDARRAY => 5;

use constant INTEGER => 1;
use constant FLOAT   => 2;
use constant STRING  => 3;
use constant SSTRING => 4;
use constant TIME    => 5;
use constant DEGREE  => 6;
use constant BOOLEAN => 7;

sub parse_string ($$);
sub typeStr ($);
sub hashmatch ($$\@);
sub string_value($$);

use CLI::Var;
use CLI::Hash;
use CLI::Command;
use CLI::Array;
use CLI::MixedArray;

use strict;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $self  = {
	       ELEMENTS => {},
	       DEFAULT => undef
	      };

  bless ($self, $class);

  return $self;
}

sub add {
  my $self = shift;
  my $type = shift;
  my $name = shift;
  my $elements = $self->{ELEMENTS};

  my $new_element;
  if ($type==VAR) {
    my $var = shift;
    tie $$var, 'CLI::Var', $name, @_;
    $new_element = tied $$var;
  } elsif ($type==ARRAY) {
    my $var = shift;
    tie @{$var}, 'CLI::Array', $name, @_;
    $new_element = tied @{$var};
  } elsif ($type==MIXEDARRAY) {
    my $var = shift;
    tie @{$var}, 'CLI::MixedArray', $name, @_;
    $new_element = tied @{$var};
  } elsif ($type==HASH) {
    $new_element = new CLI::Hash($name, @_);
  } elsif ($type==COMMAND) {
    $new_element = new CLI::Command($name, @_);
  } else {
    carp 'CLI::add Unknown element type';
  }

  $elements->{$name} = $new_element;

  return $new_element;
}

# Command to run if command is not known
sub default {
  my $self = shift;
  if (@_) {
    $self->{DEFAULT} = shift; #TODO Should check type
  }
  return $self->{DEFAULT};
}

sub parse {
  my $self = shift;
  my $line = shift;

  my $elements = $self->{ELEMENTS};

  my ($key, $value);
  if ($line =~ /^\s*(\S+)         # Key
                 (?:\s+           # Optionally followed by a space
                 (?:(.*\S))?\s*)?  # and then some value
                $/x) {
    $key = $1;
    $value = $2;
  } else {
    return;  # Ignore blank lines
  }
  my @matches = ();
  my $command = hashmatch($key, $elements, @matches);

  if (defined $command) {
    $command->parse($value);
  } else {
    if (@matches) {
      print "\"$key\" matches:\n\n";
      foreach my $match (@matches) {
	print "  $match\n";
      }
      print "\n";
    } else {
      if (defined $self->default) {
	&{$self->default()}($line, $key, $value);
      } else {
	print "\n Unknown command $key\n\n";
      }
    }
  }
}

# Save a config file based on the current state of variables
# Currently does not save anything but variable types
sub save_config{
  my $self = shift;

  my $fconfig = shift;

  if (!defined $fconfig) {
    carp "CLI->save_config must supply config filename";
    return;
  }

  if (! open(CONFIG, '>', $fconfig)) {
    carp "Could not open $fconfig: $!"; 
    return;
  }

  my $elements =  $self->{ELEMENTS};

  foreach (keys(%$elements)) {
    my $type = ref($elements->{$_});
    if ($type eq 'CLI::Var') {
      printf(CONFIG "%s %s\n", $_, $elements->{$_}->value);
    }
  }

  close(CONFIG);
}

# Read back a previously saved config file. 
# Currently config file can contain anything that could be
# type on the command line
sub restore_config{
  my $self = shift;

  my $fconfig = shift;

  if (!defined $fconfig) {
    carp "CLI->restore_config: must supply config filename";
    return;
  }

  if (! open(CONFIG, $fconfig)) {
    carp "Could not open $fconfig for reading: $!"; 
    return;
  }

  my $elements =  $self->{ELEMENTS};

  while (<CONFIG>) {
    $self->parse($_);
  }

  close(CONFIG);
}


# Some generally useful routines

sub hashmatch ($$\@) {
#+
# Match a keyword in a hash, using case insensitive minimal matching, and 
# returns the hash value
# (ie 'Fr' matches 'Fred' and 'Frank')
# Usage:
#  my %hash = (
#        Fred    => 'Some value',
#        William => 20,
#        Mary    => [0, 1, 2]
#             );
#  my $key = 'Fr';
#  my @matches = ();
#  my $match = hashmatch($key, \%hash, @matches);
#
# Returns undef if no matches found, or multiple matches found
# The third parameter is set to a list reference containing all the matches
# Wild cards are allowed:   *   match any number of characters
#                           ?   Match one character
#-
  my($key, $hash, $matches) = @_;

  @$matches = ();

  # Cannot do exact matches with wild cards
  my $exactmatch = 1;
  $exactmatch = 0 if (($key =~ /\?/) || ($key =~ /\*/));

  my @matches = ();
  # Clean up the key
  $key =~ s/\./\\\./g;  # Pass '.'s (. -> \.)
  $key =~ s/\+/\\\+/g;  # Pass '+'s (+ -> \+)
  $key =~ s/\[/\\\[/g;  # Pass '['s (+ -> \[)
  $key =~ s/\]/\\\]/g;  # Pass ']'s (+ -> \])
  $key =~ s/\(/\\\(/g;  # Pass '('s (+ -> \()
  $key =~ s/\)/\\\)/g;  # Pass ')'s (+ -> \))
  $key =~ s/\*/\.\*/g;  # Allow simple wild cards ( * -> .* )
  $key =~ s/\?/\./g;    # ? matches single character (? -> .)

  foreach (keys(%$hash)) {
    #print "Trying $_ ";
    if ($exactmatch && /^$key$/i) {    # Return immediately for an exact match
      #print " exact match to $key!\n";
      @$matches = ($_);
      return $$hash{$_};
    } elsif (/^$key/i) {
      push @$matches, $_;
      #print " matches $key\n";
    } else {
      #print " no match\n";
    }
  }

  if (@$matches==1) {
    return $hash->{$matches->[0]};
  } else {
    return undef;
  }
};

sub parse_string ($$) {
  my ($type, $string) = @_;

  if (defined $type) {

    my $pattern = '';
    if ($type == INTEGER) {
      $pattern = '[+-]?\\d+';
    } elsif ($type == FLOAT) {
      #$pattern = '\\d+\.\\d+'; # Way to simplistic
      $pattern = '\\S+'; # Way to simplistic
    } elsif ($type == SSTRING) {
      $pattern = '\\S+';
    } elsif ($type == STRING) {
      $pattern = '\\S.*';
    } elsif ($type == TIME) {
      $pattern = '\\S+';
    } elsif ($type == DEGREE) {
      $pattern = '\\S+';
    } else {
      $pattern = '.+';
    }

    if ($string =~ /^\s*($pattern)(?:\s+(.*))?$/) {
      $_[1] = $2;  # Pass back the unused portion of the string

      # Return the matched portion, with possibly with some additional processing
      if ($type == DEGREE) {
	return str2turn($1,'D');
      } elsif ($type == TIME) {
	return str2turn($1,'H');
      } else {
	return $1;
      }
    } else {
      return undef;
    }
  } else {
    return undef;
  }
}

sub typeStr ($) {
  my $type = shift;
  if ($type == INTEGER) {
    return 'Integer';
  } elsif ($type == FLOAT) {
    return 'Float';
  } elsif ($type == STRING) {
    return 'String';
  } elsif ($type == SSTRING) {
    return 'SString';
  } elsif ($type == TIME) {
    return 'Time';
  } elsif ($type == DEGREE) {
    return 'Degree';
  } elsif ($type == BOOLEAN) {
    return 'Boolean';
  } else {
    return 'Unknown';
  }
}

sub string_value ($$) {
  my $value = shift;
  my $type = shift;
  if ($type == TIME) {
    return turn2str($value, 'H', 2);
  } elsif ($type == DEGREE) {
    return turn2str($value, 'D', 2);
  } else {
    return $value;
  }
}


1;
