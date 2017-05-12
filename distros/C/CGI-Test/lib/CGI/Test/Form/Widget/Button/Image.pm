package CGI::Test::Form::Widget::Button::Image;
use strict;
use warnings; 
##################################################################
# $Id: Image.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
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
# This class models a FORM image button.
# It's really a submit button in disguise as far as processing goes.
#

use base qw(CGI::Test::Form::Widget::Button::Submit);

#
# Attribute access
#

sub gui_type
{
    return "image button";
}

1;

=head1 NAME

CGI::Test::Form::Widget::Button::Image - A nice submit button

=head1 SYNOPSIS

 # Inherits from CGI::Test::Form::Widget::Button
 # $form is a CGI::Test::Form

 my $send = $form->submit_by_name("send");
 my $answer = $send->press;

=head1 DESCRIPTION

This class models an image button.  Apart from the fact that it's probably
nicer on a browser, this widget otherwise behaves like your ordinary
submit button.

Pressing it immediately triggers an HTTP request, as defined by the form.

The interface is the same as the one described in
L<CGI::Test::Form::Widget::Button>.

=head1 AUTHORS

The original author is Raphael Manfredi.

Steven Hilton was long time maintainer of this module.

Current maintainer is Alexander Tokarev F<E<lt>tokarev@cpan.orgE<gt>>.

=head1 SEE ALSO

CGI::Test::Form::Widget::Button(3).

=cut

