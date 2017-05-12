package CGI::Test::Form::Widget::Hidden;
use strict;
use warnings;
##################################################################
# $Id: Hidden.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
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
# This class models a FORM hidden field.
#

use base qw(CGI::Test::Form::Widget);

#
# %attr
#
# Defines which HTML attributes we should look at within the node, and how
# to translate that into class attributes.
#

my %attr = ('name'     => 'name',
            'value'    => 'value',
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
    return;
}

#
# ->_is_successful		-- defined
#
# Is the enabled widget "successful", according to W3C's specs?
# Any hidden field with a VALUE attribute is.
#
sub _is_successful
{
    my $this = shift;
    return defined $this->value();
}

#
# Attribute access
#

sub gui_type
{
    return "hidden field";
}

#
# Global widget predicates
#

sub is_read_only
{
    return 1;
}

#
# High-level classification predicates
#

sub is_hidden
{
    return 1;
}

1;

=head1 NAME

CGI::Test::Form::Widget::Hidden - A hidden field

=head1 SYNOPSIS

 # Inherits from CGI::Test::Form::Widget

=head1 DESCRIPTION

This class represents a hidden field, which is meant to be resent as-is
upon submit.  Such a widget is therefore read-only.

The interface is the same as the one described
in L<CGI::Test::Form::Widget>.

=head1 AUTHORS

The original author is Raphael Manfredi.

Steven Hilton was long time maintainer of this module.

Current maintainer is Alexander Tokarev F<E<lt>tokarev@cpan.orgE<gt>>.

=head1 SEE ALSO

CGI::Test::Form::Widget(3).

=cut

