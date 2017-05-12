package Attribute::Default;
{
  $Attribute::Default::VERSION = '1.35';
}

####
#### Attribute::Default
####
#### $Id$
####
#### See perldoc for details.
####

use 5.0010;
use strict;
use warnings;
no warnings 'redefine';
use attributes;
use Attribute::Handlers 0.79;

use base qw(Attribute::Handlers Exporter);

use Carp;
use Symbol;

our @EXPORT_OK = qw(exsub);

use constant EXSUB_CLASS => ( __PACKAGE__ . '::ExSub' );

##
## import()
##
## Apparently I found it necessary to export 'exsub'
## by hand. I don't know why. Eventually, it may
## be necessary to turn on some specific functionality
## once 'exsub' is exported for compile-time speed.
##
sub import {
  my $class = shift;
  my ($subname) = @_;
  my $callpkg = (caller())[0];

  if (defined($subname) && $subname eq 'exsub') {
    no strict 'refs';
    *{ "${callpkg}::exsub" } = \&exsub;
  }
  else {
    SUPER->import(@_);
  }
    
}

##
## exsub()
##
## One specifies an expanding subroutine for Default by saying 'exsub
## { YOUR CODE HERE }'. It's run and used as a default at runtime.
##
## Exsubs are marked by being blessed into EXSUB_CLASS.
##
sub exsub(&) {
  my ($sub) = @_;
  ref $sub eq 'CODE' or die "Sub '$sub' can't be blessed: must be CODE ref";
  bless $sub, EXSUB_CLASS;
}

##
## _get_args()
##
## Fairly close to no-op code. Discards the needless
## arguments I get from Attribute::Handlers stuff
## and puts single default arguments into array refs.
##
sub _get_args {
  my ($glob, $orig, $attr, $defaults) = @_[1 .. 4];
  (ref $defaults && ref $defaults ne 'CODE') or $defaults = [$defaults];

  return ($glob, $attr, $defaults, $orig);
}

##
## _is_method()
##
## Returns true if the given reference has a ':method' attribute.
##
sub _is_method {
  my ($orig) = @_;

  foreach ( attributes::get($orig) ) {
    ($_ eq 'method') and return 1;
  }

  return;
}

##
## _extract_exsubs_array()
##
## Arguments:
##    DEFAULTS -- arrayref : The list of default arguments
##
## Returns:
##    hashref: list of exsubs we found and their array indices
##    arrayref: list of defaults without exsubs
##
sub _extract_exsubs_array {
  my ($defaults) = @_;

  my %exsubs = ();
  my @noexsubs = ();

  for ( $[ .. $#$defaults ) {
    if (UNIVERSAL::isa( $defaults->[$_], EXSUB_CLASS )) {
      $exsubs{$_} = $defaults->[$_];
    }
    else {
      $noexsubs[$_] = $defaults->[$_];
    }
  }

  return (\%exsubs, \@noexsubs);
}


##
## _get_fill()
##
## Returns an appropriate subroutine to process the given defaults.
##
sub _get_fill {
  my ($defaults) = @_;

  if (ref $defaults eq 'ARRAY') {
    return _fill_array_sub($defaults);
  }
  elsif(ref $defaults eq 'HASH') {
    return _fill_hash_sub($defaults);
  }
  else {
    return _fill_array_sub([$defaults]);
  }
}

##
## _fill_array_sub()
##
## Arguments:
##   DEFAULTS: arrayref
##
##
## Returns:
##    coderef-- closure to fill sub with defaults
##    coderef-- closure to fill in exsubs
##
sub _fill_array_sub {
  my ($defaults) = @_;

  my ($exsubs, $plain) = _extract_exsubs_array($defaults);
  my $fill_sub = sub { return _fill_arr($plain, @_) };
  if ( %$exsubs ) {
      return ( $fill_sub,
	       sub {
		 my ($processed, $exsub_args) = @_;
		 while (my ($idx, $exsub) = each %$exsubs) {
		   defined( $processed->[$idx] ) and next;
		   $processed->[$idx] = &$exsub(@$exsub_args);
		 }
		 return $processed;
	       });
    }
  else {
    return ($fill_sub, undef);
  }
}

##
## _extract_exsubs_hash()
##
## Arguments:
##
##   DEFAULTS: hashref -- Name-value pairs of defaults
##
## Returns: (array)
##
##   hashref -- name-value pairs of all exsubs
##   hashref -- name-value pairs of all non-exsub defaults
##
## Returns the exsubs in a hash of defaults.
##
sub _extract_exsubs_hash {
  my ($defaults) = @_;

  my %exsubs = ();
  my %noexsubs = ();
  while ( my ($key, $value) = each %$defaults ) {
    if (UNIVERSAL::isa( $value, EXSUB_CLASS ) ) {
      $exsubs{$key} = $value;
    }
    else {
      $noexsubs{$key} = $value;
    }
  }
  return (\%exsubs, \%noexsubs);
}

##
## _fill_hash_sub()
##
##  Arguments
##    DEFAULTS: hashref -- name-value pairs of defaults
##
## Returns: list
##    coderef -- closure to fill default values
##    coderef -- closure to fill exsubs
##
## Returns the appropriate preprocessor to fill a hash
## with defaults.
##
sub _fill_hash_sub {
  my ($defaults) = @_;

  my ($exsubs, $plain) = _extract_exsubs_hash($defaults);
  my $fill_sub = sub { return _fill_hash($plain, @_); };
  if ( %$exsubs ) {
    return ($fill_sub, 
	    sub {
	      my ($filled, $exsub_args) = @_;
	      my %processed = @$filled;
	      while (my ($key, $exsub) = each %$exsubs) {
		(! defined $processed{$key}) or next;
		$processed{$key} = &$exsub(@$exsub_args);
	      }
	      @$filled = %processed;
	      return $filled;
	    });
  }
  else {
    return ( $fill_sub, undef );
  }
}

##
## _get_sub()
##
## Arguments:
##    DEFAULTS: arrayref -- Array of defaults to a subroutine
##    ORIG: code ref -- The subroutine we're applying defaults to
## 
## Returns the appropriate subroutine wrapper that
## will call ORIG with the given default values.
##
sub _get_sub {
  my ($defaults, $orig) = @_;

  my ($fill_sub, $exsub_sub) = _get_fill($defaults);

  if ( _is_method($orig) ) {
      if (defined $exsub_sub) {
	  return sub {
	      my ($self, @args) = @_;
	      my @filled = &$fill_sub(@args);
	      @_ = ($self, @{ &$exsub_sub( \@filled, [$self, @filled] ) } );
	      goto $orig;
	  };
      }
      else {
	  return sub {
	      my ($self, @args) = @_;
	      @_ = ($self, &$fill_sub(@args));
	      goto $orig;
	  };
      }
  }
  else {
      if (defined $exsub_sub) {
	  return sub {
	      my @filled = &$fill_sub(@_);
	      @_ = @{ &$exsub_sub( \@filled, \@filled ) };
	      goto $orig;
	  };
      }
      else {
	  return sub {
	      @_ = &$fill_sub(@_);
	      goto $orig;
	  };
      }
  }
}


sub Default : ATTR(CODE) {
  my ($glob, $attr, $defaults_arg, $orig) = _get_args(@_);
  
  my $defaults = $defaults_arg;
  
  if ( defined $defaults && (ref $defaults eq 'ARRAY') && ( scalar @{ $defaults } == 1 ) ) {
  	$defaults = $defaults_arg->[0];
  }

  *$glob = _get_sub($defaults, $orig);

}


##
## _fill_hash()
##
## Arguments:
##    DEFAULTS: hashref -- Hash table of default arguments
##    ARGS: list -- The arguments to be filtered
##
## Returns:
##    list -- Arguments with defaults filled in
##
sub _fill_hash {
  my $defaults = shift;
  my %args = @_;
  while (my ($key, $value) = each %$defaults) {
    unless ( defined($args{$key}) ) {
      if ( UNIVERSAL::isa( $value, EXSUB_CLASS ) ) {
	$args{$key} = undef;
      }
      else {
	$args{$key} = $value;
      }
    }
  }
  return %args;
}

##
## _fill_arr()
##
## Arguments:
##    DEFAULTS: arrayref -- Array of default arguments
##    ARGS: list -- The arguments to be filtered
##
## Returns:
##    list -- Arguments with defaults filled in
##
sub _fill_arr {
  my $defaults = shift;
  my @filled = ();
  foreach (0 .. $#_) {
    push @filled, ( defined( $_[$_] ) ? $_[$_] : $defaults->[$_] );
  }
  if ($#$defaults > $#_) {
    push(@filled, @$defaults[scalar @_ .. $#$defaults]);
  }

  return @filled;
}

##
## Defaults()
##
## Arguments:
##   GLOB: typeglobref -- Typeglob of name of sub to wrap
##   ORIG: coderef -- Ref to original sub
##   ATTR: string -- name of the attribute (Always 'Defaults' right now)
##   DEFAULTS_LIST -- list of default arguments
##
## Defaults() creates a wrapper subroutine that does a two-layer check on
## incoming arguments. It first processes the toplevel arguments as an
## array, then processes any reference defaults.
##
## If the default and the argument are of differing reference types, the
## argument is passed through unscathed.
##
## An undef of a reference type is treated like someone passing an empty
## array or hash.
##
## Implementation note: Using huge numbers of closures like I am may
## waste too much memory. It's a hell of a lot cleaner than what I was doing
## before, though.
##
##
sub Defaults : ATTR(CODE) {
  my ($glob, $orig, $attr, $defaults) = @_[1 .. 4];
  (ref $defaults) && (ref $defaults eq 'ARRAY') or $defaults = [$defaults];

  my @ref_defaults = ();
  my @ref_exsubs = ();
  my @toplevel_defaults = ();

  foreach ($[ .. $#$defaults) {
    if ( (my $type = ref $$defaults[$_]) && (! UNIVERSAL::isa($$defaults[$_], EXSUB_CLASS) ) ) {
      my ($fill_sub, $fill_exsub) = _get_fill($$defaults[$_]);
      push @ref_defaults, [$_, $type, $fill_sub];
      defined $fill_exsub and push @ref_exsubs, [$_, $type, $fill_exsub];
    }
    else {
      $toplevel_defaults[$_] = $$defaults[$_];
    }
  }

  my ($toplevel_sub, $toplevel_exsub) = _fill_array_sub(\@toplevel_defaults);

  if ( _is_method($orig) ) {
    *$glob = 
sub {
  my @filled = &$toplevel_sub(@_[ ($[ + 1) .. $#_ ]);
  _fill_sublevel(\@filled, \@ref_defaults);
  defined ($toplevel_exsub) && &$toplevel_exsub(\@filled, [$_[0], @filled]);
  _fill_exsubs(\@filled, \@ref_exsubs, [$_[0], @filled]);
  @_ = ($_[0], @filled);
  goto $orig;
}
  }
  else {
      *$glob =
 sub {
	  
	  # First, fill toplevel arguments
	  my @filled = &$toplevel_sub(@_);
	  
	  # Next, fill all sublevel arguments
	  _fill_sublevel(\@filled, \@ref_defaults);

	  defined ($toplevel_exsub) && &$toplevel_exsub(\@filled, \@filled);
	  _fill_exsubs(\@filled, \@ref_exsubs, \@filled);
	  @_ = @filled;
	  goto $orig;
      }
	  
  }      
      

}

sub _fill_exsubs {
  my ($args, $ref_exsubs, $exsub_args) = @_;

  foreach (@$ref_exsubs) {
    my ($idx, $type, $exsub_sub) = @$_;
    ($type eq ref $$args[$idx]) || (! defined $$args[$idx]) or next;
    if ($type eq 'HASH') {
      $$args[$idx] = { @{ &$exsub_sub( [%{ $$args[$idx] } ], $exsub_args  ) } };
    }
    elsif ($type eq 'ARRAY') {
      $$args[$idx] = &$exsub_sub( $$args[$idx], $exsub_args );
    }
    else {
      die "Exsub expansion cannot handle '$type'";
    }
  }
}



sub _fill_sublevel {
  my ($filled, $ref_defaults) = @_;

  foreach (@$ref_defaults) {
    my ($idx, $type, $fill_sub) = @$_;
    ($type eq ref $$filled[$idx]) || (! defined $$filled[$idx]) or next;
    if ($type eq 'HASH') {
      $$filled[$idx] = { &$fill_sub( defined $$filled[$idx] ? %{ $$filled[$idx] } : () ) };
    } elsif ($type eq 'ARRAY') {
      $$filled[$idx] = [ &$fill_sub( defined $$filled[$idx] ? @{ $$filled[$idx] } : () ) ];
    } else {
      die "I don't know what to do with '$type'";
    }

  }

}

1;
__END__

=head1 NAME

Attribute::Default - Perl extension to assign default values to subroutine arguments

=head1 SYNOPSIS

  package MyPackage;
  use base 'Attribute::Default';

  # Makes person's name default to "Jimmy"
  sub introduce : Default("Jimmy") {
     my ($name) = @_;
     print "My name is $name\n";
  }
  # prints "My name is Jimmy"
  introduce();

  # Make age default to 14, sex default to male
  sub vitals : Default({age => 14, sex => 'male'}) {
     my %vitals = @_;
     print "I'm $vitals{'sex'}, $vitals{'age'} years old, and am from $vitals{'location'}\n";
  }
  # Prints "I'm male, 14 years old, and am from Schenectady"
  vitals(location => 'Schenectady');


=head1 DESCRIPTION

You've probably seen it a thousand times: a subroutine begins with a
complex series of C<defined($blah) or $blah = 'fribble'> statements
designed to provide reasonable default values for optional
parameters. They work fine, but every once in a while one wishes that
perl 5 had a simple mechanism to provide default values to
subroutines.

This module attempts to provide that mechanism.

B<THIS MODULE IS DEPRECATED.> I'll be providing basic bug fixes, but
there are superior modules out there-- I'd suggest L<Method::Signatures>
or L<Params::Validate>.

=head2 SIMPLE DEFAULTS

If you would like to have a subroutine that takes three parameters,
but the second two should default to 'Mister Morton' and 'walked', you
can declare it like this:

  package WhateverPackage;
  use base 'Attribute::Default';

  sub what_happened : Default(undef, 'Mister Morton', 'walked down the street') {
    my ($time, $subject, $verb) = @_;

    print "At $time, $subject $verb\n";
  }

and C<$subject> and C<$verb> will automatically be filled in when
someone calls the C<what_happened()> subroutine with only a single
argument.

  # prints "At 12AM, Mister Morton walked down the street"
  what_happened('12AM');

  # prints "At 3AM, Interplanet Janet walked down the street"
  what_happened('3AM', 'Interplanet Janet');

  # prints "At 6PM, a bill got passed into law"
  what_happened('6PM', 'a bill', 'got passed into law');

  # prints "At 7:03 PM, Mister Morton grew flowers for Perl"
  what_happened("7:03 PM", undef, "grew flowers for Perl");

You can also use the default mechanism to handle the named parameter
style of coding. Just pass a hash reference as the value of
C<Default()>, like so:

  package YetAnotherPackage;
  use base 'Attribute::Default';

  sub found_pet : Default({name => 'Rufus Xavier Sarsaparilla', pet => 'kangaroo'}) {
    my %args = @_;
    my ($first_name) = split(/ /, $args{'name'}, 2);
    print "$first_name found a $args{'pet'} that followed $first_name home\n"; 
    print "And now that $args{'pet'} belongs...\n";
    print "To $args{'name'}.\n\n";
  }

  # Prints "Rufus found a kangaroo that followed Rufus home"...
  found_pet();

  # Prints "Rafaella found a kangaroo that followed Rafaella home"...
  found_pet(name => 'Rafaella Gabriela Sarsaparilla');

  # Or...
  found_pet(name => 'Rafaella Gabriela Sarsaparilla', pet => undef);

  # Prints "Albert found a rhinoceros that followed Albert home"...
  found_pet(name => 'Albert Andreas Armadillo', pet => 'rhinoceros');

=head2 DEFAULTING REFERENCES

If you prefer to pass around your arguments as references, rather than
full lists, Attribute::Default can accomodate you. Simply use
C<Defaults()> instead of C<Default()>, and your reference parameters
will have defaults added wherever necessary. For example:

  package StillAnotherPackage;
  use base 'Attribute::Default';

  sub lally : Defaults({part_of_speech => 'adverbs', place => 'here'}, 3) {
    my ($in, $number) = @_;
    print join(' ', ('lally') x $number), ", get your $in->{part_of_speech} $in->{'place'}...\n";
  }

  # Prints "lally lally lally, get your adverbs here"
  lally();

  # Prints "lally, get your nouns here"
  lally({part_of_speech => 'nouns'}, 1);

If an argument reference's type does not match an expected default
type, then it is passed along without any attempt at defaulting.


=head2 DEFAULTING METHOD ARGUMENTS

If you are performing object-oriented programming, you can use the
C<:method> attribute to mark your function as a method. The
C<Default()> and C<Defaults()> attributes ignore the first argument (in
other words, the 'type' or 'self' argument) for functions marked as
methods. So you can use C<Default()> and C<Defaults()> just as for regular functions, like so:

 package Thing;
 use base 'Noun';

 sub new :method :Default({ word => 'train' }) {
    my $type = shift;
    my %args = @_;

    my $self = [ $args->{'word'} ];
    bless $self, $type;
 }

 sub make_sentence :method :Default('to another state') {
    my $self = shift;
    my ($phrase) = @_;

    return "I took a " . $self->[0] . " $phrase"
 }

 # prints "I took a train to another state"
 my $train = Noun->new();
 print $train->make_sentence();

 # prints "I took a ferry to the Statue of Liberty"
 my $ferry = Noun->new( word => 'ferry' );
 print $ferry->make_sentence('to the Statue of Liberty');

=head2 EXPANDING SUBROUTINES

Sometimes it's not possible to know in advance what the default should
be for a particular argument. Instead, you'd like the default to be
the return value of some bit of Perl code invoked when the subroutine
is called. No problem! You can pass an expanding subroutine to the
C<Default()> attribute using C<exsub>, like so:

 use Attribute::Default 'exsub';
 use base 'Attribute::Default';

 sub log_action : Default( undef, exsub { get_time(); } ) {
    my ($verb, $time) = @_;
    print "$verb! That's what's happening at $time\n";
 }

Here, if $time is undef, it gets filled in with the results of
executing get_time().

Exsubs are passed the same arguments as the base subroutine on which
they're declared, so you can use other arguments (including default
arguments) in your exsubs, like so:

 sub double : Default( 2, exsub { $_[0] * 2 }) {
     my ($first, $second) = @_;

     print "First: $first Second: $second\n";
}

 # Prints "First: 2 Second: 4"
 double();

 # Prints "First: 3 Second: 6"
 double(3);

 # Prints "First: 4 Second: 5"
 double(4, 5);

Note that this means that exsubs for methods are effectively called as methods:

 package MyObject;

 sub new { my $type = shift; bless [3], $type; }

 sub double :method :Default( exsub { $_[0][0] * 2 } ) {
   my $self = shift;
   print $_[1], "\n";
 }

 my $myobject = MyObject->new();

 # Prints 6
 $myobject->double()

 # Prints 4
 $myobject->double(4);

To avoid potential recursion, other exsub defaults are not passed to
exsub arguments.

=head1 BUGS

There's an as-yet unmeasured compile time delay as Attribute::Default does its magic.

Use of large numbers of default arguments to a subroutine can be a
sign of bad design. Use responsibly.

=head1 AUTHOR

Stephen Nelson, E<lt>stephenenelson@mac.comE<gt>

=head1 SPECIAL THANKS TO

Christine Doyle, Randy Ray, Jeff Anderson, and my brother and sister monks at www.perlmonks.org.

=head1 SEE ALSO

L<Attribute::Handlers>, L<Sub::NamedParams>, L<attributes>.

=head1 LICENSE

This software is copyright (c) 2002-2013 by Stephen Nelson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


