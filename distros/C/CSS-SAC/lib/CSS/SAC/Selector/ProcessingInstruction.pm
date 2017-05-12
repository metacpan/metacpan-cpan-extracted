
###
# CSS::SAC::Selector::ProcessingInstruction - SAC ProcessingInstructionSelector
# Robin Berjon <robin@knowscape.com>
# 24/02/2001
###

package CSS::SAC::Selector::ProcessingInstruction;
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
                                                _target_
                                                _data_
                                              )],
                                  };
#---------------------------------------------------------------------#




### Constructor #######################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# CSS::SAC::Selector::ProcessingInstruction->new($type,$target,$data)
# creates a new sac ProcessingInstructionSelector object
#---------------------------------------------------------------------#
sub new {
    my $class = ref($_[0])?ref(shift):shift;
    my $type   = shift;
    my $target = shift;
    my $data   = shift;

    # create a selector
    my $psel = $class->SUPER::new($type);

    # add our fields
    $psel->[_target_] = $target;
    $psel->[_data_]   = $data if defined $data;

    return $psel;
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Constructor #######################################################



### Accessors #########################################################
#                                                                     #
#                                                                     #


*CSS::SAC::Selector::ProcessingInstruction::getTarget = \&Target;
*CSS::SAC::Selector::ProcessingInstruction::getData = \&Data;

#---------------------------------------------------------------------#
# my $target = $psel->Target()
# $psel->Target($target)
# get/set the selector's target
#---------------------------------------------------------------------#
sub Target {
    (@_==2) ? $_[0]->[_target_] = $_[1] :
              $_[0]->[_target_];
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $data = $psel->Data()
# $psel->Data($data)
# get/set the selector's data
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

CSS::SAC::Selector::ProcessingInstruction - SAC ProcessingInstructionSelector

=head1 SYNOPSIS

 see CSS::SAC::Selector

=head1 DESCRIPTION

This is a subclass of CSS::SAC::Selector::Simple, look there for more
documentation. This class adds the following methods (which also exist
in spec style, simply prepend them with 'get'):

=head1 METHODS

=over

=item * CSS::SAC::Selector::ProcessingInstruction->new($type,$target,$data)
=item * $psel->new($type,$target,$data)

Creates a new pi selector.

=item * $psel->Target([$target])

get/set the selector's target

=item * $psel->Data([$data])

get/set the selector's data

=back

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut


