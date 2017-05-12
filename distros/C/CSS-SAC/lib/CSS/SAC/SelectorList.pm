
###
# CSS::SAC::SelectorList - SAC SelectorLists
# Robin Berjon <robin@knowscape.com>
# 24/02/2001 - prototype mark I of the new model
###

package CSS::SAC::SelectorList;
use strict;
use vars qw($VERSION);

$VERSION = $CSS::SAC::VERSION || '0.03';


### Constructor #######################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# CSS::SAC::SelectorList->new(\@list)
# creates a new list
#---------------------------------------------------------------------#
sub new {
    my $class = shift;
    my $list = shift || [];

    return bless $list, $class;
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Constructor #######################################################



### Accessors #########################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# $sl->Length
# returns the length of the list
#---------------------------------------------------------------------#
sub Length {
    return scalar @$_[0];
}
#---------------------------------------------------------------------#
*CSS::SAC::SelectorList::getLength = \&Length;

#---------------------------------------------------------------------#
# $sl->Item($pos,[$sel])
# get/set the item at that position
#---------------------------------------------------------------------#
sub Item {
    (@_ == 2) ? $_[0]->[$_[1]] = $_[2] :
                $_[0]->[$_[1]];
}
#---------------------------------------------------------------------#
*CSS::SAC::SelectorList::item = \&Item;


#                                                                     #
#                                                                     #
### Accessors #########################################################


=pod

=head1 NAME

CSS::SAC::SelectorList - SAC SelectorLists

=head1 SYNOPSIS

 fill this in later...

=head1 DESCRIPTION

SAC SelectorLists are simple arrayrefs with a few methods on top. I
recommend that you use them the Perl way because they are really
nothing more than arrays. However there was demand for the methods
that exist in the spec, so I added this interface.

=head1 METHODS

=over

=item * CSS::SAC::SelectorList->new(\@selectors) or $sl->new(\@selectors)

Creates a new sl, optionally with those selectors.

=item * $sl->Length

Returns the length of the array

=item * $sel->Item($index,[$selector])

get/set a selector at that (0-based) index in the array

=back

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut
