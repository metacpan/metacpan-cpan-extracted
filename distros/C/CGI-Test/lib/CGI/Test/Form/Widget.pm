package CGI::Test::Form::Widget;
use strict;
use warnings;
################################################################
# $Id: Widget.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
# $Name: cgi-test_0-104_t1 $
################################################################
#
#  Copyright (c) 2001, Raphael Manfredi
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#

use Carp;

#
# This class models a CGI form widget (button, text field, etc...).
# It belongs to one form, identified by its `form' attribute , a ref
# to a CGI::Test::Form object.
#

############################################################
#
# ->new
#
# Creation routine -- common to ALL widgets but <BUTTON> elements.
#
############################################################
sub new
{
    my $this = bless {}, shift;
    my ($node, $form) = @_;

    #
    # Can't create a CGI::Test::Form::Widget object, only heirs.
    #

    confess "%s is a deferred class", __PACKAGE__
      if ref $this eq __PACKAGE__;

    $this->_common_init($form);

    #
    # We don't keep any reference on the node.
    # Analyze the HTML tree to determine some parameters.
    #

    $this->_init($node);    # Defined in each heir

    return $this;
}

############################################################
#
# ->_common_init
#
# Common attribute initialization for all widgets
#
############################################################
sub _common_init
{
    my $this = shift;
    my ($form) = @_;

    $this->{form}  = $form;    # <FORM> containing this widget
    $this->{name}  = "";       # Always possible to query, must be defined
    $this->{value} = "";       # Idem

    return;
}

############################################################
#
# ->_init
#
# Per-widget initialization routine.
# Parse HTML node to determine our specific parameters.
#
############################################################
sub _init
{
    my $this = shift;
    my ($node) = @_;
    confess "deferred";
}

############################################################
#
# ->_parse_attr
#
# Each heir locally defines a hash table mapping HTML node attributes to
# class attributes.  This structure is used to parse the node and setup
# the object accordingly.
#
############################################################
sub _parse_attr
{
    my $this = shift;
    my ($node, $attr) = @_;

    while (my ($html_attr, $obj_attr) = each %$attr)
    {
        my $val = $node->attr($html_attr);
        $this->{$obj_attr} = $val if defined $val;
    }

    return;
}

#
# Attribute access
#

sub form
{
    my $this = shift;
    return $this->{form};
}

#
# Access to attributes that must be setup by heirs within _init()
# Those are common attributes for the whole Widget hierarchy.
#
# The `value' attribute may not have any meaning (e.g. for an image button)
# but it is always possible to query it.
#

sub name
{
    my $this = shift;
    return $this->{name};
}

sub value
{
    my $this = shift;
    return $this->{value};
}

sub old_value
{
    my $this = shift;
    return $this->{old_value};
}

sub is_disabled
{
    my $this = shift;
    return $this->{is_disabled};
}    # "grayed out"

#
# Global widget predicates
#

sub is_read_only
{
    0
}    # Can change "value"

#
# High-level classification predicates
#

############################################################
sub is_button
{
    return 0;
}
############################################################
sub is_input
{
    return 0;
}
############################################################
sub is_menu
{
    return 0;
}
############################################################
sub is_box
{
    return 0;
}
############################################################
sub is_hidden
{
    return 0;
}
############################################################
sub is_file
{
    return 0;
}

sub gui_type
{
    confess "deferred";
}

############################################################
#
# ->is_mutable
#
# Check whether it is possible to change widget's value from a user interface.
# Optionally warn if widget's value cannot be changed.
#
############################################################
sub is_mutable
{
    my $this = shift;
    my ($warn) = @_;

    if ($this->is_disabled)
    {
        carp 'cannot change value of disabled %s "%s"', $this->gui_type,
          $this->name
          if $warn;
        return 0;
    }

    if ($this->is_read_only)
    {
        carp 'cannot change value of read-only %s "%s"', $this->gui_type,
          $this->name
          if $warn;
        return 0;
    }

    return 1;
}

############################################################
#
# ->set_value
#
# Change value.
# Only allowd to proceed if mutable.
#
############################################################
sub set_value
{
    my $this = shift;
    my ($value) = @_;

    return unless $this->is_mutable(1);    # Cannot change value
    return if $value eq $this->{value};    # No change

    #
    # To ease redefinition, let this call _frozen_set_value, which is
    # not redefinable and performs the common operation.
    #

    $this->_frozen_set_value($value);
    return;
}

############################################################
#
# ->_frozen_set_value		-- frozen
#
# Change value.
#
############################################################
sub _frozen_set_value
{
    my $this = shift;
    my ($value) = @_;

    #
    # The first time we do this, save current value in `old_value'.
    #

    $this->{old_value} = $this->{value} unless exists $this->{old_value};
    $this->{value}     = $value;

    return;
}

############################################################
#
# ->reset_state
#
# Called when a "Reset" button is pressed to restore the value the widget
# had upon form entry.
#
############################################################
sub reset_state
{
    my $this = shift;

    #
    # If there is `old_value' attribute yet, then the value is already OK.
    #

    return unless exists $this->{old_value};

    #
    # Restore value from old_value, and delete this attribute to signal that
    # the value is now back to its original setting.
    #

    $this->{value} = delete $this->{old_value};
    return;
}

############################################################
#
# ->is_submitable
#
# Check whether widget is "successful" (that's such an ugly name), in other
# words, whether its name/value pair should be part of submittted form data.
#
# A "successful" widget must not be disabled.
# Heirs should define the _is_successful internal routine.
#
# Returns true if submitable.
#
############################################################
sub is_submitable
{
    my $this = shift;

    return 0 if $this->is_disabled;
    return $this->_is_successful;
}

############################################################
#
# ->_is_successful
#
# Is the enabled widget "successful", according to W3C's specs?
#
############################################################
sub _is_successful
{
    confess "deferred";
}

############################################################
#
# ->submit_tuples
#
# Returns list of (name => value) tuples that should be part of the
# submitted form data.  There may be more than one tuple returned for
# scrollable lists only: each checkbox is a widget, and therefore can
# return only one tuple.
#
############################################################
sub submit_tuples
{
    my $this = shift;

    return ($this->name(), $this->value());
}

############################################################
#
# ->delete
#
# Done with this widget, cleanup by breaking circular refs.
#
############################################################
sub delete
{
    my $this = shift;
    $this->{form} = undef;
    return;
}

1;

=head1 NAME

CGI::Test::Form::Widget - Ancestor of all form widget classes

=head1 SYNOPSIS

 # Deferred class, only heirs can be created

=head1 DESCRIPTION

The C<CGI::Test::Form::Widget> class is deferred.
It is an abstract representation of a <FORM> widget, i.e. a graphical control
element like a popup menu or a submit button.

Here is an outline of the class hierarchy tree, with the leading
C<CGI::Test::Form::> string stripped for readability, and a trailing C<*>
indicating deferred classes:

    Widget*
    . Widget::Box*
    . . Widget::Box::Check
    . . Widget::Box::Radio
    . Widget::Button*
    . . Widget::Button::Plain
    . . Widget::Button::Submit
    . .   Widget::Button::Image
    . . Widget::Button::Reset
    . Widget::Hidden
    . Widget::Input*
    . . Widget::Input::Text_Area
    . . Widget::Input::Text_Field
    . .   Widget::Input::File
    . .   Widget::Input::Password
    . Widget::Menu*
    . . Widget::Menu::List
    . . Widget::Menu::Popup

Only leaf nodes are concrete classes, and there is one such class for each
known control type that can appear in the <FORM> element.

Those classes are constructed as needed by C<CGI::Test>.  They are the
programmatic artefacts which can be used to manipulate those graphical
elements, on which you would otherwise click and fill within a browser.

=head1 INTERFACE

This is the interface defined at the C<CGI::Test::Form::Widget> level,
and which is therefore common to all classes in the hierarchy.
Each subclass may naturally add further specific features.

It is very important to stick to using common widget features when
writing a matching callback for the C<widgets_matching> routine in
C<CGI::Test::Form>, or you run the risk of getting a runtime error
since Perl is not statically typed.

=head2 Attributes

=over 4

=item C<form>

The C<CGI::Test::Form> to which this widget belongs.

=item C<gui_type>

A human readable description of the widget, as it would appear on a GUI,
like "popup menu" or "radio button".  Meant for logging only, not to
determine the object type.

=item C<name>

The CGI parameter name.

=item C<value>

The current CGI parameter value.

=back

=head2 Attribute Setting

=over 4

=item C<set_value> I<new_value>

Change the C<value> attribute to I<new_value>.
The widget must not be C<is_read_only> nor C<is_disabled>.

=back

=head2 Widget Modification Predicates

Those predicates may be used to determine whether it is possible to
change the value of a widget from the user interface.

=over 4

=item C<is_disabled>

When I<true>, the widget is disabled, i.e. not available for editing.
It would typically appear as being I<grayed out> within a browser.

This predicate is not architecturally defined: a widget may or may not
be marked as disabled in HTML via a suitable attribute.

=item C<is_mutable> [I<warn_flag>]

Test whether widget can change value.  Returns I<false> when
the widget C<is_read_only> or C<is_disabled>.

When the optional I<warn_flag> is true, C<carp> is called
to emit a warning from the perspective of the caller.

=item C<is_read_only>

When I<false>, the C<value> parameter can be changed with C<set_value>.
This is an architecturally defined predicate, i.e. its value depends only
on the widget type.

=back

=head2 Widget Classification Predicates

Those predicates may be used to determine the overall widget type.
The classification is rather high level and only helps determining
the kind of calls that may be used on a given widget object.

=over 4

=item C<is_box>

Returns true for radio buttons and checkboxes.

=item C<is_button>

Returns true for all buttons that are not boxes.

=item C<is_file>

Returns true for a I<file upload> widget, which allows file selection.

=item C<is_hidden>

Returns true for hidden fields, which have no graphical representation
by definition.

=item C<is_input>

Returns true for all input fields, where the user can type text.

=item C<is_menu>

Returns true for popup menus and scrolling lists.

=back

=head2 Miscellaneous Features

Although documented, those features are more targetted for internal use...

=over 4

=item C<delete>

Breaks circular references.
This is normally done by the C<delete> routine on the enclosing form.

=item C<is_submitable>

Returns I<true> when the name/value tupple of this widget need to be
part of the submitted parameters.  The rules for determining the submitable
nature of a widget vary depending on the widget type.

=item C<reset_state>

Reset the widget's C<value> to the one it had initially.  Invoked internally
when a reset button is pressed.

=item C<submit_tuples>

For submitable widgets, return the list of (name => value) tupples that
should be part of the submitted data.  Widgets like scrolling list may return
more than one tuple.

This routine is invoked to compute the parameter list that must be sent back
when pressing a submit button.

=back

=head1 AUTHORS

The original author is Raphael Manfredi.

Steven Hilton was long time maintainer of this module.

Current maintainer is Alexander Tokarev F<E<lt>tokarev@cpan.orgE<gt>>.

=head1 SEE ALSO

CGI::Test::Form(3),
CGI::Test::Form::Widget::Box(3),
CGI::Test::Form::Widget::Button(3),
CGI::Test::Form::Widget::Input(3),
CGI::Test::Form::Widget::Hidden(3),
CGI::Test::Form::Widget::Menu(3).

=cut

