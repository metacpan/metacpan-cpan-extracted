#---------------------------------------------------------------------
package Apache2::HttpEquiv;
#
# Copyright 2012 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 11 Mar 2006
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Convert <meta http-equiv=...> to HTTP headers
#---------------------------------------------------------------------

use 5.008;
use strict;
use Apache2::Const -compile => qw(OK DECLINED);
use HTML::PullParser;

#=====================================================================
# Package Global Variables:

our $VERSION = '1.00';
# This file is part of Apache2-HttpEquiv 1.00 (January 4, 2014)

#=====================================================================
sub handler
{
  my $r = shift;

  return Apache2::Const::DECLINED
      unless $r->is_initial_req
         and $r->content_type eq "text/html"
         and open(my $file, '<:encoding(latin1)', $r->filename);

  my ($p, $token, $header) = HTML::PullParser->new(
    file  => $file,
    start => 'tag, attr',
    end   => 'tag',
  );

  my $content_type;

  while ($token = $p->get_token) {
    if ($token->[0] eq 'meta') {
      if ($header = $token->[1]{'charset'} and not defined $content_type) {
        $content_type = "text/html; charset=$header";
      } # end if <meta charset=...>
      elsif ($header = $token->[1]{'http-equiv'}) {
        if ($header eq 'Content-Type' and not defined $content_type) {
          $content_type = $token->[1]{content};
          # text/xhtml is not a valid content type:
          $content_type =~ s!^text/xhtml(?=\s|;|\z)!text/html!i;
        } else {
          $r->headers_out->set($header => $token->[1]{content});
        }
      } # end elsif <meta http-equiv=...>
    } # end if <meta> tag
    last if $token->[0] eq 'body' or $token->[0] eq '/head';
  } # end while get_token

  $r->content_type($content_type) if $content_type;

  close($file);

  return Apache2::Const::OK;
} # end handler

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

Apache2::HttpEquiv - Convert <meta http-equiv=...> to HTTP headers

=head1 VERSION

This document describes version 1.00 of
Apache2::HttpEquiv, released January 4, 2014.

=head1 SYNOPSIS

In your Apache config:

  <Location />
    PerlFixupHandler Apache2::HttpEquiv
  </Location>

=head1 DESCRIPTION

Apache2::HttpEquiv provides a PerlFixupHandler for mod_perl 2 that turns
C<< <meta http-equiv="Header-Name" content="Header Value"> >> into an actual
HTTP header.  It also looks for C<< <meta charset="..."> >> and uses it to
set the Content-Type to C<text/html; charset=...>.

If the file claims its Content-Type is 'text/xhtml', the Content-Type
is set to 'text/html' instead.  'text/xhtml' is not a valid
Content-Type, and any file that claims it is probably too broken to
parse as 'application/xhtml+xml'.

This works only for static HTML files (that Apache has identified as
'text/html').  If you're generating dynamic content, you should be
generating the appropriate Content-Type and other headers at the same
time.

=for Pod::Coverage
handler

=head1 CONFIGURATION AND ENVIRONMENT

Apache2::HttpEquiv requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-Apache2-HttpEquiv AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Apache2-HttpEquiv >>.

You can follow or contribute to Apache2-HttpEquiv's development at
L<< https://github.com/madsen/apache2-httpequiv >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
