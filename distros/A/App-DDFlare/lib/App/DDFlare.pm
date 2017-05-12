package App::DDFlare;

use v5.10;
use strict;
use warnings FATAL => 'all';

=head1 NAME

App::DDFlare - Dynamic DNS client for CloudFlare

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';


=head1 SYNOPSIS

Provides ddflare, a command line Dynamic DNS utility that updates with
the latest IP every 5 minutes. After installing the module you should
set up a start up service using your OS's favourite mechanism.

=head1 AUTHOR

Peter Roberts, C<< <me+dev at peter-r.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-ddflare at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App::DDFlare>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::DDFlare
    perldoc ddflare

You can also look for information at:

=over 4

=item * DDFlare

L<https://bitbucket.org/pwr22/ddflare>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-DDFlare>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-DDFlare>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-DDFlare>

=item * Search CPAN

L<http://search.cpan.org/dist/App-DDFlare/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Peter Roberts.

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

1; # End of App::DDFlare
