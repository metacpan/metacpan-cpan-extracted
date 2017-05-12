package DateTime::Event::Jewish::Sedrah;
use strict;
use warnings;
use base qw(Exporter);
use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(@sedrah);
our $VERSION = '0.01';

# (C) Raphael Mankin 2009
our @sedrah= (
    "",			# 0
    "Bereishit",
    "Noach",
    "Lech Lecha",
    "Vayeira",
    "Chayei Sarah",
    "Toldot",
    "Vayeitzei",
    "Vayishlach",
    "Vayeishev",
    "Mikeitz",		#10
    "Vayigash",
    "Vayechi",
    "Shemot",
    "Va'eira",
    "Bo",
    "Beshalach",
    "Yitro",
    "Mishpatim",
    "Terumah",
    "Tetzaveh",		# 20
    "Ki Tisa",
    "Vayakhel",		# 22
    "Pekudei",
    "Vayikra",
    "Tzav",
    "Shemini",
    "Tazria",		# 27
    "Metzora",
    "Acharei Mot",	# 29
    "Kedoshim",		# 30
    "Emor",
    "Behar",		# 32
    "Bechukotai",
    "Bemidbar",
    "Nasso",
    "Beha'alotcha",
    "Shelach",
    "Korach",
    "Chukat",		# 39
    "Balak",		# 40
    "Pinchas",
    "Mattot",		# 42
    "Masei",
    "Devarim",
    "Va'etchanan",
    "Eikev",
    "Re'eh",
    "Shoftim",
    "Ki Teitzei",
    "Ki Tavo",		# 50
    "Nitzavim",		# 51
    "Vayeilech",
    "Haazinu",
    "Vezot HaBerachah",
    "Undefined 55",
    "Undefined 56",
);
1;

=head1 NAME

Sedrah.pm - List of sidrot for the year

=head1 SYNOPSIS

 use DateTime::Event::Jewish::Sedrah qw(@sedrah);

=head1 DESCRIPTION

This module contains just a list of sidrot for the year. It is
factored ot so that it can easily be used in other modules.

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

1; # End of DateTime::Event::Sedrah
