
###
# CSS::SAC::Condition::Attribute - SAC AttributeConditions
# Robin Berjon <robin@knowscape.com>
# 24/02/2001
###

package CSS::SAC::Condition::Attribute;
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
                                                _local_name_
                                                _value_
                                                _ns_uri_
                                                _specified_
                                              )],
                                  };
#---------------------------------------------------------------------#




### Constructor #######################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# CSS::SAC::Condition::Attribute->new($type,$lname,$ns,$specified,$value)
# creates a new sac AttributeCondition object
#---------------------------------------------------------------------#
sub new {
    my $class = ref($_[0])?ref(shift):shift;
    my $type       = shift; # should be one of the attribute conditions
    my $local_name = shift;
    my $ns_uri     = shift;
    my $specified  = shift;
    my $value      = shift;

    # create a condition
    my $acond = $class->SUPER::new($type);

    # add our fields
    $acond->[_local_name_] = $local_name if $local_name;
    $acond->[_value_]      = $value      if defined $value;
    $acond->[_ns_uri_]     = $ns_uri     if defined $ns_uri;
    $acond->[_specified_]  = $specified  if $specified;

    return $acond;
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Constructor #######################################################



### Accessors #########################################################
#                                                                     #
#                                                                     #

# aliases
*CSS::SAC::Condition::Attribute::getLocalName = \&LocalName;
*CSS::SAC::Condition::Attribute::getNamespaceURI = \&NamespaceURI;
*CSS::SAC::Condition::Attribute::getValue = \&Value;
*CSS::SAC::Condition::Attribute::getSpecified = \&Specified;


#---------------------------------------------------------------------#
# my $lname = $cond->LocalName()
# $cond->LocalName($lname)
# get/set the local name
#---------------------------------------------------------------------#
sub LocalName {
    (@_==2) ? $_[0]->[_local_name_] = $_[1] :
              $_[0]->[_local_name_];
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $ns = $cond->NamespaceURI()
# $cond->NamespaceURI($ns)
# get/set the ns uri
#---------------------------------------------------------------------#
sub NamespaceURI {
    (@_==2) ? $_[0]->[_ns_uri_] = $_[1] :
              $_[0]->[_ns_uri_];
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $value = $cond->Value()
# $cond->Value($value)
# get/set the value
#---------------------------------------------------------------------#
sub Value {
    (@_==2) ? $_[0]->[_value_] = $_[1] :
              $_[0]->[_value_];
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# my $spec = $cond->Specified()
# $cond->Specified($spec)
# get/set the 'specified' state, ie whether a specific value was
# requested for this attr
#---------------------------------------------------------------------#
sub Specified {
    (@_==2) ? $_[0]->[_specified_] = $_[1] :
              $_[0]->[_specified_];
}
#---------------------------------------------------------------------#



#                                                                     #
#                                                                     #
### Accessors #########################################################



1;

=pod

=head1 NAME

CSS::SAC::Condition::Attribute - SAC AttributeConditions

=head1 SYNOPSIS

 see CSS::SAC::Condition

=head1 DESCRIPTION

This is a subclass of CSS::SAC::Condition, look there for more
documentation. This class adds the following methods (the spec
equivalents are available as well, just prepend 'get'):

=head1 METHODS

=over 4

=item * CSS::SAC::Condition::Attribute->new($type,$lname,$ns,$specified,$value)

=item * $cond->new($type,$lname,$ns,$specified,$value)

Creates a new attribute condition.

=item * $acond->LocalName([$lname])

get/set the local name

=item * $acond->NamespaceURI([$ns])

get/set the ns uri

=item * $acond->Value([$value])

get/set the value

=item * $acond->Specified([$spec])

get/set the 'specified' state, ie whether a specific value was
requested for this attr

=back

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut


