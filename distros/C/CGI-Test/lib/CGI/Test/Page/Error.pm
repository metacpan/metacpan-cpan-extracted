package CGI::Test::Page::Error;
use strict;
use warnings; 
####################################################################
# $Id: Error.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
# $Name: cgi-test_0-104_t1 $
####################################################################
#
#  Copyright (c) 2001, Raphael Manfredi
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.

#
# A reply to an HTTP request resulted in an error.
#

require CGI::Test::Page;
use base qw(CGI::Test::Page);

############################################################
#
# ->new
#
# Creation routine
#
############################################################
sub new
{
    my $this = bless {}, shift;
    my ($errcode, $server) = @_;
    $this->{error_code} = $errcode;
    $this->{server}     = $server;
    return $this;
}

#
# Attribute access
#

############################################################
sub error_code
{
    my $this = shift;
    return $this->{error_code};
}    # redefined as attribute

#
# Redefined features
#
############################################################
sub is_error
{
    return 1;
}
############################################################
sub content_type
{
    return "text/html";
}

1;

=head1 NAME

CGI::Test::Page::Error - An HTTP error page

=head1 SYNOPSIS

 # Inherits from CGI::Test::Page

=head1 DESCRIPTION

This class represents an HTTP error page.
Its interface is the same as the one described in L<CGI::Test::Page>.

=head1 AUTHORS

The original author is Raphael Manfredi.

Steven Hilton was long time maintainer of this module.

Current maintainer is Alexander Tokarev F<E<lt>tokarev@cpan.orgE<gt>>.

=head1 SEE ALSO

CGI::Test::Page(3), CGI::Test::Page::Real(3).

=cut

