
###
# CSS::SAC::Selector::Conditional - SAC ConditionalSelector
# Robin Berjon <robin@knowscape.com>
# 24/02/2001
###

package CSS::SAC::Selector::Conditional;
use strict;
use vars qw($VERSION);
$VERSION = $CSS::SAC::VERSION || '0.03';

use base qw(CSS::SAC::Selector::Simple);


#---------------------------------------------------------------------#
# build the fields for an array based object
#---------------------------------------------------------------------#
use Class::ArrayObjects extend => {
                                   class => 'CSS::SAC::Selector::Simple',
                                   with  => [qw(
                                                _selector_
                                                _condition_
                                              )],
                                  };
#---------------------------------------------------------------------#




### Constructor #######################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# CSS::SAC::Selector::Conditional->new($type,$selector,$condition)
# creates a new sac ConditionalSelector object
#---------------------------------------------------------------------#
sub new {
    my $class = ref($_[0])?ref(shift):shift;
    my $type      = shift;
    my $selector  = shift;
    my $condition = shift;

    # create a selector
    my $csel = $class->SUPER::new($type);

    # add our fields
    $csel->[_condition_] = $condition;
    $csel->[_selector_]  = $selector;

    return $csel;
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Constructor #######################################################



### Accessors #########################################################
#                                                                     #
#                                                                     #

*CSS::SAC::Selector::Conditional::getCondition = \&Condition;
*CSS::SAC::Selector::Conditional::getSimpleSelector = \&SimpleSelector;

#---------------------------------------------------------------------#
# my $cond = $csel->Condition()
# $csel->Condition($cond)
# get/set the selector's condition
#---------------------------------------------------------------------#
sub Condition {
    (@_==2) ? $_[0]->[_condition_] = $_[1] :
              $_[0]->[_condition_];
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $cond = $csel->SimpleSelector()
# $csel->SimpleSelector($cond)
# get/set the selector's simple selector
#---------------------------------------------------------------------#
sub SimpleSelector {
    (@_==2) ? $_[0]->[_selector_] = $_[1] :
              $_[0]->[_selector_];
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Accessors #########################################################



1;

=pod

=head1 NAME

CSS::SAC::Selector::Conditional - SAC ConditionalSelector

=head1 SYNOPSIS

 see CSS::SAC::Selector

=head1 DESCRIPTION

This is a subclass of CSS::SAC::Selector::Simple, look there for more
documentation. This class adds the following methods (which also exist
in spec style, simply prepend them with 'get'):

=head1 METHODS

=over

=item * CSS::SAC::Selector::Conditional->new($type,$selector,$condition)
=item * $sel->new($type,$selector,$condition)

Creates a new conditional selector.

=item * $csel->Condition([$cond])

get/set the selector's condition

=item * $csel->SimpleSelector([$cond])

get/set the selector's simple selector

=back

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut


