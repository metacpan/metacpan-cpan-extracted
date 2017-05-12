package CGI::Test::Form::Widget::Button::Reset;
use strict;
use warnings;
##################################################################
# $Id: Reset.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
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
# This class models a FORM reset button.
#

use base qw(CGI::Test::Form::Widget::Button);

#
# Attribute access
#

sub gui_type
{
    return "reset button";
}

#
# ->press
#
# Press button.
# Has immediate effect: all widgets are reset to their initial state.
#
# Returns undef.
#
sub press
{
    my $this = shift;
    $this->form->reset();
    return undef;
}

#
# Global widget predicates
#

sub is_read_only
{
    return 1;
}    # Handled internally by client

#
# Button predicates
#

sub is_reset
{
    return 1;
}

1;

=head1 NAME

CGI::Test::Form::Widget::Button::Reset - A reset button

=head1 SYNOPSIS

 # Inherits from CGI::Test::Form::Widget::Button
 # $form is a CGI::Test::Form

 my @reset = $form->buttons_matching(sub { $_[0]->is_reset });
 $reset[0]->press if @reset;

=head1 DESCRIPTION

This class models a reset button.  Pressing this buttom immediately
resets the form to its original state.  The processing is done on the
client-side, and no request is made to the HTTP server.

The interface is the same as the one described in
L<CGI::Test::Form::Widget::Button>.

=head1 AUTHORS

The original author is Raphael Manfredi.

Steven Hilton was long time maintainer of this module.

Current maintainer is Alexander Tokarev F<E<lt>tokarev@cpan.orgE<gt>>.

=head1 SEE ALSO

CGI::Test::Form::Widget::Button(3).

=cut

