package CGI::Test::Form::Widget::Button::Plain;
use strict;
use warnings;
##################################################################
# $Id: Plain.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
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
# This class models a FORM plain <BUTTON>.
#

use base qw(CGI::Test::Form::Widget::Button);

#
# Attribute access
#

sub gui_type
{
    return "plain button";
}

#
# Button predicates
#

sub is_plain
{
    return 1;
}

1;

=head1 NAME

CGI::Test::Form::Widget::Button::Plain - A button with client-side processing

=head1 SYNOPSIS

 # Inherits from CGI::Test::Form::Widget::Button

=head1 DESCRIPTION

This class models a plain button, which probably has some client-side
processing attached to it.  Unfortunately, C<CGI::Test> does not support
this, so there's not much you can do with this button, apart from making
sure it is present.

The interface is the same as the one described in
L<CGI::Test::Form::Widget::Button>.

=head1 AUTHORS

The original author is Raphael Manfredi.

Steven Hilton was long time maintainer of this module.

Current maintainer is Alexander Tokarev F<E<lt>tokarev@cpan.orgE<gt>>.

=head1 SEE ALSO

CGI::Test::Form::Widget::Button(3).

=cut

