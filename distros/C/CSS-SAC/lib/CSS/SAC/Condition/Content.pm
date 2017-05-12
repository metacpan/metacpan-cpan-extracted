
###
# CSS::SAC::Condition::Content - SAC ContentConditions
# Robin Berjon <robin@knowscape.com>
# 24/02/2001
###

package CSS::SAC::Condition::Content;
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
                                                _data_
                                              )],
                                  };
#---------------------------------------------------------------------#




### Constructor #######################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# CSS::SAC::Condition::Content->new($type,$data)
# creates a new sac ContentCondition object
#---------------------------------------------------------------------#
sub new {
    my $class = ref($_[0])?ref(shift):shift;
    my $type = shift; # should be one of the content conditions
    my $data = shift;

    # create a condition
    my $ccond = $class->SUPER::new($type);

    # add our fields
    $ccond->[_data_] = $data if defined $data;

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
*CSS::SAC::Condition::Content::getData = \&Data;

#---------------------------------------------------------------------#
# my $data = $ccond->Data()
# $ccond->Data($data)
# get/set the condition's data
#---------------------------------------------------------------------#
sub Data {
    (@_==2) ? $_[0]->[_data_] = $_[1] :
              $_[0]->[_data_];
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Accessors #########################################################



1;

=pod

=head1 NAME

CSS::SAC::Condition::Content - SAC ContentConditions

=head1 SYNOPSIS

 see CSS::SAC::Condition

=head1 DESCRIPTION

This is a subclass of CSS::SAC::Condition, look there for more
documentation. This class adds the following methods (the spec
equivalents are available as well, just prepend 'get'):

=head1 METHODS

=over 4

=item * CSS::SAC::Condition::Content->new($type,$data)

=item * $cond->new($type,$data)

Creates a new content condition.

=item * $ccond->Data([$data])

get/set the condition's data

=back

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut


