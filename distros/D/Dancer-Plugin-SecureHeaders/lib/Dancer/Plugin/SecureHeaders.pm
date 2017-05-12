package Dancer::Plugin::SecureHeaders;

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;

=head1 NAME

Dancer::Plugin::SecureHeaders - Automate HTTP Security headers.

=head1 VERSION

Version 1.0.3

=cut

=for HTML <a href="https://travis-ci.org/Casao/Dancer-Plugin-Paginate"><img src="https://travis-ci.org/Casao/Dancer-Plugin-Paginate.svg?branch=master"></a>

=cut

our $VERSION = '1.0.3';

=head1 DESCRIPTION

Automatically add HTTP Security Headers to requests.

=head1 SYNOPSIS

Provides sensible default HTTP Security headers. Allows setting the headers in the plugin configuration.

Will not override any headers set manually.

=head1 SETTINGS

=head2 Frame-Options

Sets the B<X-Frame-Options> header. Defaults to B<"DENY">.

=head2 Content-Security-Policy

Sets the B<X-Content-Security-Policy> header. Defaults to B<"default-src 'self'">. 

Specification for this header is available at L<https://dvcs.w3.org/hg/content-security-policy/raw-file/bcf1c45f312f/csp-unofficial-draft-20110303.html>.

=head2 IE-Settings

Determines whether to supplier IE-specific headers.

=head2 IE-Content-Type-Options

Sets the B<X-Content-Type-Options> header for IE. Defaults to B<"nosniff">.

=head2 IE-Download-Options

Sets the B<X-Download-Options> header for IE. Defaults to B<'noopen'>.

=head2 IE-XSS-Protection

Sets the B<X-XSS-Protection> header. Defaults to B<"1; 'mode=block'">.

=head1 Example Settings (default)

=begin :text

    plugins:
        SecureHeaders:
            Frame-Options: "DENY"
            Content-Security-Policy: "default-src 'self'"
            IE-Settings: 1
            IE-Content-Type-Options: "nosniff"
            IE-Download-options: "noopen"
            IE-XSS-Protection: "1; 'mode=block'"

=end :text

=cut

my $settings = plugin_setting;
my $frame_options = $settings->{'Frame-Options'} || 'DENY';
my $content_security_policy = $settings->{'Content-Security-Policy'} || "default-src 'self'";
my $ie_settings = $settings->{'IE-Settings'} || 1;
my $ie_content_type = $settings->{'IE-Content-Type-Options'} || 'nosniff';
my $ie_download_options = $settings->{'IE-Download-Options'} || 'noopen';
my $ie_xss_protection = $settings->{'IE-XSS-Protection'} || "1; 'mode=block'";

hook after => sub {
    my $res = shift;

    _add_header('X-Frame-Options', $frame_options, $res);
    _add_header('X-Content-Security-Policy', $content_security_policy, $res);
    if ($ie_settings) {
        _add_header('X-Content-Type-Options', $ie_content_type, $res);
        _add_header('X-Download-Options', $ie_download_options, $res);
        _add_header('X-XSS-Protection', $ie_xss_protection, $res);
    }

};

sub _add_header {
    my $key = shift;
    my $value = shift;
    my $res = shift;

    unless ($res->header($key)) {
        $res->header($key, $value);
    }
}

=head1 AUTHOR

Ewen, Colin, C<< <colin at draecas.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-secureheaders at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-SecureHeaders>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::SecureHeaders


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-SecureHeaders>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-SecureHeaders>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-SecureHeaders>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-SecureHeaders/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Ewen, Colin.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

register_plugin;

1;
