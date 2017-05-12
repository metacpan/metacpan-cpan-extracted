
###
# CSS::SAC::Condition::Positional - SAC PositionalConditions
# Robin Berjon <robin@knowscape.com>
# 24/02/2001
###

package CSS::SAC::Condition::Positional;
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
                                                _position_
                                                _same_type_
                                                _same_node_type_
                                              )],
                                  };
#---------------------------------------------------------------------#




### Constructor #######################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# CSS::SAC::Condition::Positional->new($type,$position,$node_type,$same_type)
# creates a new sac PositionalCondition object
#---------------------------------------------------------------------#
sub new {
    my $class = ref($_[0])?ref(shift):shift;
    my $type      = shift; # should be one of the content conditions
    my $position  = shift;
    my $same_type = shift;
    my $node_type = shift;


### IMPORTANT NOTE ###
#
# we will need to parse the new an+b expressions that can be found in
# positional conditions. In fact, old style simple numbers will be
# expressed that new way because they can be mapped to it.
#
# We'll need to provide for the corresponding accessors. Also, a
# ->position_matches($pos) method would be cool as it would allow
# client code to simply ask whether a position matches instead of
# calculating it itself.


    # create a condition
    my $pcond = $class->SUPER::new($type);

    # add our fields
    $pcond->[_position_]       = $position  if defined $position;
    $pcond->[_same_type_]      = $same_type if defined $same_type;
    $pcond->[_same_node_type_] = $node_type if defined $node_type;

    return $pcond;
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Constructor #######################################################



### Accessors #########################################################
#                                                                     #
#                                                                     #

# aliases
*CSS::SAC::Condition::Positional::getPosition = \&Position;
*CSS::SAC::Condition::Positional::getType = \&Type;
*CSS::SAC::Condition::Positional::getTypeNode = \&TypeNode;


#---------------------------------------------------------------------#
# my $pos = $pcond->Position()
# $pcond->Position($pos)
# get/set the condition's position
#---------------------------------------------------------------------#
sub Position {
    (@_==2) ? $_[0]->[_position_] = $_[1] :
              $_[0]->[_position_];
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $bool = $pcond->Type()
# $pcond->Type($bool)
# get/set the condition's type constraint
#---------------------------------------------------------------------#
sub Type {
    (@_==2) ? $_[0]->[_same_type_] = $_[1] :
              $_[0]->[_same_type_];
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $bool = $pcond->TypeNode()
# $pcond->TypeNode($bool)
# get/set the condition's node type constraint
#---------------------------------------------------------------------#
sub TypeNode {
    (@_==2) ? $_[0]->[_same_node_type_] = $_[1] :
              $_[0]->[_same_node_type_];
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Accessors #########################################################



1;

=pod

=head1 NAME

CSS::SAC::Condition::Positional - SAC PositionalConditions

=head1 SYNOPSIS

 see CSS::SAC::Condition

=head1 DESCRIPTION

This is a subclass of CSS::SAC::Condition, look there for more
documentation. This class adds the following methods (the spec
equivalents are available as well, just prepend 'get'):

=head1 METHODS

=over 4

=item * CSS::SAC::Condition::Positional->new($type,$pos,$node_type,$same_type)

=item * $cond->new($type,$pos,$node_type,$same_type)

Creates a new positional condition.

=item * $pcond->Position([$pos])

get/set the condition's position

=item * $pcond->Type([$bool])

get/set the condition's type constraint

=item * $pcond->TypeNode([$bool])

get/set the condition's node type constraint

=back

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut


