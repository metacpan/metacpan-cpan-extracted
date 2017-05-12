
###
# CSS::SAC::Condition::Negative - SAC NegativeConditions
# Robin Berjon <robin@knowscape.com>
# 24/02/2001
###

package CSS::SAC::Condition::Negative;
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
                                                _cond_
                                              )],
                                  };
#---------------------------------------------------------------------#




### Constructor #######################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# CSS::SAC::Condition::Negative->new($type,$cond)
# creates a new sac NegativeCondition object
#---------------------------------------------------------------------#
sub new {
    my $class = ref($_[0])?ref(shift):shift;
    my $type = shift; # should be one of the content conditions
    my $cond = shift;

    # create a condition
    my $ncond = $class->SUPER::new($type);

    # add our fields
    $ncond->[_cond_] = $cond;

    return $ncond;
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Constructor #######################################################



### Accessors #########################################################
#                                                                     #
#                                                                     #

# aliases
*CSS::SAC::Condition::Negative::getCondition = \&Condition;


#---------------------------------------------------------------------#
# my $cond = $ncond->Condition()
# $ncond->Condition($cond)
# get/set the condition's sub condition
#---------------------------------------------------------------------#
sub Condition {
    (@_==2) ? $_[0]->[_cond_] = $_[1] :
              $_[0]->[_cond_];
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Accessors #########################################################



1;

=pod

=head1 NAME

CSS::SAC::Condition::Negative - SAC NegativeConditions

=head1 SYNOPSIS

 see CSS::SAC::Condition

=head1 DESCRIPTION

This is a subclass of CSS::SAC::Condition, look there for more
documentation. This class adds the following methods (the spec
equivalents are available as well, just prepend 'get'):

=head1 METHODS

=over 4

=item * CSS::SAC::Condition::Negative->new($type,$cond)

=item * $cond->new($type,$cond)

Creates a new negative condition.

=item * $ccond->Condition([$cond])

get/set the condition's sub condition

=back

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut


