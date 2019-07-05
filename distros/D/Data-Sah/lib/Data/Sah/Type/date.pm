package Data::Sah::Type::date;

our $DATE = '2019-07-04'; # DATE
our $VERSION = '0.896'; # VERSION

use Data::Sah::Util::Role 'has_clause';
use Role::Tiny;
use Role::Tiny::With;

with 'Data::Sah::Type::BaseType';
with 'Data::Sah::Type::Comparable';
with 'Data::Sah::Type::Sortable';

# XXX prop: year
# XXX prop: quarter (1-4)
# XXX prop: month
# XXX prop: day
# XXX prop: day_of_month
# XXX prop: hour
# XXX prop: minute
# XXX prop: second
# XXX prop: millisecond
# XXX prop: microsecond
# XXX prop: nanosecond
# XXX prop: day_of_week
# XXX prop: day_of_quarter
# XXX prop: day_of_year
# XXX prop: week_of_month
# XXX prop: week_of_year
# XXX prop: date?
# XXX prop: time?
# XXX prop: time_zone_long_name
# XXX prop: time_zone_offset
# XXX prop: is_leap_year

1;
# ABSTRACT: date type

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Type::date - date type

=head1 VERSION

This document describes version 0.896 of Data::Sah::Type::date (from Perl distribution Data-Sah), released on 2019-07-04.

=for Pod::Coverage ^(clause_.+|clausemeta_.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
