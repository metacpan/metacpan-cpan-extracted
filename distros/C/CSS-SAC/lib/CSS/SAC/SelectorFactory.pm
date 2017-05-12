
###
# CSS::SAC::SelectorFactory - the default SelectorFactory
# Robin Berjon <robin@knowscape.com>
# 24/02/2001
###

package CSS::SAC::SelectorFactory;
use strict;
use vars qw($VERSION);
$VERSION = $CSS::SAC::VERSION || '0.03';

use CSS::SAC::Selector                          qw(:constants);
use CSS::SAC::Selector::Descendant              qw();
use CSS::SAC::Selector::Sibling                 qw();
use CSS::SAC::Selector::Simple                  qw();
use CSS::SAC::Selector::CharacterData           qw();
use CSS::SAC::Selector::Conditional             qw();
use CSS::SAC::Selector::Element                 qw();
use CSS::SAC::Selector::Negative                qw();
use CSS::SAC::Selector::ProcessingInstruction   qw();

#---------------------------------------------------------------------#
# build the fields for an array based object
#---------------------------------------------------------------------#
use Class::ArrayObjects define => { fields => [] };
#---------------------------------------------------------------------#



### Constructor #######################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# CSS::SAC::SelectorFactory->new
# creates a new sac selector factory
#---------------------------------------------------------------------#
sub new {
    my $class = ref($_[0])?ref(shift):shift;
    return bless [], $class;
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Constructor #######################################################



### Factory Methods ###################################################
#                                                                     #
#                                                                     #


# defined aliases
*CSS::SAC::SelectorFactory::createAnyNodeSelector = \&create_any_node_selector;
*CSS::SAC::SelectorFactory::createCdataSectionSelector = \&create_cdata_section_selector;
*CSS::SAC::SelectorFactory::createChildSelector = \&create_child_selector;
*CSS::SAC::SelectorFactory::createCommentSelector = \&create_comment_selector;
*CSS::SAC::SelectorFactory::createConditionalSelector = \&create_conditional_selector;
*CSS::SAC::SelectorFactory::createDescendantSelector = \&create_descendant_selector;
*CSS::SAC::SelectorFactory::createDirectAdjacentSelector = \&create_direct_adjacent_selector;
*CSS::SAC::SelectorFactory::createElementSelector = \&create_element_selector;
*CSS::SAC::SelectorFactory::createNegativeSelector = \&create_negative_selector;
*CSS::SAC::SelectorFactory::createProcessingInstructionSelector = \&create_processing_instruction_selector;
*CSS::SAC::SelectorFactory::createPseudoElementSelector = \&create_pseudo_element_selector;
*CSS::SAC::SelectorFactory::createRootNodeSelector = \&create_root_node_selector;
*CSS::SAC::SelectorFactory::createTextNodeSelector = \&create_text_node_selector;


#---------------------------------------------------------------------#
# my $sel = $sf->create_any_node_selector
# creates a any-node selector
#---------------------------------------------------------------------#
sub create_any_node_selector {
    my $cf = shift;
    return CSS::SAC::Selector::Simple->new(ANY_NODE_SELECTOR);
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $sel = $sf->create_cdata_section_selector($data)
# creates a cdata selector
#---------------------------------------------------------------------#
sub create_cdata_section_selector {
    my $cf = shift;
    my $data = shift;

    return CSS::SAC::Selector::CharacterData->new(
                                                  CDATA_SECTION_NODE_SELECTOR,
                                                  $data
                                                 );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $sel = $sf->create_child_selector($parent_sel,$child_sel)
# creates a child selector
#---------------------------------------------------------------------#
sub create_child_selector {
    my $cf = shift;
    my $parent_sel = shift;
    my $child_sel = shift;

    return CSS::SAC::Selector::Descendant->new(
                                               CHILD_SELECTOR,
                                               $parent_sel,
                                               $child_sel
                                              );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $sel = $sf->create_comment_selector($data)
# creates a comment selector
#---------------------------------------------------------------------#
sub create_comment_selector {
    my $cf = shift;
    my $data = shift;

    return CSS::SAC::Selector::CharacterData->new(
                                                  COMMENT_NODE_SELECTOR,
                                                  $data
                                                 );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $sel = $sf->create_conditional_selector($sel,$cond)
# creates a conditional selector
#---------------------------------------------------------------------#
sub create_conditional_selector {
    my $cf = shift;
    my $sel = shift;
    my $cond = shift;

    return CSS::SAC::Selector::Conditional->new(
                                               CONDITIONAL_SELECTOR,
                                               $sel,
                                               $cond
                                              );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $sel = $sf->create_descendant_selector($parent_sel,$desc_sel)
# creates a descendant selector
#---------------------------------------------------------------------#
sub create_descendant_selector {
    my $cf = shift;
    my $parent_sel = shift;
    my $desc_sel = shift;

    return CSS::SAC::Selector::Descendant->new(
                                               DESCENDANT_SELECTOR,
                                               $parent_sel,
                                               $desc_sel
                                              );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $sel = $sf->create_direct_adjacent_selector($node_type,$child,$adjacent)
# creates a direct adjacent selector
#---------------------------------------------------------------------#
sub create_direct_adjacent_selector {
    my $cf = shift;
    my $node_type = shift;
    my $child = shift;
    my $adjacent = shift;

    return CSS::SAC::Selector::Sibling->new(
                                            DIRECT_ADJACENT_SELECTOR,
                                            $node_type,
                                            $child,
                                            $adjacent
                                           );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $sel = $sf->create_element_selector($ns,$lname)
# creates a element selector
#---------------------------------------------------------------------#
sub create_element_selector {
    my $cf = shift;
    my $ns = shift;
    my $lname = shift;

    return CSS::SAC::Selector::Element->new(
                                            ELEMENT_NODE_SELECTOR,
                                            $ns,
                                            $lname
                                           );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $sel = $sf->create_negative_selector($sel)
# creates a negative selector
#---------------------------------------------------------------------#
sub create_negative_selector {
    my $cf = shift;
    my $sel = shift;

    return CSS::SAC::Selector::Negative->new(
                                              NEGATIVE_SELECTOR,
                                              $sel
                                            );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $sel = $sf->create_processing_instruction_selector($target,$data)
# creates a pi selector
#---------------------------------------------------------------------#
sub create_processing_instruction_selector {
    my $cf = shift;
    my $target = shift;
    my $data = shift;

    return CSS::SAC::Selector::ProcessingInstruction->new(
                                                          PROCESSING_INSTRUCTION_NODE_SELECTOR,
                                                          $target,
                                                          $data
                                                         );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $sel = $sf->create_pseudo_element_selector($ns,$lname)
# creates a pseudo-e selector
#---------------------------------------------------------------------#
sub create_pseudo_element_selector {
    my $cf = shift;
    my $ns = shift;
    my $lname = shift;

    return CSS::SAC::Selector::Element->new(
                                            PSEUDO_ELEMENT_SELECTOR,
                                            $ns,
                                            $lname
                                           );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $sel = $sf->create_root_node_selector
# creates a root selector
#---------------------------------------------------------------------#
sub create_root_node_selector {
    my $cf = shift;
    return CSS::SAC::Selector::Simple->new(ROOT_NODE_SELECTOR);
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $sel = $sf->create_text_node_selector($data)
# creates a text selector
#---------------------------------------------------------------------#
sub create_text_node_selector {
    my $cf = shift;
    my $data = shift;

    return CSS::SAC::Selector::CharacterData->new(
                                                  TEXT_NODE_SELECTOR,
                                                  $data
                                                 );
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Factory Methods ###################################################




### EXPERIMENTAL Factory Methods ######################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# my $sel = $sf->create_indirect_adjacent_selector($node_type,$child,$adjacent)
# creates an indirect adjacent selector
#---------------------------------------------------------------------#
sub create_indirect_adjacent_selector {
    my $cf = shift;
    my $node_type = shift;
    my $child = shift;
    my $adjacent = shift;

    return CSS::SAC::Selector::Sibling->new(
                                            INDIRECT_ADJACENT_SELECTOR,
                                            $node_type,
                                            $child,
                                            $adjacent
                                           );
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### EXPERIMENTAL Factory Methods ######################################

1;

=pod

=head1 NAME

CSS::SAC::SelectorFactory - the default SelectorFactory

=head1 SYNOPSIS

 fill this in later...

=head1 DESCRIPTION

This is the default SelectorFactory for CSS::SAC. It creates
selectors of all types defined in SAC. You may wish to subclass or
replace the default SelectorFactory in order to get your own
selector objects.

I plan on adding more flexibility to this factory so that one could
tell it the classes to use for various selectors, that would avoid
enforcing subclassing/recoding for people that only want to replace
a family of factory methods.

I know that some of the method names are quite lengthy, but given the
great number of possible selectors it helps to have descriptive
names.

=head1 METHODS

All the C<create*> methods have a spec-style equivalent. Just remove
the _ and capitalize the next letter.

=over 4

=item * CSS::SAC::SelectorFactory->new or $cf->new

Creates a new condition factory object.

=item * $sf->create_any_node_selector

creates a any-node selector

=item * $sf->create_cdata_section_selector($data)

creates a cdata selector

=item * $sf->create_child_selector($parent_sel,$child_sel)

creates a child selector

=item * $sf->create_comment_selector($data)

creates a comment selector

=item * $sf->create_conditional_selector($sel,$cond)

creates a conditional selector

=item * $sf->create_descendant_selector($parent_sel,$desc_sel)

creates a descendant selector

=item * $sf->create_direct_adjacent_selector($node_type,$child,$adjacent)

creates a direct adjacent selector

=item * $sf->create_element_selector($ns,$lname)

creates a element selector

=item * $sf->create_negative_selector($sel)

creates a negative selector

=item * $sf->create_processing_instruction_selector($target,$data)

creates a pi selector

=item * $sf->create_pseudo_element_selector($ns,$lname)

creates a pseudo-e selector

=item * $sf->create_root_node_selector

creates a root selector

=item * $sf->create_text_node_selector($data)

creates a text selector

=back

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut


