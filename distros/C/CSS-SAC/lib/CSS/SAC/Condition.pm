
###
# CSS::SAC::Condition - base class for SAC conditions
# Robin Berjon <robin@knowscape.com>
# 24/02/2001
###

package CSS::SAC::Condition;
use strict;
use vars qw($VERSION);
$VERSION = $CSS::SAC::VERSION || '0.03';

#---------------------------------------------------------------------#
# build the fields for an array based object
#---------------------------------------------------------------------#
use Class::ArrayObjects define => {
                                   fields => [qw(_type_)],
                                  };
#---------------------------------------------------------------------#


### Constants #########################################################
#                                                                     #
#                                                                     #

sub UNKNOWN_CONDITION                () {  1 }
sub AND_CONDITION                    () {  2 }
sub ATTRIBUTE_CONDITION              () {  3 }
sub BEGIN_HYPHEN_ATTRIBUTE_CONDITION () {  4 }
sub CLASS_CONDITION                  () {  5 }
sub CONTENT_CONDITION                () {  6 }
sub ID_CONDITION                     () {  7 }
sub LANG_CONDITION                   () {  8 }
sub NEGATIVE_CONDITION               () {  9 }
sub ONE_OF_ATTRIBUTE_CONDITION       () { 10 }
sub ONLY_CHILD_CONDITION             () { 11 }
sub ONLY_TYPE_CONDITION              () { 12 }
sub OR_CONDITION                     () { 13 }
sub POSITIONAL_CONDITION             () { 14 }
sub PSEUDO_CLASS_CONDITION           () { 15 }

# new non-standard conditions for CSS3 selectors
sub STARTS_WITH_ATTRIBUTE_CONDITION () { 16 }   # [attr^='string']
sub ENDS_WITH_ATTRIBUTE_CONDITION   () { 17 }   # [attr$='string']
sub CONTAINS_ATTRIBUTE_CONDITION    () { 18 }   # [attr*='string']
sub IS_ROOT_CONDITION               () { 19 }   # :root
sub IS_EMPTY_CONDITION              () { 20 }   # :empty

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
                        UNKNOWN_CONDITION
                        AND_CONDITION
                        ATTRIBUTE_CONDITION
                        BEGIN_HYPHEN_ATTRIBUTE_CONDITION
                        CLASS_CONDITION
                        CONTENT_CONDITION
                        ID_CONDITION
                        LANG_CONDITION
                        NEGATIVE_CONDITION
                        ONE_OF_ATTRIBUTE_CONDITION
                        ONLY_CHILD_CONDITION
                        ONLY_TYPE_CONDITION
                        OR_CONDITION
                        POSITIONAL_CONDITION
                        PSEUDO_CLASS_CONDITION

                        STARTS_WITH_ATTRIBUTE_CONDITION
                        ENDS_WITH_ATTRIBUTE_CONDITION
                        CONTAINS_ATTRIBUTE_CONDITION
                        IS_ROOT_CONDITION
                        IS_EMPTY_CONDITION
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
# CSS::SAC::Condition->new($type)
# creates a new sac condition object
#---------------------------------------------------------------------#
sub new {
    my $class = ref($_[0])?ref(shift):shift;
    my $type = shift;
    return bless [$type], $class;
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Constructor #######################################################



### Accessors #########################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# my $type = $cond->ConditionType()
# $cond->ConditionType($type)
# get/set the condition type
#---------------------------------------------------------------------#
sub ConditionType {
    (@_==2) ? $_[0]->[_type_] = $_[1] :
              $_[0]->[_type_];
}
#---------------------------------------------------------------------#
*CSS::SAC::Condition::getConditionType = \&ConditionType;


#---------------------------------------------------------------------#
# $cond->is_type($condition_constant)
# returns true is this condition is of type $condition_constant
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

CSS::SAC::Condition - base class for SAC conditions

=head1 SYNOPSIS

  use CSS::SAC::Condition qw(:constants);
  foo if $cond->is_type(CONDITION_TYPE_CONSTANT);

=head1 DESCRIPTION

SAC Conditions describe conditions that can be expressed in CSS such
as AttributeConditions or PositionalConditions. This class provides
everything that is needed to implement simple conditions (methods,
constants) as well as what is needed by subclasses defining more
complex conditions.

The constants are those defined in the SAC spec, with the leading SAC_
removed. What the constants map to is to be considered an opaque token
that can be tested for equality. If there is demand for it, I will add
a way to add new constants (for people wishing to define new condition
types).

I have also added the UNKNOWN_CONDITION constant. It shouldn't occur
in normal processing but it's always useful to have such fallback
values.

The Condition interface adds $cond->is_type($condition_type) to the
interface defined in the SAC spec. This allows for more flexible type
checking. For instance, if you create a subclass of ContentCondition
that extends it with the ContentRegexCondition interface you will
probably want software ignorant of your subclass's existence to still
be able to do something useful with it. That software should also be
able to treat ContentRegexConditions as if they were
ContentConditions.

If that software tests condition types the following way:

  $rcond->ConditionType == CONTENT_CONDITION

then you've lost because the condition type of ContentRegexCondition
is REGEX_CONTENT_CONDITION. If, however, it tests it that way:

  $rcond->is_type(CONTENT_CONDITION)

then you can simply implement is_type() so that it returns true for
it's own type and the type of it's superclass. I strongly recommend
using the latter scheme except in cases when you want to know the
exact type.

=head1 CONSTANTS

=over 4

=item * UNKNOWN_CONDITION

=item * AND_CONDITION

=item * ATTRIBUTE_CONDITION

=item * BEGIN_HYPHEN_ATTRIBUTE_CONDITION

=item * CLASS_CONDITION

=item * CONTENT_CONDITION

=item * ID_CONDITION

=item * LANG_CONDITION

=item * NEGATIVE_CONDITION

=item * ONE_OF_ATTRIBUTE_CONDITION

=item * ONLY_CHILD_CONDITION

=item * ONLY_TYPE_CONDITION

=item * OR_CONDITION

=item * POSITIONAL_CONDITION

=item * PSEUDO_CLASS_CONDITION

=back

=head1 METHODS

=over 4

=item * CSS::SAC::Condition->new($type) or $cond->new($type)

Creates a new condition. The $type must be one of the type constants.

=item * $cond->ConditionType()

Returns the constant corresponding to the type of this condition.

=item * $cond->is_type($condition_type)

Returns a boolean indicating whether this condition is of type
$condition_type (a condition constant).

=back

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut


