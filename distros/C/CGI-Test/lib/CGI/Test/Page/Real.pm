package CGI::Test::Page::Real;
use strict;
use warnings; 
####################################################################
# $Id: Real.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
# $Name: cgi-test_0-104_t1 $
####################################################################
#
#  Copyright (c) 2001, Raphael Manfredi
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.

#
# An abstract interface to a real page, which is the result of a valid output
# and not an HTTP error.  The concrete representation is defined by heirs,
# depending on the Content-Type.
#

use Carp;

use base qw(CGI::Test::Page);

#
# ->new
#
# Creation routine
#
sub new
{
    confess "deferred";
}

#
# Attribute access
#

sub uri
{
    my $this = shift;
    return $this->{uri};
}

#
# ->_init
#
# Initialize common attributes
#
sub _init
{
    my $this = shift;

    my %params = @_;

    my $file              = $params{-file};
    $this->{server}       = $params{-server};
    $this->{content_type} = $params{-content_type};
    $this->{user}         = $params{-user};
    $this->{uri}          = $params{-uri};

    $this->_read_raw_content($file);

    return;
}

#
# ->_read_raw_content
#
# Read file content verbatim into `raw_content', skipping header.
#
# Even in the case of an HTML content, reading the whole thing into memory
# as a big happy string means we can issue regexp queries.
#
sub _read_raw_content
{
    my ($self, $file_name) = @_;

    open my $fh, $file_name || die "Can't open $file_name: $!";

    my %headers;
    my $content_length;

    while (my $line = <$fh>) {
        last if $line =~ /^\r?$/;

        $line =~ s/\r\n$//;

        my ($h, $v) = $line =~ /^(.*?):\s+(.*)$/;
        $headers{ $h } = $v if defined $h;

        $content_length = $v if $h =~ /content[-_]length/i;
    }

    $self->{headers} = \%headers;
    $self->{content_length} = $content_length;

    local $/ = undef;                          # Will slurp remaining
    $self->{raw_content} = <$fh>;
    close $fh;

    return;
}

1;

=head1 NAME

CGI::Test::Page::Real - Abstract representation of a real page

=head1 SYNOPSIS

 # Inherits from CGI::Test::Page
 # $page holds a CGI::Test::Page::Real object

 use CGI::Test;

 ok 1, $page->raw_content =~ /test is ok/;
 ok 2, $page->uri->scheme eq "http";
 ok 3, $page->content_type !~ /html/;

=head1 DESCRIPTION

This class is the representation of a real page, i.e. something physically
returned by the server and which is not an error.

=head1 INTERFACE

The interface is the same as the one described in L<CGI::Test::Page>, with
the following additions:

=over 4

=item C<raw_content>

Returns the raw content of the page, as a string.

=item C<raw_content_ref>

Returns a reference to the raw content of the page, to avoid making yet
another copy.

=item C<uri>

The URI object, identifying the page we requested.

=back

=head1 AUTHORS

The original author is Raphael Manfredi.

Steven Hilton was long time maintainer of this module.

Current maintainer is Alexander Tokarev F<E<lt>tokarev@cpan.orgE<gt>>.

=head1 SEE ALSO

CGI::Test::Page(3), CGI::Test::Page::HTML(3), CGI::Test::Page::Other(3),
CGI::Test::Page::Text(3), URI(3).

=cut

