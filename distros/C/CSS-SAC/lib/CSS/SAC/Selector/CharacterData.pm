
###
# CSS::SAC::Selector::CharacterData - SAC CharacterDataSelector
# Robin Berjon <robin@knowscape.com>
# 24/02/2001
###

package CSS::SAC::Selector::CharacterData;
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
                                                _data_
                                              )],
                                  };
#---------------------------------------------------------------------#




### Constructor #######################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# CSS::SAC::Selector::CharacterData->new($type,$data)
# creates a new sac CharacterDataSelector object
#---------------------------------------------------------------------#
sub new {
    my $class = ref($_[0])?ref(shift):shift;
    my $type = shift; # should be one of the cdata selectors
    my $data = shift;

    # create a selector
    my $csel = $class->SUPER::new($type);

    # add our fields
    $csel->[_data_] = $data if defined $data;

    return $csel;
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Constructor #######################################################



### Accessors #########################################################
#                                                                     #
#                                                                     #

*CSS::SAC::Selector::CharacterData::getData = \&Data;

#---------------------------------------------------------------------#
# my $data = $csel->Data()
# $csel->Data($data)
# get/set the selector's cdata
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

CSS::SAC::Selector::CharacterData - SAC CharacterDataSelector

=head1 SYNOPSIS

 see CSS::SAC::Selector

=head1 DESCRIPTION

This is a subclass of CSS::SAC::Selector::Simple, look there for more
documentation. This class adds the following methods (which also exist
in spec style, simply prepend them with 'get'):

=head1 METHODS

=over

=item * CSS::SAC::Selector::CharacterData->new($type,$data)
=item * $sel->new($type,$data)

Creates a new cdata selector.

=item * $csel->Data([$data])

get/set the selector's data

=back

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut


