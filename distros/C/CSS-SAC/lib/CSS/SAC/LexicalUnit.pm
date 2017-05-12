
###
# CSS::SAC::LexicalUnit - SAC units
# Robin Berjon <robin@knowscape.com>
# 24/02/2001
###

package CSS::SAC::LexicalUnit;
use strict;
use vars qw($VERSION);
$VERSION = $CSS::SAC::VERSION || '0.03';

#---------------------------------------------------------------------#
# build the fields for an array based object
#---------------------------------------------------------------------#
use Class::ArrayObjects define => {
                                   fields => [qw(
                                                 _type_
                                                 _value_
                                                 _text_
                                               )],
                                  };
#---------------------------------------------------------------------#


### Constants #########################################################
#                                                                     #
#                                                                     #


sub ATTR                () {  1 }
sub CENTIMETER          () {  2 }
sub COUNTER_FUNCTION    () {  3 }
sub COUNTERS_FUNCTION   () {  4 }
sub DEGREE              () {  5 }
sub DIMENSION           () {  6 }
sub EM                  () {  7 }
sub EX                  () {  8 }
sub FUNCTION            () {  9 }
sub GRADIAN             () { 10 }
sub HERTZ               () { 11 }
sub IDENT               () { 12 }
sub INCH                () { 13 }
sub INHERIT             () { 14 }
sub INTEGER             () { 15 }
sub KILOHERTZ           () { 16 }
sub MILLIMETER          () { 17 }
sub MILLISECOND         () { 18 }
sub OPERATOR_COMMA      () { 19 }
sub OPERATOR_EXP        () { 20 }
sub OPERATOR_GE         () { 21 }
sub OPERATOR_GT         () { 22 }
sub OPERATOR_LE         () { 23 }
sub OPERATOR_LT         () { 24 }
sub OPERATOR_MINUS      () { 25 }
sub OPERATOR_MOD        () { 26 }
sub OPERATOR_MULTIPLY   () { 27 }
sub OPERATOR_PLUS       () { 28 }
sub OPERATOR_SLASH      () { 29 }
sub OPERATOR_TILDE      () { 30 }
sub PERCENTAGE          () { 31 }
sub PICA                () { 32 }
sub PIXEL               () { 33 }
sub POINT               () { 34 }
sub RADIAN              () { 35 }
sub REAL                () { 36 }
sub RECT_FUNCTION       () { 37 }
sub RGBCOLOR            () { 38 }
sub SECOND              () { 39 }
sub STRING_VALUE        () { 40 }
sub SUB_EXPRESSION      () { 41 }
sub UNICODERANGE        () { 42 }
sub URI                 () { 43 }



