package CGI::Test::Form::Widget::Menu::Popup;
use strict;
use warnings; 
##################################################################
# $Id: Popup.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
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
# This class models a FORM popup menu.
#

use base qw(CGI::Test::Form::Widget::Menu);

#
# %attr
#
# Defines which HTML attributes we should look at within the node, and how
# to translate that into class attributes.
#

my %attr = ('name'     => 'name',
            'disabled' => 'is_disabled',);

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
    $this->_parse_options($node);
    return;
}

#
# ->set_selected		-- redefined
#
# Change "selected" status for a menu value.
# We can only "select" values from a popup, never unselect one.
#
sub set_selected
{
    my $this = shift;
    my ($value, $state) = @_;

    unless ($state)
    {
        carp "cannot unselect value \"%s\" from popup $this", $value;
        return;
    }

    return $this->SUPER::set_selected($value, $state);
}

#
# Attribute access
#

sub gui_type
{
    return "popup menu";
}

#
# Defined predicates
#

sub is_popup
{
    return 1;
}

1;

=head1 NAME

CGI::Test::Form::Widget::Menu::Popup - A popup menu

=head1 SYNOPSIS

 # Inherits from CGI::Test::Form::Widget::Menu
 # $form is a CGI::Test::Form

 my $action = $form->menu_by_name("action");
 $action->select("reboot");

=head1 DESCRIPTION

This class models a popup menu, from which one item at most may be selected,
and for which there is at least one item selected, i.e. where exactly one
item is chosen.

If no item was explicitely selected, C<CGI::Test> arbitrarily chooses the
first item in the popup (if not empty) and warns you via C<warn>.

=head1 INTERFACE

The interface is the same as the one described in
L<CGI::Test::Form::Widget::Menu>.

=head1 AUTHORS

The original author is Raphael Manfredi.

Steven Hilton was long time maintainer of this module.

Current maintainer is Alexander Tokarev F<E<lt>tokarev@cpan.orgE<gt>>.

=head1 SEE ALSO

CGI::Test::Form::Widget::Menu(3).

=cut

