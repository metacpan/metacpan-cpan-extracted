package Acme::Stardate;

use warnings;
use strict;

=head1 NAME

Acme::Stardate - Provide a simple 'stardate' string

=head1 VERSION

Version 20081029.16083

=cut

our $VERSION = '20081112.31792';

=head1 SYNOPSIS

    use Acme::Stardate;

    my $t = stardate();

or from a command line

    stardate

=head1 ABSTRACT

The Star Trek TV series started each episode with the stardate.  Never mind that
they don't make any sense.  This module gives you a stardate of your very own.
A stardate might be used as a version number.

=head1 EXPORT

stardate

=cut

use Exporter 'import';
our @EXPORT = qw(stardate);

=head1 FUNCTIONS

=head2 stardate

Returns a string yyyymmdd.fffff where yyyy is the four digit year, mm
is the two digit month, dd is the two digit day of the month and .fffff
is the 5 digit fraction of the current day.  All times are GMT.

=cut

use POSIX 'strftime';

sub stardate {
    strftime("%Y%m%d.", gmtime). int(time%86400/86400 * 100000)
}


=head1 AUTHOR

Chris Fedde, C<< <cfedde at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-stardate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Stardate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Stardate

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Stardate>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Stardate>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Stardate>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Stardate>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Chris Fedde, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Acme::Stardate
