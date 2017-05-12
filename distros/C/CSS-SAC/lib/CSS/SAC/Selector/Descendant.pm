
###
# CSS::SAC::Selector::Descendant - SAC DescendantSelector
# Robin Berjon <robin@knowscape.com>
# 24/02/2001
###

package CSS::SAC::Selector::Descendant;
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
                                                _ancestor_
                                                _simple_
                                              )],
                                  };
#---------------------------------------------------------------------#




### Constructor #######################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# CSS::SAC::Selector::Descendant->new($type,$ancestor_sel,$simple_sel)
# creates a new sac DescendantSelector object
#---------------------------------------------------------------------#
sub new {
    my $class = ref($_[0])?ref(shift):shift;
    my $type         = shift;
    my $ancestor_sel = shift;
    my $simple_sel   = shift;

    # create a selector
    my $dsel = $class->SUPER::new($type);

    # add our fields
    $dsel->[_ancestor_] = $ancestor_sel;
    $dsel->[_simple_]   = $simple_sel;

    return $dsel;
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Constructor #######################################################



### Accessors #########################################################
#                                                                     #
#                                                                     #

*CSS::SAC::Selector::Descendant::getAncestorSelector = \&AncestorSelector;
*CSS::SAC::Selector::Descendant::getSimpleSelector = \&SimpleSelector;

#---------------------------------------------------------------------#
# my $ancestor_sel = $dsel->AncestorSelector()
# $dsel->AncestorSelector($ancestor_sel)
# get/set the selector's ancestor selector
#---------------------------------------------------------------------#
sub AncestorSelector {
    (@_==2) ? $_[0]->[_ancestor_] = $_[1] :
              $_[0]->[_ancestor_];
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $simple_sel = $dsel->SimpleSelector()
# $dsel->SimpleSelector($simple_sel)
# get/set the selector's simple selector
#---------------------------------------------------------------------#
sub SimpleSelector {
    (@_==2) ? $_[0]->[_simple_] = $_[1] :
              $_[0]->[_simple_];
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Accessors #########################################################



1;

=pod

=head1 NAME

CSS::SAC::Selector::Descendant - SAC DescendantSelector

=head1 SYNOPSIS

 see CSS::SAC::Selector

=head1 DESCRIPTION

This is a subclass of CSS::SAC::Selector, look there for more
documentation. This class adds the following methods (which also exist
in spec style, simply prepend them with 'get'):

=head1 METHODS

=over

=item * CSS::SAC::Selector::Descendant->new($type,$ancestor_sel,$simple_sel)
=item * $dsel->new($type,$ancestor_sel,$simple_sel)

Creates a new descendant selector.

=item * $dsel->AncestorSelector([$ancestor_sel])

get/set the selector's ancestor selector

=item * $dsel->SimpleSelector([$simple_sel])

get/set the selector's simple selector

=back

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut


