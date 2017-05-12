package CGI::Test::Form::Widget::Button;
use strict;
use warnings; 
##################################################################
# $Id: Button.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
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
# This class models a FORM button.
#

use base qw(CGI::Test::Form::Widget);

############################################################
#
# ->new
#
# Creation routine for <BUTTON> elements.
#
############################################################
sub new
{
    my $this = bless {}, shift;
    my ($node, $form) = @_;

    #
    # Can't create a CGI::Test::Form::Widget::Button object, only heirs.
    #

    confess "%s is a deferred class", __PACKAGE__
      if ref $this eq __PACKAGE__;

    $this->_common_init($form);

    #
    # We don't keep any reference on the node.
    # Analyze the HTML tree to determine some parameters.
    #

    $this->_init_button($node);

    return $this;
}

############################################################
#
# %attr
# %attr_button
#
# Defines which HTML attributes we should look at within the node, and how
# to translate that into class attributes.  The %attr_button is specific
# to the <BUTTON> tags.
#
############################################################

my %attr = ('name'     => 'name',
            'value'    => 'value',
            'disabled' => 'is_disabled',
            );

my %attr_button = (%attr,);

############################################################
#
# ->_init
#
# Per-widget initialization routine, for <INPUT>.
# Parse HTML node to determine our specific parameters.
#
############################################################
sub _init
{
    my $this = shift;
    my ($node) = shift;
    $this->_parse_attr($node, \%attr);
    $this->{is_enhanced} = 0;
    $this->{is_pressed}  = 0;
    return;
}

############################################################
#
# ->_init_button
#
# Per-widget initialization routine, for <BUTTON>.
# Parse HTML node to determine our specific parameters.
#
############################################################
sub _init_button
{
    my $this = shift;
    my ($node) = shift;
    $this->_parse_attr($node, \%attr_button);
    $this->{is_enhanced} = 1;
    $this->{is_pressed}  = 0;
    return;
}

############################################################
#
# ->_is_successful		-- defined
#
# Is the enabled widget "successful", according to W3C's specs?
# Any pressed button is.
#
############################################################
sub _is_successful
{
    my $this = shift;
    return $this->is_pressed();
}

#
# Attribute access
#

############################################################
sub is_enhanced
{
    my $this = shift;
    return $this->{is_enhanced};
}    # True for <BUTTON> elements
############################################################
sub is_pressed
{
    my $this = shift;
    return $this->{is_pressed};
}

############################################################
#
# ->press
#
# Press button.
#
# Has immediate effect:
#   * If it's a reset button, all widgets are reset to their initial state.
#   * If it's a submit button, a GET/POST request is issued.
#   * By default, a warning is issued that the action is ignored.
#
# Returns undef if no submit is done, a new CGI::Test::Page otherwise.
#
############################################################
sub press
{
    my $this = shift;

    #
    # Default action: do nothing
    # Routine is redefined in heirs when processing required.
    #

    warn 'ignoring button press: name="%s", value="%s"', $this->name(),
      $this->value();

    return undef;
}

############################################################
#
# ->set_is_pressed
#
# Press or unpress button.
#
############################################################
sub set_is_pressed
{
    my $this = shift;
    my ($pressed) = @_;
    $this->{is_pressed} = $pressed;
    return;
}

############################################################
#
# ->reset_state			-- redefined
#
# Called when a "Reset" button is pressed to restore the value the widget
# had upon form entry.
#
############################################################
sub reset_state
{
    my $this = shift;
    $this->{is_pressed} = 0;
    return;
}

############################################################
#
#
# Global widget predicates
#
############################################################
sub is_read_only
{
    return 1;
}

#
# Button predicates
#

############################################################
sub is_reset
{
    return 0;
}
############################################################
sub is_submit
{
    return 0;
}
############################################################
sub is_plain
{
    return 0;
}

#
# High-level classification predicates
#

############################################################
sub is_button
{
    return 1;
}

1;

=head1 NAME

CGI::Test::Form::Widget::Button - Abstract representation of a button

=head1 SYNOPSIS

 # Inherits from CGI::Test::Form::Widget

=head1 DESCRIPTION

This class is the abstract representation of a button, i.e. a submit
button, an image button, a reset button or a plain button.

Pressing a button is achieved by calling C<press()> on it, which returns a
new page, as a C<CGI::Test::Page> object, or C<undef> if pressing had
no round-trip effect.

=head1 INTERFACE

The interface is the same as the one described in L<CGI::Test::Form::Widget>,
with the following additions:

=head2 Attributes

=over 4

=item C<is_pressed>

True when the button is pressed.

=back

=head2 Attribute Setting

=over 4

=item C<press>

Press the button, setting C<is_pressed> to true.

If the button is a reset button (C<is_reset> is true), all widgets
are reset to their initial state, and C<undef> is returned.

If the button is a submit button (C<is_submit> is true), then a GET/POST
request is issued as appropriate and the reply is made available through
a C<CGI::Test::Page> object.

Otherwise, the button pressing is ignored, a warning is issued from the
perspective of the caller, via C<carp>, and C<undef> is returned.

=back

=head2 Widget Classification Predicates

There is an additional set of predicates to distinguish between the various
buttons:

=over 4

=item C<is_plain>

Returns I<true> for a plain button, i.e. a button that has no submit/reset
effects.  Usually, those buttons are linked to a script, but C<CGI::Test>
does not support scripting yet.

=item C<is_reset>

Returns I<true> for reset buttons.

=item C<is_submit>

Returns I<true> for submit buttons, whether they are really shown as
buttons or as images.  A submit button will cause an HTTP request to be
issued in response to its being pressed.

=back

=head2 Miscellaneous Features

Although documented, those features are more targetted for
internal use...

=over 4

=item C<set_is_pressed> I<flag>

Change the pressed status of the button, to the value of I<flag>.
It does not raise any other side effect, like submitting an HTTP request
if the button is a submit button.

You should probably use the C<press> convenience routine instead of calling
this feature directly.

=back

=head1 AUTHORS

The original author is Raphael Manfredi.

Steven Hilton was long time maintainer of this module.

Current maintainer is Alexander Tokarev F<E<lt>tokarev@cpan.orgE<gt>>.

=head1 SEE ALSO

CGI::Test::Form::Widget(3),
CGI::Test::Form::Widget::Button::Image(3),
CGI::Test::Form::Widget::Button::Plain(3),
CGI::Test::Form::Widget::Button::Reset(3),
CGI::Test::Form::Widget::Button::Submit(3).

=cut

