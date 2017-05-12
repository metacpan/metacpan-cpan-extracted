package CGI::Test::Form::Widget::Box::Check;
use strict;
use warnings;
##################################################################
# $Id: Check.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
# $Name: cgi-test_0-104_t1 $
##################################################################
#
#  Copyright (c) 2001, Raphael Manfredi
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#

#
# This class models a FORM checkbox button.
#

use base qw(CGI::Test::Form::Widget::Box);

#
# Attribute access
#

sub gui_type
{
    return "checkbox";
}

#
# Defined predicates
#

sub is_radio
{
    return 0;
}

1;

=head1 NAME

CGI::Test::Form::Widget::Box::Check - A checkbox widget

=head1 SYNOPSIS

 # Inherits from CGI::Test::Form::Widget::Box
 # $form is a CGI::Test::Form

 my ($agree, $ads) = $form->checkbox_by_name(qw(i_agree ads));

 die "expected a standalone checkbox" unless $agree->is_standalone;
 $agree->check;
 $ads->uncheck_tagged("spam OK");

=head1 DESCRIPTION

This class represents a checkbox widget, which may be checked or unchecked
at will by users.

The interface is the same as the one described
in L<CGI::Test::Form::Widget::Box>.

=head1 AUTHORS

The original author is Raphael Manfredi.

Steven Hilton was long time maintainer of this module.

Current maintainer is Alexander Tokarev F<E<lt>tokarev@cpan.orgE<gt>>.

=head1 SEE ALSO

CGI::Test::Form::Widget::Box(3), CGI::Test::Form::Widget::Box::Radio(3).

=cut

