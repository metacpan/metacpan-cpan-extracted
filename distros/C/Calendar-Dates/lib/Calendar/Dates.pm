package Calendar::Dates;

our $DATE = '2019-06-22'; # DATE
our $VERSION = '0.2.3'; # VERSION

1;
# ABSTRACT: Modules that contain calendar dates

__END__

=pod

=encoding UTF-8

=head1 NAME

Calendar::Dates - Modules that contain calendar dates

=head1 SPECIFICATION VERSION

0.1

=head1 VERSION

This document describes version 0.2.3 of Calendar::Dates (from Perl distribution Calendar-Dates), released on 2019-06-22.

=head1 DESCRIPTION

The C<Calendar::Dates::*> namespace is reserved for modules that provide
calendar dates using a common interface. The interface is designed to be: simple
to implement, lightweight, and easy to use and export (e.g. to an iCal
calendar).

Conventions for subdivision under the C<Calendar::Dates::> namespace:

=over

=item * Country-specific calendars go to <XX>::*, where <XX> is the ISO3166-1 2-letter country code

Examples:

  Calendar::Dates::SG::Events
  Calendar::Dates::SG::FestivalsEvents
  Calendar::Dates::ID::Tax

=item * Country-specific (public) holiday calendars go to <XX>::Holiday::*

Examples:

 Calendar::Dates::US::Holiday

=item * Region/province- and locality-specific calendars go to <CC>::<Name>::*

Examples:

 Calendar::Dates::ID::Jakarta::Events

=item * Year number can be added as the last component if the module only supports a specific year

Examples:

 Calendar::Dates::ID::Holiday::2019

=item * Religion-related calendars go to Religion::<Name>::*

Examples:

 Calendar::Dates::Religion::Christianity

=item * Sports-related calendars go to Sports::*

Examples:

 Calendar::Dates::Sports::WTA
 Calendar::Dates::Sports::WTA::2019
 Calendar::Dates::ID::Jakarta::Sports::Marathon

=back

=head1 STATUS

Draft series (0.x), expected to be stable in 1.0.

=head1 METHODS

=head2 get_min_year

Usage:

 my $min_year = Calendar::Dates::Foo->get_min_year;

Return the earliest year that the module has dates for. See also
L</get_max_year>. Note that the module might not support some years between the
earliest and latest years.

=head2 get_max_year

Usage:

 my $max_year = Calendar::Dates::Foo->get_max_year;

Return the latest year that the module has dates for. See also L</get_min_year>.
Note that the module might not support some years between the earliest and
latest years.

=head2 get_entries

Usage:

 my $entries = Calendar::Dates::Foo->get_entries([ \%params, ] $year [, $mon [, $day ] ]);

Return entries for a particular year (or month, or day). Method must die if year
(or month, or day) is not supported.

B<Parameters.> The optional C<%params> can be specified for more complex
querying/filtering. Each calendar module might support different parameters, and
should die if a parameter is unsupported. Currently known common/standardized
parameters:

=over

=item * all

Boolean. If set to true, will include all entries that are normally not
included, e.g. low-priority entries (entries with tag C<low-priority>).

=item * include_tags

Array. If set, then only entries which contain all tags mentioned in this
parameter should be included.

=item * exclude_tags

Array. If set, then entries which contain any of the tags mentioned in this
parameter should NOT be included.

=item * q

String. String/keyword matching. Only include entries that match this
keyword/string.

=back

B<Result.> Result is arrayref of entries, where each entry is a L<DefHash>. The
following keys are recognized, an asterisk (C<*>) signifies required key (see
L<DefHash> for more details on each key):

=over

=item * date*

String. Either ISO8601 date in the form of C<< YYYY-MM-DD >> or C<<
YYYY-MM-DD"T"HH:MM >>, or date interval in the form of C<<
YYYY-MM-DD"T"HH:MM/HH:MM >>.

Examples:

 2019-02-13
 2019-02-13T07:00
 2019-02-13T07:00/09:00

Interval that spans day is currently not allowed. You might want to create
separate entries for each day in the span.

Timezones are not currently allowed. Dates are assumed in the local time zone.

=item * year*

Integer. Year number (e.g. 2019).

=item * month*

Integer. Month number (1-12).

=item * day*

Integer. Day of month number (1-31).

=item * summary

From DefHash specification. Can be in English or another language, but providing
English version is recommended. To specify summary in other language, use
"summary.alt.lang.<LL>" keys.

=item * description

From DefHash specification. Can be in English or another language, but providing
English version is recommended. To specify description in other language, use
"description.alt.lang.<LL>" keys.

=item * tags

From DefHash specification. Some recommended/known tags: B<tentative>,
B<holiday>, B<religious>, B<low-priority> (entry with this tag by default should
not be returned by L</get_entries> unless it specifies a true C<all> option),
B<anniversary> (entry with this tag will repeat yearly and will be included in
every (later) year).

=item * url

URL.

=item * image_url

URL.

=item * is_holiday

Boolean. You can also use tag C<holiday> to mark an entry as a holiday.

=back

B<Optional parameters.> A hashref (parameters) can be specified as an optional
first argument. It can be used to specify in more details what kind of entries
are requested. For example, a Calendar::Dates::AU::Holiday module (Australian
holiday calendar) contains different holidays for different provinces. User can
specify:

 # return 2019 holiday dates for Victoria
 $entries = Calendar::Dates::AU::Holiday->get_entries({province=>'VIC'}, 2019);

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Calendar-Dates>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Calendar-Dates>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Calendar-Dates>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Related namespaces:

=over

=item * C<Calendar::DatesUtils>

This is namespace for modules that make use of C<Calendar::Dates::*> modules,
e.g. L<Calendar::DatesUtils::To::ICal>.

=item * C<Calendar::DatesRoles>

For roles related to Calendar::Dates.

=back

Related modules and applications:

=over

=item * L<App::CalendarDatesUtils>

which contain utilities like L<list-calendar-dates>, etc.

=item * L<calx> from L<App::calx>

Uses Calendar::Dates::* to highlight dates.

=back

Related projects:

=over

=item * L<Date::Holidays>

A long established project. Shares a similar goal with Calendar::Dates (to
provide a common interface for all Date::Holidays::* modules) but focuses on
holidays only.

=back

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
