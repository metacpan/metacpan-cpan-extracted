package DateTime::Event::Jewish;

use warnings;
use strict;

=head1 NAME

DateTime::Event::Jewish - Claculate leyning and Shabbat times

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';


=head1 SYNOPSIS

This module is not intended to be used directly. Instead you
should use either the Sunrise of Parshah sub-modules.


    use DateTime::Event::Jewish::Sunrise :
    use DateTime::Event::Jewish::Parshah qw(nextShabbat parshah);

DateTime::Event::Jewish::Sunrise is an OO module that provides functions for
calculating interesting halachic times. See the pod in that
module for mmore information.

DateTime::Event::Jewish::Parshah calculates the leyning for a
given Gregorian date. See the pod in that module for more
information.


=head1 AUTHOR

Raphael Mankin, C<< <rapmankin at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-datetime-event-jewish at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DateTime-Event-Jewish>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DateTime::Event::Jewish


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Event-Jewish>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DateTime-Event-Jewish>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DateTime-Event-Jewish>

=item * Search CPAN

L<http://search.cpan.org/dist/DateTime-Event-Jewish/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Raphael Mankin.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of DateTime::Event::Jewish
