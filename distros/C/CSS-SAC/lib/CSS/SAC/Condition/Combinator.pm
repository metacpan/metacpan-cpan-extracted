
###
# CSS::SAC::Condition::Combinator - SAC CombinatorConditions
# Robin Berjon <robin@knowscape.com>
# 24/02/2001
###

package CSS::SAC::Condition::Combinator;
use strict;
use vars qw($VERSION);
$VERSION = $CSS::SAC::VERSION || '0.03';

use base qw(CSS::SAC::Condition);


#---------------------------------------------------------------------#
# build the fields for an array based object
#---------------------------------------------------------------------#
use Class::ArrayObjects extend => {
                                   class => 'CSS::SAC::Condition',
                                   with  => [qw(
                                                _condition_1_
                                                _condition_2_
                                              )],
                                  };
#---------------------------------------------------------------------#




### Constructor #######################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# CSS::SAC::Condition::Combinator->new($type,$first_cond,$second_cond)
# creates a new sac CombinatorCondition object
#---------------------------------------------------------------------#
sub new {
    my $class = ref($_[0])?ref(shift):shift;
    my $type        = shift; # should be one of the combinator conditions
    my $condition_1 = shift; # any default ?
    my $condition_2 = shift;

    # create a condition
    my $ccond = $class->SUPER::new($type);

    # add our fields
    $ccond->[_condition_1_] = $condition_1 if $condition_1;
    $ccond->[_condition_2_] = $condition_2 if $condition_2;

    return $ccond;
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Constructor #######################################################



### Accessors #########################################################
#                                                                     #
#                                                                     #

# aliases
*CSS::SAC::Condition::Combinator::getFirstCondition = \&FirstCondition;
*CSS::SAC::Condition::Combinator::getSecondCondition = \&SecondCondition;


#---------------------------------------------------------------------#
# my $cond1 = $ccond->FirstCondition()
# $ccond->FirstCondition($cond1)
# get/set the first condition
#---------------------------------------------------------------------#
sub FirstCondition {
    (@_==2) ? $_[0]->[_condition_1_] = $_[1] :
              $_[0]->[_condition_1_];
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $cond2 = $ccond->SecondCondition()
# $ccond->SecondCondition($cond2)
# get/set the second condition
#---------------------------------------------------------------------#
sub SecondCondition {
    (@_==2) ? $_[0]->[_condition_2_] = $_[1] :
              $_[0]->[_condition_2_];
}
#---------------------------------------------------------------------#



#                                                                     #
#                                                                     #
### Accessors #########################################################



1;

=pod

=head1 NAME

CSS::SAC::Condition::Combinator - SAC CombinatorConditions

=head1 SYNOPSIS

 see CSS::SAC::Condition

=head1 DESCRIPTION

This is a subclass of CSS::SAC::Condition, look there for more
documentation. This class adds the following methods  (the spec
equivalents are available as well, just prepend 'get'):

=head1 METHODS

=over 4

=item * CSS::SAC::Condition::Combinator->new($type,$cond1,$cond2)

=item * $cond->new($type,$cond1,$cond2)

Creates a new combinator condition.

=item * $ccond->FirstCondition([$cond])
=item * $ccond->SecondCondition([$cond])

get/set the conditions that compose the combinator

=back

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut


