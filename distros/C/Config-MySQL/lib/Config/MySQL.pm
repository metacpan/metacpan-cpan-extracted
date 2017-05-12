package Config::MySQL;

use warnings;
use strict;

=head1 NAME

Config::MySQL - Read and write MySQL-style configuration files

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 DESCRIPTION

This module extends L<Config::INI> to support reading and writing MySQL-style
configuration files.  Although deceptively similar to standard C<.INI> files,
they can include bare boolean options with no value assignment and additional
features like C<!include> and C<!includedir>.

=head1 SEE ALSO

=over 4

=item L<Config::INI>

=item L<MySQL::Config>

=item L<Config::Extend::MySQL>

=back

=head1 AUTHOR

Iain Arnell, C<< <iarnell at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-config-ini-mysql at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Config-MySQL>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::MySQL

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Config-MySQL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-MySQL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Config-MySQL>

=item * Search CPAN

L<http://search.cpan.org/dist/Config-MySQL/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Ricardo Signes for Config-INI.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Iain Arnell.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Config::MySQL