#---------------------------------------------------------------------#
# import()
# all import can do is export the constants
#---------------------------------------------------------------------#
sub import {
    my $class = shift;
    my $tag = shift || '';

    # check that we have the right tag
    return unless $tag eq ':constants';

    # define some useful vars
    my $pkg = caller;
    my @constants = qw(
                        ATTR CENTIMETER COUNTER_FUNCTION COUNTERS_FUNCTION
                        DEGREE DIMENSION EM EX FUNCTION GRADIAN HERTZ
                        IDENT INCH INHERIT INTEGER KILOHERTZ MILLIMETER
                        MILLISECOND OPERATOR_COMMA OPERATOR_EXP OPERATOR_GE
                        OPERATOR_GT OPERATOR_LE OPERATOR_LT OPERATOR_MINUS
                        OPERATOR_MOD OPERATOR_MULTIPLY OPERATOR_PLUS
                        OPERATOR_SLASH OPERATOR_TILDE PERCENTAGE PICA PIXEL
                        POINT RADIAN REAL RECT_FUNCTION RGBCOLOR SECOND
                        STRING_VALUE SUB_EXPRESSION UNICODERANGE URI
                      );

    # now lets create the constants in the caller's package
    no strict 'refs';
    for my $c (@constants) {
        my $qname = "${pkg}::$c";
        *$qname = \&{$c};
    }
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Constants #########################################################


### Constructor #######################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# CSS::SAC::LexicalUnit->new($type,$text,$value)
# creates a new sac lexical unit object
#---------------------------------------------------------------------#
sub new {
    my $class = ref($_[0])?ref(shift):shift;
    my $type  = shift;
    my $text  = shift;
    my $value = shift;

    # define our fields
    my $self = [];
    $self->[_type_]  = $type;
    $self->[_text_]  = $text;
    $self->[_value_] = $value;

    return bless $self, $class;
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Constructor #######################################################




### Accessors #########################################################
#                                                                     #
#                                                                     #

# defined aliases
*CSS::SAC::LexicalUnit::getDimensionUnitText = \&DimensionUnitText;
*CSS::SAC::LexicalUnit::getFunctionName = \&FunctionName;
*CSS::SAC::LexicalUnit::getValue = \&Value;
*CSS::SAC::LexicalUnit::getLexicalUnitType = \&LexicalUnitType;

#---------------------------------------------------------------------#
# my $dut = $lu->DimensionUnitText
# $lu->DimensionUnitText($dut)
# get/set the text of the dimension unit (eg cm, px, etc...)
#---------------------------------------------------------------------#
sub DimensionUnitText {
    (@_==2) ? $_[0]->[_text_] = $_[1] :
              $_[0]->[_text_];
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $fn = $lu->FunctionName
# $lu->FunctionName($fn)
# get/set the name of the function (eg attr, uri, etc...)
#---------------------------------------------------------------------#
sub FunctionName {
    (@_==2) ? $_[0]->[_text_] = $_[1] :
              $_[0]->[_text_];
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $value = $lu->Value
# $lu->Value($value)
# get/set the value of the lu (which may be another lu, or a lu list)
#---------------------------------------------------------------------#
sub Value {
    (@_==2) ? $_[0]->[_value_] = $_[1] :
              $_[0]->[_value_];
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $type = $lu->LexicalUnitType
# $lu->LexicalUnitType($type)
# get/set the type of the lu
#---------------------------------------------------------------------#
sub LexicalUnitType {
    (@_==2) ? $_[0]->[_type_] = $_[1] :
              $_[0]->[_type_];
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# $lu->is_type($lu_constant)
# returns true is this lu is of type $lu_constant
#---------------------------------------------------------------------#
sub is_type {
    return $_[0]->[_type_] == $_[1];
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Accessors #########################################################


1;
=pod

=head1 NAME

CSS::SAC::LexicalUnit - SAC units

=head1 SYNOPSIS

  use CSS::SAC::LexicalUnit qw(:constants);
  foo if $lu->is_type(LU_TYPE_CONSTANT);

=head1 DESCRIPTION

In the SAC spec, LexicalUnit is a linked list, that is, you only ever
hold one LexicalUnit, and you ask for the next of for the previous one
when you want to move on.

Such a model seems awkward, though I'm sure it makes sense somehow in
Java, likely for a Java-specific reason.

In the Perl implementation, I have changed this. A LexicalUnit is an
object that stands on it's own and has no next/previous objects.
Instead, the $handler->property callback gets called with a
LexicalUnitList, which is in fact just an array ref of LexicalUnits.

We also don't differentiate between IntegerValue, FloatValue, and
StringValue, it's always Value in Perl. This also applies to
Parameters and SubValues. Both are called as Value and return an array
ref of LexicalUnits.

I added the is_type() method, see CSS::SAC::Condition for advantages
of that approach.

=head1 CONSTANTS

=over 4

=item * ATTR

=item * CENTIMETER

=item * COUNTER_FUNCTION

=item * COUNTERS_FUNCTION

=item * DEGREE

=item * DIMENSION

=item * EM

=item * EX

=item * FUNCTION

=item * GRADIAN

=item * HERTZ

=item * IDENT

=item * INCH

=item * INHERIT

=item * INTEGER

=item * KILOHERTZ

=item * MILLIMETER

=item * MILLISECOND

=item * OPERATOR_COMMA

=item * OPERATOR_EXP

=item * OPERATOR_GE

=item * OPERATOR_GT

=item * OPERATOR_LE

=item * OPERATOR_LT

=item * OPERATOR_MINUS

=item * OPERATOR_MOD

=item * OPERATOR_MULTIPLY

=item * OPERATOR_PLUS

=item * OPERATOR_SLASH

=item * OPERATOR_TILDE

=item * PERCENTAGE

=item * PICA

=item * PIXEL

=item * POINT

=item * RADIAN

=item * REAL

=item * RECT_FUNCTION

=item * RGBCOLOR

=item * SECOND

=item * STRING_VALUE

=item * SUB_EXPRESSION

=item * UNICODERANGE

=item * URI

=back

=head1 METHODS

=over

=item * CSS::SAC::LexicalUnit->new($type,$text,$value) or $lu->new($type,$text,$value)

Creates a new unit. The $type must be one of the type constants, the
text depends on the type of unit (unit text, func name, etc...), and
the value is the content of the lu.

=item * $lu->DimensionUnitText([$dut]) or getDimensionUnitText

get/set the text of the dimension unit (eg cm, px, etc...)

=item * $lu->FunctionName([$fn]) or getFunctionName

get/set the name of the function (eg attr, uri, etc...)

=item * $lu->Value([$value]) or getValue

get/set the value of the lu (which may be another lu, or a lu list)

=item * $lu->LexicalUnitType([$type]) or getLexicalUnitType

get/set the type of the lu

=item * $lu->is_type($lu_constant)

returns true is this lu is of type $lu_constant

=back

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut


