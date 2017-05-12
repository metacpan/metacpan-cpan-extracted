
###
# CSS::SAC::Selector - base class for SAC selectors
# Robin Berjon <robin@knowscape.com>
# 24/02/2001
###

package CSS::SAC::Selector;
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

sub UNKNOWN_SELECTOR                        () {  1 }
sub ANY_NODE_SELECTOR                       () {  2 }
sub CDATA_SECTION_NODE_SELECTOR             () {  3 }
sub CHILD_SELECTOR                          () {  4 }
sub COMMENT_NODE_SELECTOR                   () {  5 }
sub CONDITIONAL_SELECTOR                    () {  6 }
sub DESCENDANT_SELECTOR                     () {  7 }
sub DIRECT_ADJACENT_SELECTOR                () {  8 }
sub ELEMENT_NODE_SELECTOR                   () {  9 }
sub NEGATIVE_SELECTOR                       () { 10 }
sub PROCESSING_INSTRUCTION_NODE_SELECTOR    () { 11 }
sub PSEUDO_ELEMENT_SELECTOR                 () { 12 }
sub ROOT_NODE_SELECTOR                      () { 13 }
sub TEXT_NODE_SELECTOR                      () { 14 }

# EXPERIMENTAL SELECTOR
sub INDIRECT_ADJACENT_SELECTOR              () { 15 }


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
                        UNKNOWN_SELECTOR
                        ANY_NODE_SELECTOR
                        CDATA_SECTION_NODE_SELECTOR
                        CHILD_SELECTOR
                        COMMENT_NODE_SELECTOR
                        CONDITIONAL_SELECTOR
                        DESCENDANT_SELECTOR
                        DIRECT_ADJACENT_SELECTOR
                        ELEMENT_NODE_SELECTOR
                        NEGATIVE_SELECTOR
                        PROCESSING_INSTRUCTION_NODE_SELECTOR
                        PSEUDO_ELEMENT_SELECTOR
                        ROOT_NODE_SELECTOR
                        TEXT_NODE_SELECTOR

                        INDIRECT_ADJACENT_SELECTOR
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
# CSS::SAC::Selector->new($type)
# creates a new sac selector object
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
# my $type = $sel->SelectorType()
# $sel->SelectorType($type)
# get/set the selector type
#---------------------------------------------------------------------#
sub SelectorType {
    (@_==2) ? $_[0]->[_type_] = $_[1] :
              $_[0]->[_type_];
}
#---------------------------------------------------------------------#
*CSS::SAC::Selector::getSelectorType = \&SelectorType;

#---------------------------------------------------------------------#
# $sel->is_type($selector_constant)
# returns true is this selector is of type $selector_constant
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

CSS::SAC::Selector - base class for SAC selectors

=head1 SYNOPSIS

  use CSS::SAC::Selector qw(:constants);
  foo if $sel->is_type(SELECTOR_TYPE_CONSTANT);

=head1 DESCRIPTION

SAC Selectors describe selectors that can be expressed in CSS such
as ElementSelector or SiblingSelector. This class provides everything
that is needed to implement simple selectors (methods, constants) as
well as what is needed by subclasses defining more complex selectors.

The constants are those defined in the SAC spec, with the leading SAC_
removed. What the constants map to is to be considered an opaque token
that can be tested for equality. If there is demand for it, I will add
a way to add new constants (for people wishing to define new condition
types).

I have also added the UNKNOWN_SELECTOR constant. It shouldn't occur
in normal processing but it's always useful to have such fallback
values.

The Selector interface adds $sel->is_type($selector_type) to the
interface defined in the SAC spec. This allows for more flexible type
checking. The advantages are the same as those described for the same
extension in the CSS::SAC::Condition class.

=head1 CONSTANTS

=over

=item * UNKNOWN_SELECTOR

=item * ANY_NODE_SELECTOR

=item * CDATA_SECTION_NODE_SELECTOR

=item * CHILD_SELECTOR

=item * COMMENT_NODE_SELECTOR

=item * CONDITIONAL_SELECTOR

=item * DESCENDANT_SELECTOR

=item * DIRECT_ADJACENT_SELECTOR

=item * ELEMENT_NODE_SELECTOR

=item * NEGATIVE_SELECTOR

=item * PROCESSING_INSTRUCTION_NODE_SELECTOR

=item * PSEUDO_ELEMENT_SELECTOR

=item * ROOT_NODE_SELECTOR

=item * TEXT_NODE_SELECTOR

=back

=head1 METHODS

=over

=item * CSS::SAC::Selector->new($type) or $sel->new($type)

Creates a new selector. The $type must be one of the type constants.

=item * $sel->SelectorType() or $sel->getSelectorType

Returns the constant corresponding to the type of this selector.

=item * $sel->is_type($selector_type)

Returns a boolean indicating whether this selector is of type
$selector_type (a selector constant).

=back

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut


