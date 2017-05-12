
###
# CSS::SAC::Condition::Lang - SAC LangConditions
# Robin Berjon <robin@knowscape.com>
# 24/02/2001
###

package CSS::SAC::Condition::Lang;
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
                                                _lang_
                                              )],
                                  };
#---------------------------------------------------------------------#




### Constructor #######################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# CSS::SAC::Condition::Lang->new($type,$lang)
# creates a new sac LangCondition object
#---------------------------------------------------------------------#
sub new {
    my $class = ref($_[0])?ref(shift):shift;
    my $type = shift; # should be one of the content conditions
    my $lang = shift;

    # create a condition
    my $ccond = $class->SUPER::new($type);

    # add our fields
    $ccond->[_lang_] = $lang if $lang;

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
*CSS::SAC::Condition::Lang::getLang = \&Lang;

#---------------------------------------------------------------------#
# my $lang = $lcond->Lang()
# $lcond->Lang($lang)
# get/set the condition's lang
#---------------------------------------------------------------------#
sub Lang {
    (@_==2) ? $_[0]->[_lang_] = $_[1] :
              $_[0]->[_lang_];
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Accessors #########################################################



1;

=pod

=head1 NAME

CSS::SAC::Condition::Lang - SAC LangConditions

=head1 SYNOPSIS

 see CSS::SAC::Condition

=head1 DESCRIPTION

This is a subclass of CSS::SAC::Condition, look there for more
documentation. This class adds the following methods (the spec
equivalents are available as well, just prepend 'get'):

=head1 METHODS

=over 4

=item * CSS::SAC::Condition::Lang->new($type,$lang)

=item * $cond->new($type,$lang)

Creates a new lang condition.

=item * $ccond->Lang([$lang])

get/set the condition's lang

=back

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut


