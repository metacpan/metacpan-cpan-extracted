package CGI::Test::Form::Widget::Input::Text_Area;
use strict;
use warnings; 
##################################################################
# $Id: Text_Area.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
# $Name: cgi-test_0-104_t1 $
##################################################################
#
#  Copyright (c) 2001, Raphael Manfredi
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#

use Carp;

#
# This class models a FORM textarea input field.
#

use base qw(CGI::Test::Form::Widget::Input);

#
# %attr
#
# Defines which HTML attributes we should look at within the node, and how
# to translate that into class attributes.
#

my %attr = ('name'     => 'name',
            'value'    => 'value',
            'rows'     => 'rows',
            'cols'     => 'columns',
            'wrap'     => 'wrap_mode',
            'disabled' => 'is_disabled',
            'readonly' => 'is_read_only',
            );

#
# ->_init
#
# Per-widget initialization routine.
# Parse HTML node to determine our specific parameters.
#
sub _init
{
    my $this = shift;
    my ($node) = shift;
    $this->_parse_attr($node, \%attr);
    return;
}

#
# Attribute access
#
############################################################
sub rows
{
    my $this = shift;
    return $this->{rows};
}
############################################################
sub columns
{
    my $this = shift;
    return $this->{columns};
}
############################################################
sub wrap_mode
{
    my $this = shift;
    return $this->{wrap_mode};
}
############################################################

sub gui_type
{
    "text area"
}

#
# Redefined predicates
#

############################################################
sub is_area
{
    1
}

1;

=head1 NAME

CGI::Test::Form::Widget::Input::Text_Area - A text area

=head1 SYNOPSIS

 # Inherits from CGI::Test::Form::Widget::Input
 # $form is a CGI::Test::Form

 my $comments = $form->input_by_name("comments");
 $comments->append(<<EOM);
 -- 
 There's more than one way to do it.
     --Larry Wall
 EOM

=head1 DESCRIPTION

This class models a text area, where users can type text.

=head1 INTERFACE

The interface is the same as the one described in
L<CGI::Test::Form::Widget::Input>, with the following additional attributes:

=over 4

=item C<columns>

Amount of displayed columns.

=item C<rows>

Amount of displayed text rows.

=item C<wrap_mode>

The selected work wrapping mode.

=back

=head1 BUGS

Does not handle C<wrap_mode> and C<columns> yet.  There is actually some work
done by the browser when the wrapping mode is set to C<"hard">, which alters
the value transmitted back to the script upon submit.

=head1 AUTHORS

The original author is Raphael Manfredi.

Steven Hilton was long time maintainer of this module.

Current maintainer is Alexander Tokarev F<E<lt>tokarev@cpan.orgE<gt>>.

=head1 SEE ALSO

CGI::Test::Form::Widget::Input(3).

=cut

