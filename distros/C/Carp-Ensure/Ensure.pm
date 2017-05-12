package Carp::Ensure;

# Copyright 2002 Stefan Merten

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use strict;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

use Carp;

require Exporter;

$VERSION = '$Name: Carp_Ensure_1_23 $' =~ /_(\d+)_(\d+)\b/ && sprintf("%d.%02d", $1 - 1, $2);

@ISA = qw( Exporter );

###############################################################################
# The idea of the following is shamelessly stolen from `Carp::Assert'

@EXPORT = qw( ensure DEBUG );
@EXPORT_OK = qw( is_a );
$EXPORT_TAGS{NDEBUG} = $EXPORT_TAGS{DEBUG} = [ @EXPORT ];

sub REAL_DEBUG() { 1 }
sub NDEBUG() { 0 }
sub noop { undef }

# Export the proper DEBUG flag according to if :NDEBUG is set.
# Also export noop versions of our routines if NDEBUG
sub import($@) {
  my( $cls, @syms ) = @_;

  if(scalar(grep{ $_ eq ':NDEBUG' }(@syms)) ||
     (exists($ENV{PERL_NDEBUG}) ? $ENV{PERL_NDEBUG} : $ENV{'NDEBUG'})) {
    my $dst = caller();
    foreach ( @{$EXPORT_TAGS{NDEBUG}} ) {
      no strict 'refs';
      *{$dst . '::' . $_} = $_ eq 'DEBUG' ? \&NDEBUG : \&noop;
    }
    Carp::Ensure->export_to_level(1, $cls, grep{ $_ ne ':NDEBUG' }(@syms));
  }
  else {
    *DEBUG = *REAL_DEBUG;
    Carp::Ensure->export_to_level(1, $cls, @syms);
  }
}

sub unimport($@) {
  my( $cls, @syms ) = @_;

  *DEBUG = *NDEBUG;
  import($cls, ':NDEBUG', @syms);
}

# End of stolen idea
###############################################################################

=head1 NAME

Carp::Ensure - Ensure a value is of the expected type

=head1 SYNOPSIS

  use Carp::Ensure( qw( is_a ) );

  ensure('string', "Some arbitrary string") if DEBUG;
  ensure('@integer', 1, 2, 3) if DEBUG;
  ensure('@\integer', \1, \2, \3) if DEBUG;

  my %word2Int = ( one => 1, two => 2, three => 3 );
  my @ints = values(%word2Int);
  my @wordsInts = ( keys(%word2Int), @ints );

  ensure('\@integer', \@ints) if DEBUG;

  ensure('@word|integer', %word2Int) if DEBUG;
  ensure('%word=>integer', %word2Int) if DEBUG;

  die("Unexpected type")
      unless is_a('@word|integer', @wordsInts);
  die("Unexpected type")
      unless is_a('@\@word|integer', \@wordsInts, [ "four", 4 ]);

  # Receives a string, a `Mail::Internet' object, a reference to a hash mapping
  # strings to integers
  sub someSub($$%) {
    ensure([ qw( string Mail::Internet HASH %string=>integer ) ], \@_) if DEBUG;
    my( $string, $object, %hash ) = @_;

    # ...
  }

=head1 DESCRIPTION

Most of the time it's a nice feature, that Perl has no really strict type
checking as in C++. However, sometimes you want to ensure, that you subs
actually get the type of arguments they expect. Or they return what you expect.

That is where B<Carp::Ensure> may be useful. You can check every value whether
it has the type you expect. You may fine tune the type checking from very
coarse checking like defined vs. undefined to very detailed checks which check
even the keys and values of a hash. In most places you may give alternative
types so for instance a parameter can easily be checked to be of a certain type
or undefined.

There are checking routines for a few commonly used base types included and you
may add your own checking routines so you can check for the types specific to
your program.

The types are described by a simple grammar which picks up as much as possible
you already know from the Perl type system.

=cut

###############################################################################

=head1 FUNCTIONS

=over 4

=item B<ensure>

  use Carp::Ensure;

  ensure("some_type", $value) if DEBUG;
  ensure("@value_type", @array) if DEBUG;
  ensure("%key_type=>value_type", %hash) if DEBUG;

  ensure([ qw( type1 type2 ... ) ], [ $value1, $value2, ... ]) if DEBUG;
  ensure([ qw( type1 type2 ... ) ], \@_) if DEBUG;

Checks whether the types described in the first argument are matched by the
values given in the following arguments. If the values match the type B<ensure>
returns an aribtrary value. If a value doesn't match the specified type,
B<ensure> B<Carp::confess>es with an approriate error message and thus stops
the program.

If the first argument is a string, it describes the type of the remaining
arguments which may be arbitrary many (including none). This is useful for list
types (i.e. arrays and hashes) and to check single values.

If the first argument is a reference to an array, the second argument must be a
reference to an array, too. In this calling scheme the first array describes
the types contained in the second argument. It is particularly useful to check
the argument list of a sub.

Care is taken to not change the second argument in any way.

Note, that usually ot only makes sense when the last of the described types
checks for a list type. This is because in Perl a list type sucks up all the
remaining values.

See L<"TYPE GRAMMAR"> for how the types are described.

The C<if DEBUG> concept is taken from L<Carp::Assert> where it is explained in
detail (particularly in L<Carp::Assert/"Debugging vs Production">. Actually the
B<DEBUG> value is probably shared between L<Carp::Assert> and this module. So
take care when enabling it in one and disabling it in the other package C<use>.
In short: If you say C<use Carp::Ensure> you switch B<DEBUG> on and B<ensure>
works as expected. If you say C<no Carp::Ensure> then the whole call is
compiled away from the program and has no impact on efficiency.

=cut

sub ensure($@) {
  # Call it with our arguments to save a copy
  my $err = &_is_not;
  confess("ensure: $err")
      if $err;
  return !undef;
}

###############################################################################

=item B<is_a>

  # Both are possible
  use Carp::Ensure( qw( :DEBUG is_a ) );
  use Carp::Ensure( qw( :NDEBUG is_a ) );

  $is_of_type = is_a("some_type", $value);
  $is_of_type = is_a("@value_type", @array);
  $is_of_type = is_a("%key_type=>value_type", %hash);

  $is_of_type = is_a([ qw( type1 type2 ... ) ], [ $value1, $value2, ... ]);
  $is_of_type = is_a([ qw( type1 type2 ... ) ], \@_);

This does the same as B<ensure>, however, it only returns true or false instead
of B<Carp::confess>ing. You can use this to check types of values without
immediately stopping the program on failure or to build your own testing subs
like this:

	sub Carp::Ensure::is_a_word1empty { Carp::Ensure::is_a('word|empty', ${shift()}) }

If a false value is returned I<$@> is set to an error message. Otherwise I<$@>
is undefined.

=cut

sub is_a($@) {
  # Call it with our arguments to save a copy
  $@ = &_is_not;
  return !$@;
}

###############################################################################

my $ErrTpCall = 1;
my $ErrTpDscr = 2;
my $ErrTpType = 3;

# This does the real work. Returns an error message or undef.
sub _is_not($@) {
  my $tp = shift();

  my $err;
  unless(defined($tp))
    { $err = "$ErrTpCall Undefined first argument"; }
  elsif(!ref($tp)) {
    my $cTp = $tp;
    $cTp =~ s/\s+//g;
    $err = _type($cTp, 0, \@_);
  }
  elsif(ref($tp) eq "ARRAY") {
    my $vals = shift();
    if(@_)
      { $err = "$ErrTpCall Too many arguments"; }
    elsif(ref($vals) ne "ARRAY")
      { $err = "$ErrTpCall Second argument must be an array reference, too"; }
    else {
      for(my $i = 0; !$err && $i < @$tp; $i++) {
	if(!defined($tp->[$i]) || ref($tp->[$i]))
	  { $err = "$ErrTpCall Not a string element at index $i of first argument"; }
	else {
          my $cTp = $tp->[$i];
          $cTp =~ s/\s+//g;
	  $err = _type($cTp, $i, $vals);
        }
      }
    }
  }
  else
    { $err = "$ErrTpCall First argument must be a string or array reference"; }
  return undef
      unless $err;

  my $errTp;
  ( $errTp, $err ) = $err =~ /^(\d+)(.*)$/;
  return "Invalid " .
      ($errTp == $ErrTpCall ? "call" :
       $errTp == $ErrTpDscr ? "description" :
       $errTp == $ErrTpType ? "type" : "unknown") . ":$err";
}

###############################################################################

=back

=head1 TYPE GRAMMAR

You may create rather complex type descriptions from the following grammar.

=head2 Lexical rules

Since whitespace is not relevant in the grammar, it may occur anywhere outside
of identifiers. Actually any whitespace is removed before parsing the type
description starts.

=head2 Grammar rules

=cut

# All subs implementing the grammar return an error message or `undef' if
# everything worked.

=over 4

=item I<type> :=

I<hash> | I<array> | I<alternative>

=cut

sub _type($$$ ) {
  my( $tp, $idx, $arr ) = @_;

  if($tp =~ /^\@/)
    { return _array($tp, $idx, $arr); }
  elsif($tp =~ /^\%/)
    { return _hash($tp, $idx, $arr); }
  else
    { return _alternative($tp, \$arr->[$idx]); }
}

###############################################################################

=item I<hash> :=

'C<%>' I<alternative> 'C<=>>' I<alternative>

=cut

sub _hash($$$ ) {
  my( $tp, $idx, $arr ) = @_;

  $tp =~ s/^\%//;
  return "$ErrTpDscr Missing `=>' in hash type `\%$tp'"
      unless $tp =~ /=>/;

  my( $keyTp, $valTp ) = ( $`, $' );
  my $err;
  $err = _alternative($keyTp, \$arr->[$idx++]) ||
      _alternative($valTp, \$arr->[$idx++])
      while !$err && $idx < @$arr;
  return $err;
}

###############################################################################

=item I<array> :=

'C<@>' I<alternative>

=cut

sub _array($$$ ) {
  my( $tp, $idx, $arr ) = @_;

  $tp =~ s/^\@//;

  my $err;
  $err = _alternative($tp, \$arr->[$idx++])
      while !$err && $idx < @$arr;
  return $err;
}

###############################################################################

=item I<alternative> :=

I<simple> 'C<|>' I<alternative> | I<simple>

=cut

sub _alternative($$) {
  my( $tp, $val ) = @_;

  return _simple($tp, $val)
      unless $tp =~ /\|/;

  foreach my $alt ( split(/\|/, $tp) ) {
    my $err = _simple($alt, $val);
    return undef
	unless $err;

    my ( $errTp ) = $err =~ /^(\d+)/;
    return $err
	if $errTp < $ErrTpType;
  }
  return "$ErrTpType `" . $$val . "' is not one of `$tp'";
}

###############################################################################

=item I<simple> :=

I<reference> | I<dynamic> | I<special> | I<scalar>

=item I<reference> :=

'C<\>' I<type> | I<class> | I<object> | 'C<HASH>' | 'C<ARRAY>' | 'C<CODE>' | 'C<GLOB>'

Note: Take care with the C<\>. Even in a string using single quotes a directly
following backslash quotes a backslash! Whitespace between subsequent
backslashes simplifies things greatly.

=cut

my @referenceSs = qw( HASH ARRAY CODE GLOB );

sub _reference($$) {
  my( $tp, $val ) = @_;

  if(grep{ $tp eq $_ }(@referenceSs))
    { return _is_a($tp, $val); }
  elsif($tp =~ /^\^/)
    { return _class($tp, $val); }
  elsif($tp =~ s/^\\//) {
    return "$ErrTpType `" . $$val . "' is not a reference"
	unless ref($val) eq "REF";

    my $refTp = ref($$val);
    if($refTp eq "SCALAR" || $refTp eq "REF")
      { return _type($tp, 0, [ $$$val ]); }
    elsif($refTp eq "HASH")
      { return _type($tp, 0, [ %$$val ]); }
    elsif($refTp eq "ARRAY")
      { return _type($tp, 0, [ @$$val ]); }
    elsif($refTp eq "CODE")
      { return _type($tp, 0, [ &$$val ]); }
    elsif($refTp eq "GLOB")
      { return _type($tp, 0, [ *$$val ]); }
    else # object
      { return _type($tp, 0, [ $$val ]); }
  }
  else
    { return _object($tp, $val); }
}

###############################################################################

=item I<dynamic> :=

I<user>

=cut

sub _dynamic($$) {
  my( $tp, $val ) = @_;

  return _user($tp, $val);
}

###############################################################################

=item I<special> :=

'C<undefined>' | 'C<defined>' | 'C<anything>'

=cut

my @specialSs = qw( undefined defined anything );

sub _special($$) {
  my( $tp, $val ) = @_;

  return _is_a($tp, $val);
}

###############################################################################

=item I<scalar> :=

'C<string>' | 'C<word>' | 'C<empty>' | 'C<integer>' | 'C<float>' | 'C<boolean>' | 'C<regex>'

These common simple types are predefined.

=cut

my @scalarSs = qw( string word empty integer float boolean regex );

sub _scalar($$) {
  my( $tp, $val ) = @_;

  return "$ErrTpDscr Unknown scalar type `$tp'"
      unless grep{ $tp eq $_ }(@scalarSs);

  return _is_a($tp, $val);
}

###############################################################################

=item I<class> :=

'C<^>' I<object>

A value matching such a type is a name of a class (i.e. a string) represented
by the name matching the regular expression I<object>. This may mean, that the
class is a superclass of the class given by the value.

Thus the first parameter of a method which might be used static as well as with
an object has a type of

	Some::Class|^Some::Class

=cut

sub _class($$) {
  my( $tp, $val ) = @_;

  $tp =~ /^\^/;
  my $cls = $';
  return ref($val) eq "SCALAR" && eval { $$val->isa($cls) } ? undef :
      "$ErrTpType `" . $$val . "' is not of type `$tp'";
}

###############################################################################

=item I<object> :=

I</^[A-Z]\w*(::\w+)*$/>

The value is a object (i.e. a blessed reference) of the class represented by
the name matching the regular expression. This may mean, that the class is a
superclass of the object's class.

=cut

my $objectRe = '[A-Z]\w*(::\w+)*';

sub _object($$) {
  my( $tp, $val ) = @_;

  return ref($val) eq "REF" && UNIVERSAL::isa($$val, $tp) ? undef :
      "$ErrTpType `" . $$val . "' is not of type `$tp'";
}

###############################################################################

=item I<user> :=

I</^[a-z]\w*$/>

This might be a string I<userType> matching the regular expression. For this a
sub

C<Carp::Ensure::is_a_>I<userType>

must be defined. When checking a value for being a I<userType>, the sub is
called with a single argument being a B<reference>(!) to the value it should
check. This minimizes copying. The sub must return false if the referenced
value is not of the desired type and a true value otherwise. See C<is_a> for an
example.

=cut

my $userRe = '[a-z]\w*';

sub _user($$) {
  my( $tp, $val ) = @_;

  return _is_a($tp, $val);
}

###############################################################################

sub _simple($$) {
  my( $tp, $val ) = @_;

  if(grep{ $tp eq $_ }(@scalarSs))
    { return _scalar($tp, $val); }
  elsif(grep{ $tp eq $_ }(@specialSs))
    { return _special($tp, $val); }
  elsif($tp =~ /^$userRe$/)
    { return _dynamic($tp, $val); }
  elsif(scalar(grep{ $tp eq $_ }(@referenceSs)) ||
	$tp =~ /^\\/ || $tp =~ /^$objectRe$/ || $tp =~ /^\^$objectRe$/)
    { return _reference($tp, $val); }
  else
    { return "$ErrTpDscr Unparsable simple type `$tp'"; }
}

###############################################################################

=back

=head2 Terminal symbols

The terminal symbols have the following meaning:

=cut

###############################################################################

# Calls the `is_a_$tp'(`$val') sub.
sub _is_a($$) {
  my( $tp, $val ) = @_;

  my $sub = "is_a_$tp";
  no strict 'refs';
  return "$ErrTpDscr No user defined test `Carp::Ensure::$sub'"
      unless defined(&$sub);

  return &$sub($val) ? undef :
      "$ErrTpType `" . $$val . "' is not of type `$tp'";
}

###############################################################################

=over 4

=item C<HASH>

The value is a reference(!) to a hash with arbitrary keys and values. Use this
if you don't want to check the hash content.

=cut

sub is_a_HASH($ ) {
  my( $r ) = @_;

  return ref($r) eq "REF" && ref($$r) eq "HASH";
}

###############################################################################

=item C<ARRAY>

The value is a reference(!) to an array with arbitrary content. Use this if you
don't want to check the array content.

=cut

sub is_a_ARRAY($ ) {
  my( $r ) = @_;

  return ref($r) eq "REF" && ref($$r) eq "ARRAY";
}

###############################################################################

=item C<CODE>

The value is a reference to some code. This may be an anonymous or a named sub.

=cut

sub is_a_CODE($ ) {
  my( $r ) = @_;

  return ref($r) eq "REF" && ref($$r) eq "CODE";
}

###############################################################################

=item C<GLOB>

The value is a GLOB.

=cut

sub is_a_GLOB($ ) {
  my( $r ) = @_;

  return ref($r) eq "GLOB";
}

###############################################################################

=item C<undefined>

Only the undefined value is permitted. Often used as one part of an
alternative. Missing optional arguments of a sub are undefined, also.

=cut

sub is_a_undefined($ ) {
  my( $r ) = @_;

  return ref($r) eq "SCALAR" && !defined($$r);
}

###############################################################################

=item C<defined>

The value only needs to be defined.

=cut

sub is_a_defined($ ) {
  my( $r ) = @_;

  return defined($$r);
}

###############################################################################

=item C<anything>

Actually not a test since anything is permitted.

=cut

sub is_a_anything($ ) {
  return !undef;
}

###############################################################################

=item C<string>

An arbitrary string.

=cut

sub is_a_string($ ) {
  my( $r ) = @_;

  return ref($r) eq "SCALAR";
}

###############################################################################

=item C<word>

A string matching C</w+/>.

=cut

sub is_a_word($ ) {
  my( $r ) = @_;

  return ref($r) eq "SCALAR" && $$r =~ /^\w+$/;
}

###############################################################################

=item C<empty>

An empty string.

=cut

sub is_a_empty($ ) {
  my( $r ) = @_;

  return ref($r) eq "SCALAR" && defined($$r) && $$r eq "";
}

###############################################################################

=item C<integer>

An integer.

=cut

sub is_a_integer($ ) {
  my( $r ) = @_;

  return ref($r) eq "SCALAR" && $$r =~/^[-+]?\d+$/;
}

###############################################################################

=item C<float>

An floating point number.

=cut

sub is_a_float($ ) {
  my( $r ) = @_;

  return ref($r) eq "SCALAR" && $$r =~ /^[-+]?(\d+(\.\d*)?|\.\d+)([Ee][-+]?\d+)?$/;
}

###############################################################################

=item C<boolean>

A boolean. Actually every scalar is a boolean in Perl, so this is more a
description of how a certain value is used.

=cut

sub is_a_boolean($ ) {
  my( $r ) = @_;

  return ref($r) eq "SCALAR";
}

###############################################################################

=item C<regex>

A string which compiles cleanly as a regular expression. The C<regex> is
applied to an empty string so any parentheses in the C<regex> will probably
don't result in anything useful.

Note, that nothing prevents the C<regex> from executing arbitrary code if you
manage to include this somehow. The results are completly undefined.

=cut

sub is_a_regex($ ) {
  my( $r ) = @_;

  return ref($r) eq "SCALAR" && defined($$r) && defined(eval { "" =~ /$$r/ });
}

###############################################################################

=back

=head2 Precedence

The precedence of the operators is as indicated by the grammar. Because most
operators are prefix operators there is not much room for ambiguity anyway.
However, the grammar for alternatives opens some traps. In particular the
current grammar means, that it is not possible to have

=over 4

=item * references to alternatives

A type description C<\type1|type2> would be parsed as an alternative between
C<\type1> and C<type2> instead of a reference to either C<type1> or C<type2>.
Use C<\type1|\type2> instead.

=item * alternatives between array types

A type description C<@type1|@type2> is indeed not allowed by the grammar.
Probably you're thinking of C<@type1|type2> anyway which describes an array
consisting of C<type1> and/or C<type2> values.

If you want to describe arrays consisting of exactly one or another type use an
additional reference for your value and try C<\@type1|\@type2>.

=item * lists as hash value types

Similarly C<%typeK=>>C<@typeV1|typeV2> is not allowed by the grammar. It would
not make sense anyway because a list can not be the value of a hash key.

However, C<%typeK=>>C<\@typeV1|\@typeV2> is possible and describes a hash
mapping C<typeK> values to references to arrays consisting of either C<typeV1>
or C<typeV2> elements.

=item * references to list types with alternatives

A type description C<\@type1|type2> describes a reference to an array of
C<type1> elements or a C<type2> value. It is B<NOT> a reference to an array
consisting of C<type1> and/or C<type2> elements.

Even worse C<\%typeK1|typeK2=>>C<typeV> can't be parsed at all because the
alternative is evaluated before the hash designator.

=back

Note, that you can always define your own test functions which may break down
complex types to simple names. With the C<is_a> function this is usually done
with a few key strokes.

=head1 TODO

=over 4

=item *

As noted above the lack of parentheses in the grammar makes some complex
constructions impossible. However, introducing parentheses would make a more
complex parser necessary. After all user defined types may be used for
simulating parentheses.

If parentheses, brackets and braces would be added to the grammar, the
following changed productions would be probably best:

=over

=item I<simple> :=

'C<(>' I<alternative> 'C<)> | I<reference> | ...

=item I<reference> :=

'C<\>' I<simple> | 'C<[>' I<alternative> 'C<]>' | 'C<{>' I<alternative> 'C<=>>' I<alternative> 'C<}>' | I<class> | ...

=back

=item *

Furthermore it would be nice to have

=over 4

=item I<dynamic> :=

I<user> | 'C</>' I<match> 'C</>' | I<number> 'C<..>' I<number>

=item I<match> :=

I<a valid Perl regex>

=item I<number> :=

I</^[-+]?\d+(\.\d*)([Ee][-+]\d+)?$/>

=back

so you can define an anonymous type for a string matching a regex or for a
number being inside a range. But given the rich structure of Perl regexes at
least the I<match> would require a real parser.

=back

=head1 SIMILAR MODULES

There is the L<Usage> package which has a similar functionality. However, it
dates 1996 and seems not be maintained since then. Unfortunately it is not as
flexible as this module and is still a bit buggy.

=head1 AUTHOR

Stefan Merten <smerten@oekonux.de>

The idea for the code implementing the B<DEBUG> feature was taken from
L<Carp::Assert> by Michael G. Schwern <schwern@pobox.com>.

=head1 SEE ALSO

L<Carp>

L<Carp::Assert>

=head1 LICENSE

This program is licensed under the terms of the GPL. See

	http://www.gnu.org/licenses/gpl.txt

=head1 AVAILABILTY

See

	http://www.merten-home.de/FreeSoftware/Carp_Ensure/

=cut

1;
