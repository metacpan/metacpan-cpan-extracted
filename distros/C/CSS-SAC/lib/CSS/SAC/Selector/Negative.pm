
###
# CSS::SAC::Selector::Negative - SAC NegativeSelector
# Robin Berjon <robin@knowscape.com>
# 24/02/2001
###

package CSS::SAC::Selector::Negative;
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
                                                _sel_
                                              )],
                                  };
#---------------------------------------------------------------------#




### Constructor #######################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# CSS::SAC::Selector::Negative->new($type,$sel)
# creates a new sac NegativeSelector object
#---------------------------------------------------------------------#
sub new {
    my $class = ref($_[0])?ref(shift):shift;
    my $type = shift;
    my $sel  = shift;

    # create a selector
    my $nsel = $class->SUPER::new($type);

    # add our fields
    $nsel->[_sel_] = $sel;

    return $nsel;
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Constructor #######################################################



### Accessors #########################################################
#                                                                     #
#                                                                     #

*CSS::SAC::Selector::Negative::getSimpleSelector = \&SimpleSelector;

#---------------------------------------------------------------------#
# my $sel = $nsel->SimpleSelector()
# $nsel->SimpleSelector($sel)
# get/set the selector's simple selector
#---------------------------------------------------------------------#
sub SimpleSelector {
    (@_==2) ? $_[0]->[_sel_] = $_[1] :
              $_[0]->[_sel_];
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Accessors #########################################################



1;

=pod

=head1 NAME

CSS::SAC::Selector::Negative - SAC NegativeSelector

=head1 SYNOPSIS

 see CSS::SAC::Selector

=head1 DESCRIPTION

This is a subclass of CSS::SAC::Selector::Simple, look there for more
documentation. This class adds the following methods (which also exist
in spec style, simply prepend them with 'get'):

=head1 METHODS

=over 4

=item * CSS::SAC::Selector::Negative->new($type,$sel)

=item * $nsel->new($type,$sel)

Creates a new negative selector.

=item * $nsel->SimpleSelector([$sel])

get/set the selector's simple selector

=back

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut


