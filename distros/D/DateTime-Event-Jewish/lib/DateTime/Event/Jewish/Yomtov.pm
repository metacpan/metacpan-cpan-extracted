package DateTime::Event::Jewish::Yomtov;
use strict;
use warnings;
use base qw(Exporter);
use vars qw(@EXPORT_OK @festival);
@EXPORT_OK = qw(@festival);
our $VERSION = '0.01';
# Yom Tov or Chol HaMoed
# Only dates that affect leyning are listed.
# Format is [Name, Day, Month, diasporaFlag]
our @festival = (
	["Rosh Hashanah 1", 1, 7],
	["Rosh Hashanah 2", 2, 7],
	["Yom Kippur", 10, 7],
	["Succot 1", 15, 7],
	["Succot 2", 16, 7 ],
	["Succot 3", 17, 7],
	["Succot 4", 18, 7],
	["Succot 5", 19, 7],
	["Succot 6", 20, 7],
	["Succot 7", 21, 7],
	["Shemini Atzeret", 22, 7],
	["Simchat Torah", 23, 7, 1],
	# ["Chanukkah", 25, 9],
	# ["10 Tevet", 10, 10],
	# ["Tu Bishvat", 15, 11],
	# ["Purim", 14, -1],
	["Pesach 1", 15, 1],
	["Pesach 2", 16, 1],
	["Pesach 3", 17, 1],
	["Pesach 4", 18, 1],
	["Pesach 5", 19, 1],
	["Pesach 6", 20, 1],
	["Pesach 7", 21, 1],
	["Pesach 8", 22, 1, 1],
	["Shavuot 1", 6, 3],
	["Shavuot 2", 7, 3, 1],
	# ["17 Tammuz", 17,4],
	# ["9 Av", 9, 5],
);

1;

=head1 NAME

DateTime::Event::Jewish::Yomtov - list of festivals

=head1 SYNOPSIS

 use DateTime::Event::Jewish::Yomtov qw(@festival);

=head1 DESCRIPTION

This module exports a list of festival dates as an array of
arrayrefs. Each array element is of the form
	[ name, dayOfMonth, monthNumber, diasporaFlag ]
Bear in mind that Nissan is month 1 and Tishrei is month 7.

Only festivals that affect Shabbat leyning are listed, so Purim,
Chanukkah, 10 Tevet etc. are not in the list.

The diasporaFlag is non-zero for those festivals that apply
only outside Israel.

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

1; # End of DateTime::Event::YomTov
