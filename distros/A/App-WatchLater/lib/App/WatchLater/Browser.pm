package App::WatchLater::Browser;

use 5.016;
use strict;
use warnings;

=head1 NAME

App::WatchLater::Browser - Open URLs in the User's Browser

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

This is a simple module for opening a URL in the user's browser, using
L<open(1)> on mac OS, L<xdg-open(1)> on Linux, and C<start> on Windows. Falls
back to the command specified by the C<BROWSER> environment variable, if set.

    use App::WatchLater::Browser;
    open_url('https://duckduckgo.com');
    ...

=head1 EXPORT

=over 4

=item *

C<open_url> - exported by default.

=back

=cut

use Carp;

BEGIN {
  require Exporter;
  our @ISA       = qw(Exporter);
  our @EXPORT    = qw(open_url);
  our @EXPORT_OK = qw(open_url);
}

sub _get_browser_name {
  return $ENV{BROWSER} if exists $ENV{BROWSER};
  for ($^O) {
    if (/MSWin32/ || /cygwin/) {
      return 'start';
    }
    if (/darwin/) {
      return 'open';
    }
    if (/linux/) {
      return 'xdg-open';
    }
    croak 'unsupported OS; try setting BROWSER environment variable';
  }
}

=head1 SUBROUTINES/METHODS

=head2 open_url

    open_url($url);

Does what it says on the tin. Croaks if unable to determine an appropriate browser.

=cut

sub open_url {
  my ($url) = @_;
  my $browser = _get_browser_name();
  system { $browser } $browser, $url;
}

=head1 AUTHOR

Aaron L. Zeng, C<< <me at bcc32.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-watchlater at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-WatchLater>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::WatchLater::Browser


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-WatchLater>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-WatchLater>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-WatchLater>

=item * Search CPAN

L<http://search.cpan.org/dist/App-WatchLater/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Aaron L. Zeng.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1;                              # End of App::WatchLater::Browser
