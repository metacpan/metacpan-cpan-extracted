
###
# CSS::SAC::Selector::Element - SAC ElementSelector
# Robin Berjon <robin@knowscape.com>
# 24/02/2001
###

package CSS::SAC::Selector::Element;
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
                                                _local_name_
                                                _ns_uri_
                                              )],
                                  };
#---------------------------------------------------------------------#




### Constructor #######################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# CSS::SAC::Selector::Element->new($type,$ns_uri,$local_name)
# creates a new sac ElementSelector object
#---------------------------------------------------------------------#
sub new {
    my $class = ref($_[0])?ref(shift):shift;
    my $type       = shift;
    my $ns_uri     = shift;
    my $local_name = shift;

    # create a selector
    my $esel = $class->SUPER::new($type);

    # add our fields
    $esel->[_local_name_] = $local_name if $local_name;
    $esel->[_ns_uri_]     = $ns_uri     if defined $ns_uri;

    return $esel;
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Constructor #######################################################



### Accessors #########################################################
#                                                                     #
#                                                                     #

*CSS::SAC::Selector::Element::getLocalName = \&LocalName;
*CSS::SAC::Selector::Element::getNamespaceURI = \&NamespaceURI;

#---------------------------------------------------------------------#
# my $lname = $esel->LocalName()
# $esel->LocalName($lname)
# get/set the selector's local name
#---------------------------------------------------------------------#
sub LocalName {
    (@_==2) ? $_[0]->[_local_name_] = $_[1] :
              $_[0]->[_local_name_];
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $ns = $esel->NamespaceURI()
# $esel->NamespaceURI($ns)
# get/set the selector's ns
#---------------------------------------------------------------------#
sub NamespaceURI {
    (@_==2) ? $_[0]->[_ns_uri_] = $_[1] :
              $_[0]->[_ns_uri_];
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Accessors #########################################################



1;

=pod

=head1 NAME

CSS::SAC::Selector::Element - SAC ElementSelector

=head1 SYNOPSIS

 see CSS::SAC::Selector

=head1 DESCRIPTION

This is a subclass of CSS::SAC::Selector::Simple, look there for more
documentation. This class adds the following methods (which also exist
in spec style, simply prepend them with 'get'):

=head1 METHODS

=over

=item * CSS::SAC::Selector::Element->new($type,$local_name,$ns_uri)
=item * $esel->new($type,$local_name,$ns_uri)

Creates a new element selector.

=item * $esel->LocalName([$lname])

get/set the selector's local name

=item * $esel->NamespaceURI([$ns])

get/set the selector's ns

=back

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut


