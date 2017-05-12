
###
# CSS::SAC::ConditionFactory - the default ConditionFactory
# Robin Berjon <robin@knowscape.com>
# 24/02/2001
###

package CSS::SAC::ConditionFactory;
use strict;
use vars qw($VERSION);
$VERSION = $CSS::SAC::VERSION || '0.03';

use CSS::SAC::Condition             qw(:constants);
use CSS::SAC::Condition::Attribute  qw();
use CSS::SAC::Condition::Combinator qw();
use CSS::SAC::Condition::Content    qw();
use CSS::SAC::Condition::Lang       qw();
use CSS::SAC::Condition::Negative   qw();
use CSS::SAC::Condition::Positional qw();

#---------------------------------------------------------------------#
# build the fields for an array based object
#---------------------------------------------------------------------#
use Class::ArrayObjects define => { fields => [] };
#---------------------------------------------------------------------#


### Constructor #######################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# CSS::SAC::ConditionFactory->new
# creates a new sac condition factory
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
*CSS::SAC::ConditionFactory::createAndCondition = \&create_and_condition;
*CSS::SAC::ConditionFactory::createAttributeCondition = \&create_attribute_condition;
*CSS::SAC::ConditionFactory::createBeginHyphenAttributeCondition = \&create_begin_hyphen_attribute_condition;
*CSS::SAC::ConditionFactory::createClassCondition = \&create_class_condition;
*CSS::SAC::ConditionFactory::createContentCondition = \&create_content_condition;
*CSS::SAC::ConditionFactory::createIdCondition = \&create_id_condition;
*CSS::SAC::ConditionFactory::createLangCondition = \&create_lang_condition;
*CSS::SAC::ConditionFactory::createNegativeCondition = \&create_negative_condition;
*CSS::SAC::ConditionFactory::createOneOfAttributeCondition = \&create_one_of_attribute_condition;
*CSS::SAC::ConditionFactory::createOnlyChildCondition = \&create_only_child_condition;
*CSS::SAC::ConditionFactory::createOnlyTypeCondition = \&create_only_type_condition;
*CSS::SAC::ConditionFactory::createOrCondition = \&create_or_condition;
*CSS::SAC::ConditionFactory::createPositionalCondition = \&create_positional_condition;
*CSS::SAC::ConditionFactory::createPseudoClassCondition = \&create_pseudo_class_condition;


#---------------------------------------------------------------------#
# my $cond = $cf->create_and_condition($first,$second)
# creates a combinator condition of type and
#---------------------------------------------------------------------#
sub create_and_condition {
    my $cf = shift;
    my $first = shift;
    my $second = shift;

    return CSS::SAC::Condition::Combinator->new(
                                                AND_CONDITION,
                                                $first,
                                                $second,
                                               );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $cond = $cf->create_attribute_condition($lname,$ns,$specified,$value)
# creates an attr condition
#---------------------------------------------------------------------#
sub create_attribute_condition {
    my $cf = shift;
    my $lname = shift;
    my $ns = shift;
    my $specified = shift;
    my $value = shift;

    return CSS::SAC::Condition::Attribute->new(
                                                ATTRIBUTE_CONDITION,
                                                $lname,
                                                $ns,
                                                $specified,
                                                $value,
                                               );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $cond = $cf->create_begin_hyphen_attribute_condition($lname,$ns,$specified,$value)
# creates a attr condition of type bh
#---------------------------------------------------------------------#
sub create_begin_hyphen_attribute_condition {
    my $cf = shift;
    my $lname = shift;
    my $ns = shift;
    my $specified = shift;
    my $value = shift;

    return CSS::SAC::Condition::Attribute->new(
                                                BEGIN_HYPHEN_ATTRIBUTE_CONDITION,
                                                $lname,
                                                $ns,
                                                $specified,
                                                $value,
                                               );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $cond = $cf->create_class_condition($ns,$value)
# creates a attr condition of type class
#---------------------------------------------------------------------#
sub create_class_condition {
    my $cf = shift;
    my $ns = shift;
    my $value = shift;

    return CSS::SAC::Condition::Attribute->new(
                                                CLASS_CONDITION,
                                                undef,
                                                $ns,
                                                0,
                                                $value,
                                               );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $cond = $cf->create_content_condition($data)
# creates a content condition
#---------------------------------------------------------------------#
sub create_content_condition {
    my $cf = shift;
    my $data = shift;

    return CSS::SAC::Condition::Content->new(
                                             CONTENT_CONDITION,
                                             $data,
                                            );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $cond = $cf->create_id_condition($value)
# creates a attr condition of type id
#---------------------------------------------------------------------#
sub create_id_condition {
    my $cf = shift;
    my $value = shift;

    return CSS::SAC::Condition::Attribute->new(
                                                ID_CONDITION,
                                                undef,
                                                undef,
                                                0,
                                                $value,
                                               );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $cond = $cf->create_lang_condition($lang)
# creates a lang condition
#---------------------------------------------------------------------#
sub create_lang_condition {
    my $cf = shift;
    my $lang = shift;

    return CSS::SAC::Condition::Lang->new(
                                          LANG_CONDITION,
                                          $lang,
                                         );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $cond = $cf->create_negative_condition($cond)
# creates a negative condition
#---------------------------------------------------------------------#
sub create_negative_condition {
    my $cf = shift;
    my $cond = shift;

    return CSS::SAC::Condition::Negative->new(
                                              NEGATIVE_CONDITION,
                                              $cond,
                                             );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $cond = $cf->create_one_of_attribute_condition($lname,$ns,$specified,$value)
# creates a attr condition of type id
#---------------------------------------------------------------------#
sub create_one_of_attribute_condition {
    my $cf = shift;
    my $lname = shift;
    my $ns = shift;
    my $specified = shift;
    my $value = shift;

    return CSS::SAC::Condition::Attribute->new(
                                                ONE_OF_ATTRIBUTE_CONDITION,
                                                $lname,
                                                $ns,
                                                $specified,
                                                $value,
                                               );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $cond = $cf->create_only_child_condition()
# creates a only-child condition
#---------------------------------------------------------------------#
sub create_only_child_condition {
    my $cf = shift;
    return CSS::SAC::Condition->new(ONLY_CHILD_CONDITION);
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $cond = $cf->create_only_type_condition()
# creates a only-type condition
#---------------------------------------------------------------------#
sub create_only_type_condition {
    my $cf = shift;
    return CSS::SAC::Condition->new(ONLY_TYPE_CONDITION);
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $cond = $cf->create_or_condition($first,$second)
# creates a combinator condition of type or
#---------------------------------------------------------------------#
sub create_or_condition {
    my $cf = shift;
    my $first = shift;
    my $second = shift;

    return CSS::SAC::Condition::Combinator->new(
                                                OR_CONDITION,
                                                $first,
                                                $second,
                                               );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $cond = $cf->create_positional_condition($position,$type_node,$same_type)
# creates a positional condition
#---------------------------------------------------------------------#
sub create_positional_condition {
    my $cf = shift;
    my $position = shift;
    my $type_node = shift;
    my $same_type = shift;

    return CSS::SAC::Condition::Positional->new(
                                                POSITIONAL_CONDITION,
                                                $position,
                                                $type_node,
                                                $same_type,
                                               );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $cond = $cf->create_pseudo_class_condition($ns,$value)
# creates a attr condition of type pseudo class
#---------------------------------------------------------------------#
sub create_pseudo_class_condition {
    my $cf = shift;
    my $ns = shift;
    my $value = shift;

    return CSS::SAC::Condition::Attribute->new(
                                                PSEUDO_CLASS_CONDITION,
                                                undef,
                                                $ns,
                                                0,
                                                $value,
                                               );
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Factory Methods ###################################################



### EXPERIMENTAL Factory Methods ######################################
#                                                                     #
#                                                                     #


### IMPORTANT NOTE ####################################################
#                                                                     #
# These factory methods are considered experiemental. They will       #
# remain undocumented until further notice. CSS::SAC uses them when   #
# it meets the corresponding tokens, but they should not be relied on #
# for most uses unless you know what you are doing. These methods are #
# just as stable as the others, but given that I have implemented     #
# them on my own without consulting with the other SAC implementors   #
# (in fact, I tried to consult but they didn't appear to be           #
# interested at that moment in time) they are subject to change.      #
#                                                                     #
#######################################################################


#---------------------------------------------------------------------#
# my $cond = $cf->create_starts_with_attribute_condition($lname,$ns,$specified,$value)
# creates a attr condition of type sw
#---------------------------------------------------------------------#
sub create_starts_with_attribute_condition {
    my $cf = shift;
    my $lname = shift;
    my $ns = shift;
    my $specified = shift;
    my $value = shift;

    return CSS::SAC::Condition::Attribute->new(
                                                STARTS_WITH_ATTRIBUTE_CONDITION,
                                                $lname,
                                                $ns,
                                                $specified,
                                                $value,
                                               );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $cond = $cf->create_ends_with_attribute_condition($lname,$ns,$specified,$value)
# creates a attr condition of type ew
#---------------------------------------------------------------------#
sub create_ends_with_attribute_condition {
    my $cf = shift;
    my $lname = shift;
    my $ns = shift;
    my $specified = shift;
    my $value = shift;

    return CSS::SAC::Condition::Attribute->new(
                                                ENDS_WITH_ATTRIBUTE_CONDITION,
                                                $lname,
                                                $ns,
                                                $specified,
                                                $value,
                                               );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $cond = $cf->create_contains_attribute_condition($lname,$ns,$specified,$value)
# creates a attr condition of type sw
#---------------------------------------------------------------------#
sub create_contains_attribute_condition {
    my $cf = shift;
    my $lname = shift;
    my $ns = shift;
    my $specified = shift;
    my $value = shift;

    return CSS::SAC::Condition::Attribute->new(
                                                CONTAINS_ATTRIBUTE_CONDITION,
                                                $lname,
                                                $ns,
                                                $specified,
                                                $value,
                                               );
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $cond = $cf->create_is_root_condition()
# creates a root condition
#---------------------------------------------------------------------#
sub create_is_root_condition {
    my $cf = shift;
    return CSS::SAC::Condition->new(IS_ROOT_CONDITION);
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $cond = $cf->create_is_empty_condition()
# creates a empty condition
#---------------------------------------------------------------------#
sub create_is_empty_condition {
    my $cf = shift;
    return CSS::SAC::Condition->new(IS_EMPTY_CONDITION);
}
#---------------------------------------------------------------------#




#                                                                     #
#                                                                     #
### EXPERIMENTAL Factory Methods ######################################


1;

=pod

=head1 NAME

CSS::SAC::ConditionFactory - the default ConditionFactory

=head1 SYNOPSIS

  my $cf = CSS::SAC::ConditionFactory->new;
  my $cond1 = $cf->create_foo_condition;
  my $cond2 = $cf->create_bar_condition;

=head1 DESCRIPTION

This is the default ConditionFactory for CSS::SAC. It creates
conditions of all types defined in SAC. You may wish to subclass or
replace the default ConditionFactory in order to get your own
condition objects.

I plan on adding more flexibility to this factory so that one could
tell it the classes to use for various conditions, that would avoid
enforcing subclassing/recoding for people that only want to replace
a family of factory methods.

I know that some of the method names are quite lengthy, but given the
great number of possible conditions it helps to have descriptive
names.

=head1 METHODS

These define the interface that must be adhered to by
ConditionFactories. The Java names (given in parens) work too, though
the Perl ones are recommended.

=over 4

=item * CSS::SAC::ConditionFactory->new or $cf->new

Creates a new condition factory object.

=item * $cf->create_and_condition($first,$second)  (createAndCondition)

creates a combinator condition of type and

=item * $cf->create_attribute_condition($lname,$ns,$specified,$value)  (createAttributeCondition)

creates an attr condition

=item * $cf->create_begin_hyphen_attribute_condition($lname,$ns,$specified,$value)  (createBeginHyphenAttributeCondition)

creates a attr condition of type bh

=item * $cf->create_class_condition($ns,$value)  (createClassCondition)

creates a attr condition of type class

=item * $cf->create_content_condition($data)  (createContentCondition)

creates a content condition

=item * $cf->create_id_condition($value)  (createIdCondition)

creates a attr condition of type id

=item * $cf->create_lang_condition($lang)  (createLangCondition)

creates a lang condition

=item * $cf->create_negative_condition($cond)  (createNegativeCondition)

creates a negative condition

=item * $cf->create_one_of_attribute_condition($lname,$ns,$specified,$value)  (createOneOfAttributeCondition)

creates a attr condition of type id

=item * $cf->create_only_child_condition()  (createOnlyChildCondition)

creates a only-child condition

=item * $cf->create_only_type_condition()  (createOnlyTypeCondition)

creates a only-type condition

=item * $cf->create_or_condition($first,$second)  (createOrCondition)

creates a combinator condition of type or

=item * $cf->create_positional_condition($position,$type_node,$same_type)  (createPositionalCondition)

creates a positional condition

=item * $cf->create_pseudo_class_condition($ns,$value)  (createPseudoClassCondition)

creates a attr condition of type pseudo class

=back

=head1 EXPERIMENTAL

There's some experimental stuff in here to provide for some new CSS
constructs. It is and will remain undocumented until there is
consensus on the handling of these new tokens. If you badly need to
use one of the new CSS3 conditions that isn't documented, look at the
source for features tagged EXPERIMENTAL.

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut


