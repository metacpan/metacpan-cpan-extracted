package CGI::Test::Page::Other;
use strict;
use warnings;
####################################################################
# $Id: Other.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
# $Name: cgi-test_0-104_t1 $
####################################################################
#
#  Copyright (c) 2001, Raphael Manfredi
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#

require CGI::Test::Page::Real;
use base qw(CGI::Test::Page::Real);

#
# ->new
#
# Creation routine
#
sub new
{
    my $this = bless {}, shift;
    $this->_init(@_);
    return $this;
}

1;

=head1 NAME

CGI::Test::Page::Other - A real page, but neither text nor HTML

=head1 SYNOPSIS

 # Inherits from CGI::Test::Page::Real

=head1 DESCRIPTION

This class represents an HTTP reply containing neither C<text/hmtl>
nor C<text/plain> data.
Its interface is the same as the one described in L<CGI::Test::Page::Real>.

=head1 AUTHORS

The original author is Raphael Manfredi.

Steven Hilton was long time maintainer of this module.

Current maintainer is Alexander Tokarev F<E<lt>tokarev@cpan.orgE<gt>>.

=head1 SEE ALSO

CGI::Test::Page::Real(3).

=cut

