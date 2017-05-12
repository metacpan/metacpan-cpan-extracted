
###
# CSS::SAC::Selector::Simple - SAC SimpleSelector
# Robin Berjon <robin@knowscape.com>
# 24/02/2001
###

package CSS::SAC::Selector::Simple;
use strict;
use vars qw($VERSION);
$VERSION = $CSS::SAC::VERSION || '0.03';

use base qw(CSS::SAC::Selector);


#---------------------------------------------------------------------#
# build the fields for an array based object
#---------------------------------------------------------------------#
use Class::ArrayObjects extend => {
                                   class => 'CSS::SAC::Selector',
                                   with  => [],
                                  };
#---------------------------------------------------------------------#



### Constructor #######################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# CSS::SAC::Selector::Simple->new($type)
# creates a new sac SimpleSelector object
#---------------------------------------------------------------------#
sub new {
    my $class = ref($_[0])?ref(shift):shift;
    my $type        = shift;

    # create a selector
    my $ssel = $class->SUPER::new($type);

    return $ssel;
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Constructor #######################################################


1;

=pod

=head1 NAME

CSS::SAC::Selector::Simple - SAC SimpleSelector

=head1 SYNOPSIS

 see CSS::SAC::Selector

=head1 DESCRIPTION

This is a subclass of CSS::SAC::Selector, look there for more
documentation. This class adds nothing, it's merely different.

This subclass adds nothing per se, it is only there to enforce
some constraints as other selector classes have fields that may
only contain a SimpleSelector

=head1 METHODS

=over 4

=item * CSS::SAC::Selector::Simple->new($type)

=item * $ssel->new($type)

Creates a new simple selector.

=back

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut
