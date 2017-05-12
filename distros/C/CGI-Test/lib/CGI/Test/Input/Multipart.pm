package CGI::Test::Input::Multipart;
use strict;
use warnings; 
####################################################################
# $Id: Multipart.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
# $Name: cgi-test_0-104_t1 $
####################################################################
#
#  Copyright (c) 2001, Raphael Manfredi
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#

#
# POST input data to be encoded with "multipart/form-data".
#

use Carp;

use base qw(CGI::Test::Input);

#
# ->new
#
# Creation routine
#
sub new
{
    my $this = bless {}, shift;
    $this->_init;
    $this->{boundary} =
        "-------------cgi-test--------------"
      . int(rand(1 << 31)) . '-'
      . int(rand(1 << 31));
    return $this;
}

# DEPRECATED METHOD
sub make
{    #
    my $class = shift;
    return $class->new(@_);
}

#
# Attribute access
#

sub boundary
{
    my $this = shift;
    return $this->{boundary};
}

#
# Defined interface
#

sub mime_type
{
    my $this = shift;
    "multipart/form-data; boundary=" . $this->boundary();
}

#
# ->_build_data
#
# Rebuild data buffer from input fields.
#
sub _build_data
{
    my $this = shift;

    my $CRLF = "\015\012";
    my $data = '';
    my $fmt  = 'Content-Disposition: form-data; name="%s"';
    my $boundary = "--" . $this->boundary();  # With extra "--" per MIME specs

    # XXX field name encoding of special chars?
    # XXX does not escape "" in filenames

    foreach my $tuple (@{$this->_fields()})
    {
        my ($name, $value) = @$tuple;
        $data .= $boundary . $CRLF;
        $data .= sprintf($fmt, $name) . $CRLF . $CRLF;
        $data .= $value . $CRLF;
    }

    foreach my $tuple (@{$this->_files()})
    {
        my ($name, $value, $content) = @$tuple;
        $data .= $boundary . $CRLF;
        $data .= sprintf($fmt, $name);
        $data .= sprintf('; filename="%s"', $value) . $CRLF;
        $data .= "Content-Type: application/octet-stream" . $CRLF . $CRLF;
        if (defined $content)
        {
            $data .= $content;
        }
        else
        {
            local *FILE;
            if (open(FILE, $value))
            {    # Might not exist, but that's OK
                binmode FILE;
                local $_;
                while (<FILE>)
                {
                    $data .= $_;
                }
                close FILE;
            }
        }
    }

    $data .= $boundary . $CRLF;

    return $data;
}

1;

=head1 NAME

CGI::Test::Input::Multipart - POST input encoded as multipart/form-data

=head1 SYNOPSIS

 # Inherits from CGI::Test::Input
 require CGI::Test::Input::Multipart;

 my $input = CGI::Test::Input::Multipart->new();

=head1 DESCRIPTION

This class represents the input for HTTP POST requests, encoded
as C<multipart/form-data>.

Please see L<CGI::Test::Input> for interface details.

=head1 AUTHORS

The original author is Raphael Manfredi.

Steven Hilton was long time maintainer of this module.

Current maintainer is Alexander Tokarev F<E<lt>tokarev@cpan.orgE<gt>>.

=head1 SEE ALSO

CGI::Test::Input(3).

=cut

