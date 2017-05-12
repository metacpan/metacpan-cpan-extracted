package CGI::Test::Form::Widget::Menu::List;
use strict;
use warnings;
##################################################################
# $Id: List.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
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
# This class models a FORM scrollable list.
#

use base qw(CGI::Test::Form::Widget::Menu);

#
# %attr
#
# Defines which HTML attributes we should look at within the node, and how
# to translate that into class attributes.
#

my %attr = ('name'     => 'name',
            'size'     => 'size',
            'multiple' => 'multiple',
            'disabled' => 'is_disabled',
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
    $this->_parse_options($node);
    return;
}

#
# ->submit_tuples		-- redefined
#
# Returns list of (name => value) tuples that should be part of the
# submitted form data.
#
sub submit_tuples
{
    my $this = shift;

    return map {$this->name => $_} keys %{$this->selected()};
}

#
# Attribute access
#

sub size
{
    my $this = shift;
    return $this->{size};
}

sub gui_type
{
    "scrolling list"
}

#
# Defined predicates
#

sub is_popup
{
    return 0;
}

1;

=head1 NAME

CGI::Test::Form::Widget::Menu::List - A scrolling list menu

=head1 SYNOPSIS

 # Inherits from CGI::Test::Form::Widget::Menu
 # $form is a CGI::Test::Form

 my $action = $form->menu_by_name("action");
 $action->unselect("allow-gracetime");
 $action->select("reboot");

=head1 DESCRIPTION

This class models a scrolling list menu, from which items may be selected
and unselected.

=head1 INTERFACE

The interface is the same as the one described in
L<CGI::Test::Form::Widget::Menu>, with the following additional attribute:

=over 4

=item C<size>

The amount of choices displayed.

=back

=head1 AUTHORS

The original author is Raphael Manfredi.

Steven Hilton was long time maintainer of this module.

Current maintainer is Alexander Tokarev F<E<lt>tokarev@cpan.orgE<gt>>.

=head1 SEE ALSO

CGI::Test::Form::Widget::Menu(3).

=cut

