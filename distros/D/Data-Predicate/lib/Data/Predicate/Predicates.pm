package Data::Predicate::Predicates;

use strict;
use warnings;

use Data::Predicate::ClosurePredicate;
use Scalar::Util qw(blessed looks_like_number);
use Readonly;
use base 'Exporter';

our @EXPORT_OK = qw(
  p_and
  p_or
  p_not
  p_always_true
  p_always_false
  p_undef
  p_defined
  p_blessed
  p_is_number
  p_ref_type
  p_isa
  p_can
  p_numeric_equals
  p_string_equals
  p_regex
  p_substring
);
our %EXPORT_TAGS = (
  all      => [@EXPORT_OK],
  logic    => [qw(p_and p_or p_not)],
  defaults => [qw(p_always_true p_always_false)],
  tests    => [qw(p_defined p_undef p_blessed p_is_number p_ref_type 
                  p_isa p_can p_numeric_equals p_string_equals 
                  p_regex p_substring)],
);

#Set of predicates which never change so we build once & cache; others may & do
Readonly::Hash my %STATIC_PREDICATES => (
  'true'  => Data::Predicate::ClosurePredicate->new( 
    closure => sub { 1 } ,
    description => 'true'
  ),
  'false' => Data::Predicate::ClosurePredicate->new( 
    closure => sub { 0 },
    description => 'false' 
  ),
  'defined' => Data::Predicate::ClosurePredicate->new(
    closure => sub {
      my ($object) = @_;
      return ( defined $object ) ? 1 : 0;
    },
    description => 'defined'
  ),
  'undef' => Data::Predicate::ClosurePredicate->new(
    closure => sub {
      my ($object) = @_;
      return ( defined $object ) ? 0 : 1;
    },
    description => 'undef'
  ),
  'blessed' => Data::Predicate::ClosurePredicate->new(
    closure => sub {
      my ($object) = @_;
      return ( blessed($object) ) ? 1 : 0;
    },
    description => 'blessed'
  ),
  'number' => Data::Predicate::ClosurePredicate->new(
    closure => sub {
      my ($object) = @_;
      return ( defined $object && looks_like_number($object) ) ? 1 : 0;
    },
    description => 'number'
  )
);

sub p_and {
  my ( @predicates ) = @_;
  return Data::Predicate::ClosurePredicate->new(
    closure => sub {
      my ($object) = @_;
      foreach my $pred (@predicates) {
        if(!$pred->apply($object)) {
          return 0;
        }
      }
      return 1;
    },
    description => 'and'
  );
}

sub p_or {
  my ( @predicates ) = @_;
  return Data::Predicate::ClosurePredicate->new(
    closure => sub {
      my ($object) = @_;
      foreach my $pred (@predicates) {
        if($pred->apply($object)) {
          return 1;
        }
      }
      return 0;
    },
    description => 'or'
  );
}

sub p_not {
  my ($predicate) = @_;
  return Data::Predicate::ClosurePredicate->new(
    closure => sub {
      my ($object) = @_;
      return ($predicate->apply($object)) ? 0 : 1;
    },
    description => 'not'
  );
}

sub p_always_true {
  return $STATIC_PREDICATES{'true'};
}

sub p_always_false {
  return $STATIC_PREDICATES{'false'};
}

sub p_defined {
  return $STATIC_PREDICATES{'defined'};
}

sub p_undef {
  return $STATIC_PREDICATES{'undef'};
}

sub p_blessed {
  return $STATIC_PREDICATES{'blessed'};
}

sub p_is_number {
  return $STATIC_PREDICATES{'number'};
}

sub p_ref_type {
  my ($ref_type) = @_;
  return Data::Predicate::ClosurePredicate->new(
    closure => sub {
      my ($object) = @_;
      my $ref = ref($object);
      return 0 unless $ref;
      return ( $ref eq $ref_type ) ? 1 : 0;
    },
    description => 'ref_type predicate with type '.$ref_type
  );
}

sub p_isa {
  my ($isa) = @_;
  return Data::Predicate::ClosurePredicate->new(
    closure => sub {
      my ($object) = @_;
      return 0 unless p_blessed()->apply($object);
      return ( $object->isa($isa) ) ? 1 : 0;
    },
    description => 'isa predicate with type '.$isa
  );
}

sub p_can {
  my ($method) = @_;
  return Data::Predicate::ClosurePredicate->new(
    closure => sub {
      my ($object) = @_;
      return 0 unless p_blessed()->apply($object);
      return ( $object->can($method) ) ? 1 : 0;
    },
    description => 'Can predicate with method '.$method
  );
}

sub p_string_equals {
  my ($str, $method) = @_;
  my $target = (defined $method) ? "against method ${method}" : 'against values';
  return Data::Predicate::ClosurePredicate->new(
    closure => sub {
      my ($object) = @_;
      my $val = _invoke($object, $method);
      return ( p_defined->apply($val) && $val eq $str ) ? 1 : 0;
    },
    description => "String equals predicate $target with number $str"
  );
}

sub p_numeric_equals {
  my ($number, $method) = @_;
  my $target = (defined $method) ? "against method ${method}" : 'against values';
  return Data::Predicate::ClosurePredicate->new(
    closure => sub {
      my ($object) = @_;
      my $val = _invoke($object, $method);
      return ( p_is_number->apply($val) && $val == $number ) ? 1 : 0;
    },
    description => "Numeric equals predicate $target with number $number"
  );
}

sub p_regex {
  my ($regex, $method) = @_;
  my $target = (defined $method) ? "against method ${method}" : 'against values';
  return Data::Predicate::ClosurePredicate->new(
    closure => sub {
      my ($object) = @_;
      my $val = _invoke($object, $method);
      return ( p_defined->apply($val) && $val =~ $regex) ? 1 : 0;
    },
    description => "Regular expression predicate $target with regex $regex"
  );
}

sub p_substring {
  my ($substring, $method) = @_;
  my $target = (defined $method) ? "against method ${method}" : 'against values';
  return Data::Predicate::ClosurePredicate->new(
    closure => sub {
      my ($object) = @_;
      my $val = _invoke($object, $method);
      return ( p_defined->apply($val) && index($val, $substring) > -1) ? 1 : 0;
    },
    description => "Substring predicate $target with substring $substring"
  );
}

sub _invoke {
  my ($object, $method) = @_;
  my $val;
  if($method) {
    if(p_can($method)->apply($object)) {
      $val = $object->can($method)->($object);
    }
    else {
      confess("Cannot call the method '${method}' on the given object ${object}");
    }
  }
  else {
    $val = $object;
  }
  return $val;
}

1;
__END__
=pod

=head1 NAME

Data::Predicate::Predicates

=head1 SYNOPSIS

  use Data::Predicate::Predicates qw(:all);
  # we also support :logic :defaults :tests as groups for imports
  
  my $predicate = p_and(p_defined(), p_is_number(), p_numeric_equals(1));
  
  $predicate->apply(1); #Returns true
  $predicate->apply(2); #Returns false
  $predicate->apply(undef); #Returns false
  $predicate->apply('a'); #Returns false
  
  my @data = (1, 2, 3, 4, undef, 'a', 5, 1);
  my $new_data = $predicate->filter(\@data);
  #New data will == [1,1]

=head1 DESCRIPTION

B<Try using this class first before going off & building your own Predicate>.

This module is a set of useful ready built predicates. All predicates
defined here use C<Data::Predicate::ClosurePredicate> and build themselves
by creating a closure and passing it into a constructor. Those which require
no user input when calling the methods will be built when the class is first
used. Otherwise the others have closures built on the fly to fit your needs.

If your logic is too complex for these predicates or too slow then build
your own by using C<Data::Predicate> and implementing C<apply()> or
by creating your own closure & an instance of 
C<Data::Predicate::ClosurePredicate>.

All methods are prefixed with a C<p_> to avoid problems with other modules
importing into this name space and to avoid clashes with built-in homonyms.

=head1 EXPORT OPTIONS

=head2 all

Exports all methods into your scope

=head2 logic

Imports the logic operators C<p_and>, C<p_or> and C<p_not>

=head2 defaults

Imports the C<p_always_true> and C<p_always_false>

=head2 tests

Imports the methods not imported by logic or default tags. This means
anything which is used to test a Perlism like blessed references.

=head1 SUBROUTINES/METHODS

=head2 p_and()

  p_and(p_defined(), p_is_number())->apply(1) #Returns true
  
Combine multiple predicates into one predicate instance. The code iterates
through all predicates and will exit the moment one predicate returns false. 

=head2 p_or()

  p_or(p_defined(), p_is_number())-apply('a') #Would return true because 'a' is defined 
  
Combine multiple predicates into one predicate instance which will return the
moment one predicate in the list returns true.

=head2 p_not()

  p_or(p_defined())->apply(undef) #Returns true
  
Reverses the logic of the given predicate so the above really means return
true if the object tested is undefined

=head2 p_always_true()

  p_always_true()
  
Will always return true; useful for when you just want to pass everything

=head2 p_always_false()

Will always return false; useful for when you just want to fail everything

=head2 p_defined()

  p_defined()->apply(1) #Returns true

Will only return true when the given value is defined

=head2 p_undef()

  p_undef()->apply(undef) #Returns true

Will only return true when the given value is undefined

=head2 p_is_number()

  p_is_number()->apply(1) #Returns true
  
Returns true if the given value is a number

=head2 p_blessed()

  p_blessed()->apply(bless({})) #returns true

Returns true if the given value was a blessed value.

=head2 p_isa()

  p_isa('My::Objs::Dog')->apply($dog) #Returns true if $dog was an extension of My::Objs::Dog

Returns true according to the rules of isa when called on an object. The predicate
will also test to see if the object was a blessed one before calling isa.

This differs from most predicates as you must tell the method what kind of
Object you are expecting. This is recorded in curried in a closure & then
used during evaluation.

=head2 p_can()

  p_can('howl')->apply($dog) #Returns true if $dog had a subroutine for howl()

Returns true if the given object could respond to the given subroutine 
message. The predicate assumes the reference must be blessed for it to
find a subroutine via a reference.

This differs from most predicates as you must tell the method what kind of
subrotuine you are expecting to find. This is recorded in curried in a 
closure & then used during evaluation.

=head2 p_ref_type()

  p_ref_type('ARRAY')->apply([]) #Returns true if the given reference was what you originally said

Returns true if the given ref equalled the originally stated reference.

=head2 p_string_equals()

  #Assume an object called Dog with the method howl which returns a string
  p_string_equals('a')->apply('a') #returns true
  p_string_equals('a')->apply('b') #returns false
  
  #would return true if $dog had a subroutine called howl & it returned the specified string
  p_string_equals('rrroouggghh', 'howl')->apply($dog)

Applies the eq test for strings. In it's basic form you can specify a String and
it will only return true if the given value eq that String.

There is a more advanced mode which lets you call a subrotuine on the given
reference and then evaluate the returned value. This allows you to use
this subroutine with Objects rather than having to write a custom one for
basic evaluation.

=head2 p_numeric_equals()

  #Assume an object called Dog with the method age which returns a number
  p_numeric_equals(1)->apply(1) #returns true
  p_numeric_equals(1)->apply(2) #returns false
  
  #would return true if $dog had a subroutine called age & it returned the specified number
  p_numeric_equals(7, 'age')->apply($dog)

Applies the == test for numbers. In it's basic form you can specify a number and
it will only return true if the given value == that number. Will also return
false if it was given a String (which is passed into p_is_number())

There is a more advanced mode which lets you call a subrotuine on the given
reference and then evaluate the returned value. This allows you to use
this subroutine with Objects rather than having to write a custom one for
basic evaluation.

=head2 p_regex()

  #Assume an object called Dog with the method howl which returns a String
  p_regex(qr/A/)->apply('Aaaa') #returns true
  p_regex(qr/A/)->apply('bA') #returns true
  p_regex(qr/A/)->apply('b') #returns false
  
  p_regex(qr/rrr/, 'howl')->apply($dog) #Returns true if the string from howl matched /rrr/

Behaves identitcally to C<p_string_equals()> and C<p_numeric_equals()> allowing
for basic regular expression matches using a compiled regex or by 
supplementing it with a subroutine to run the match on. This does not apply
any numeric tests since it's quite valid to regex against a number. However
it will return false if the value retrieved or evaluated was undefined.

=head2 p_substring()

  p_substring('world')->apply('hello world'); #returns true
  p_substring('o')->apply('hello world'); #returns true
  p_substring('goodbye')->apply('hello world'); #returns false
  
  #Again assume our Dog object returns arrooowww
  p_substring('ooo', 'howl')->apply($dog);

This is another type of test which when looking for substrings is far more
performant than using C<p_regex()>. The logic is to use your first variable
as the substring to look for in the given value. If the index is greater than
-1 we return true.

In micro-benchmarks we can see a 4x improvement in speed in using the
substring style predicate over using regular expressions. Substring
also has the advantage that you cannot have your substring mis-interpreted
as a regular expression control character e.g. a period or braces

=head1 DEPENDENCIES

=over 8

=item Scalar::Util

=item Readonly

=back

=head1 AUTHOR

Andrew Yates

=head1 LICENCE

Copyright (c) 2010 - 2010 European Molecular Biology Laboratory.

Author: Andrew Yates (ayatesattheebi - remove the relevant sections accordingly)

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright 
      notice, this list of conditions and the following disclaimer.
   2. Redistributions in binary form must reproduce the above copyright 
      notice, this list of conditions and the following disclaimer in the 
      documentation and/or other materials provided with the distribution.
   3. Neither the name of the Genome Research Ltd nor the names of its 
      contributors may be used to endorse or promote products derived from 
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR 
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; 
OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF 
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut