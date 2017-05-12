
###
# CSS::SAC::Selector::Sibling - SAC SiblingSelector
# Robin Berjon <robin@knowscape.com>
# 24/02/2001
###

package CSS::SAC::Selector::Sibling;
use strict;
use vars qw($VERSION);
$VERSION = $CSS::SAC::VERSION || '0.03';

use base qw(CSS::SAC::Selector);


#---------------------------------------------------------------------#
# build the fields for an array based object
#---------------------------------------------------------------------#
use Class::ArrayObjects extend => {
                                   class => 'CSS::SAC::Selector',
                                   with  => [qw(
                                                _node_type_
                                                _selector_
                                                _sibling_selector_
                                              )],
                                  };
#---------------------------------------------------------------------#



### Constants #########################################################
#                                                                     #
#                                                                     #

sub ELEMENT_NODE                () {  1 }
sub ATTRIBUTE_NODE              () {  2 }
sub TEXT_NODE                   () {  3 }
sub CDATA_SECTION_NODE          () {  4 }
sub ENTITY_REFERENCE_NODE       () {  5 }
sub ENTITY_NODE                 () {  6 }
sub PROCESSING_INSTRUCTION_NODE () {  7 }
sub COMMENT_NODE                () {  8 }
sub DOCUMENT_NODE               () {  9 }
sub DOCUMENT_TYPE_NODE          () { 10 }
sub DOCUMENT_FRAGMENT_NODE      () { 11 }
sub NOTATION_NODE               () { 12 }
sub ANY_NODE                    () { 13 }


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
                        ELEMENT_NODE
                        ATTRIBUTE_NODE
                        TEXT_NODE
                        CDATA_SECTION_NODE
                        ENTITY_REFERENCE_NODE
                        ENTITY_NODE
                        PROCESSING_INSTRUCTION_NODE
                        COMMENT_NODE
                        DOCUMENT_NODE
                        DOCUMENT_TYPE_NODE
                        DOCUMENT_FRAGMENT_NODE
                        NOTATION_NODE
                        ANY_NODE
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
# CSS::SAC::Selector::Sibling->new($type,$node_type,$sel,$sibling_sel)
# creates a new sac SiblingSelector object
#---------------------------------------------------------------------#
sub new {
    my $class = ref($_[0])?ref(shift):shift;
    my $type        = shift;
    my $node_type   = shift;
    my $sel         = shift;
    my $sibling_sel = shift;

    # create a selector
    my $ssel = $class->SUPER::new($type);

    # add our fields
    $ssel->[_node_type_]        = $node_type || ANY_NODE;
    $ssel->[_selector_]         = $sel;
    $ssel->[_sibling_selector_] = $sibling_sel;

    return $ssel;
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Constructor #######################################################



### Accessors #########################################################
#                                                                     #
#                                                                     #

*CSS::SAC::Selector::Sibling::getNodeType = \&NodeType;
*CSS::SAC::Selector::Sibling::getSelector = \&Selector;
*CSS::SAC::Selector::Sibling::getSiblingSelector = \&SiblingSelector;

#---------------------------------------------------------------------#
# my $node_type = $ssel->NodeType()
# $ssel->NodeType($node_type)
# get/set the node type to which we apply
#---------------------------------------------------------------------#
sub NodeType {
    (@_==2) ? $_[0]->[_node_type_] = $_[1] :
              $_[0]->[_node_type_];
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $sel = $ssel->Selector()
# $ssel->Selector($sel)
# get/set the selector
#---------------------------------------------------------------------#
sub Selector {
    (@_==2) ? $_[0]->[_selector_] = $_[1] :
              $_[0]->[_selector_];
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $o_ssel = $ssel->SiblingSelector()
# $ssel->SiblingSelector($o_ssel)
# get/set the sibling selector
#---------------------------------------------------------------------#
sub SiblingSelector {
    (@_==2) ? $_[0]->[_sibling_selector_] = $_[1] :
              $_[0]->[_sibling_selector_];
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Accessors #########################################################



1;

=pod

=head1 NAME

CSS::SAC::Selector::Sibling - SAC SiblingSelector

=head1 SYNOPSIS

 see CSS::SAC::Selector

=head1 DESCRIPTION

This is a subclass of CSS::SAC::Selector, look there for more
documentation. This class adds the methods described below.

This subclass also defines the constants for the DOM nodes. It uses
the same constants as the DOM, and adds the ANY_NODE constant which
matches any node.

=head1 CONSTANTS

=over

=item * ELEMENT_NODE

=item * ATTRIBUTE_NODE

=item * TEXT_NODE

=item * CDATA_SECTION_NODE

=item * ENTITY_REFERENCE_NODE

=item * ENTITY_NODE

=item * PROCESSING_INSTRUCTION_NODE

=item * COMMENT_NODE

=item * DOCUMENT_NODE

=item * DOCUMENT_TYPE_NODE

=item * DOCUMENT_FRAGMENT_NODE

=item * NOTATION_NODE

=item * ANY_NODE

=back

=head1 METHODS

These also exist in spec style, simply prepend them with 'get'.

=over

=item * CSS::SAC::Selector::Sibling->new($type,$node_type,$sel,$sibling_sel)
=item * $ssel->new($type,$node_type,$sel,$sibling_sel)

Creates a new sibling selector.

=item * $ssel->NodeType([$node_type])

get/set the node type to which we apply

=item * $ssel->Selector([$sel])

get/set the selector's sub selector

=item * $ssel->SiblingSelector([$sib_sel])

get/set the selector's sibling selector

=back

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut
