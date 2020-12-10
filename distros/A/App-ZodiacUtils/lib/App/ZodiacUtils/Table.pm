package App::ZodiacUtils::Table;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-09-14'; # DATE
our $DIST = 'App-ZodiacUtils'; # DIST
our $VERSION = '0.115'; # VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);
use Zodiac::Chinese::Table;

our %SPEC;

my $res = gen_read_table_func(
    name => 'list_chinese_zodiac_table',
    table_spec => $Zodiac::Chinese::Table::meta,
    table_data => $Zodiac::Chinese::Table::data,
);
$res->[0] == 200 or die "Can't generate list_chinese_zodiac_table(): $res->[0] - $res->[1]";

1;
# ABSTRACT: Zodiac table functions

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ZodiacUtils::Table - Zodiac table functions

=head1 VERSION

This document describes version 0.115 of App::ZodiacUtils::Table (from Perl distribution App-ZodiacUtils), released on 2020-09-14.

=head1 FUNCTIONS


=head2 list_chinese_zodiac_table

Usage:

 list_chinese_zodiac_table(%args) -> [status, msg, payload, meta]

Chinese zodiac.

REPLACE ME

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<earthly_branch> => I<str>

Only return records where the 'earthly_branch' field equals specified value.

=item * B<earthly_branch.contains> => I<str>

Only return records where the 'earthly_branch' field contains specified text.

=item * B<earthly_branch.in> => I<array[str]>

Only return records where the 'earthly_branch' field is in the specified values.

=item * B<earthly_branch.is> => I<str>

Only return records where the 'earthly_branch' field equals specified value.

=item * B<earthly_branch.isnt> => I<str>

Only return records where the 'earthly_branch' field does not equal specified value.

=item * B<earthly_branch.max> => I<str>

Only return records where the 'earthly_branch' field is less than or equal to specified value.

=item * B<earthly_branch.min> => I<str>

Only return records where the 'earthly_branch' field is greater than or equal to specified value.

=item * B<earthly_branch.not_contains> => I<str>

Only return records where the 'earthly_branch' field does not contain specified text.

=item * B<earthly_branch.not_in> => I<array[str]>

Only return records where the 'earthly_branch' field is not in the specified values.

=item * B<earthly_branch.xmax> => I<str>

Only return records where the 'earthly_branch' field is less than specified value.

=item * B<earthly_branch.xmin> => I<str>

Only return records where the 'earthly_branch' field is greater than specified value.

=item * B<element> => I<str>

Only return records where the 'element' field equals specified value.

=item * B<element.contains> => I<str>

Only return records where the 'element' field contains specified text.

=item * B<element.in> => I<array[str]>

Only return records where the 'element' field is in the specified values.

=item * B<element.is> => I<str>

Only return records where the 'element' field equals specified value.

=item * B<element.isnt> => I<str>

Only return records where the 'element' field does not equal specified value.

=item * B<element.max> => I<str>

Only return records where the 'element' field is less than or equal to specified value.

=item * B<element.min> => I<str>

Only return records where the 'element' field is greater than or equal to specified value.

=item * B<element.not_contains> => I<str>

Only return records where the 'element' field does not contain specified text.

=item * B<element.not_in> => I<array[str]>

Only return records where the 'element' field is not in the specified values.

=item * B<element.xmax> => I<str>

Only return records where the 'element' field is less than specified value.

=item * B<element.xmin> => I<str>

Only return records where the 'element' field is greater than specified value.

=item * B<en_animal> => I<str>

Only return records where the 'en_animal' field equals specified value.

=item * B<en_animal.contains> => I<str>

Only return records where the 'en_animal' field contains specified text.

=item * B<en_animal.in> => I<array[str]>

Only return records where the 'en_animal' field is in the specified values.

=item * B<en_animal.is> => I<str>

Only return records where the 'en_animal' field equals specified value.

=item * B<en_animal.isnt> => I<str>

Only return records where the 'en_animal' field does not equal specified value.

=item * B<en_animal.max> => I<str>

Only return records where the 'en_animal' field is less than or equal to specified value.

=item * B<en_animal.min> => I<str>

Only return records where the 'en_animal' field is greater than or equal to specified value.

=item * B<en_animal.not_contains> => I<str>

Only return records where the 'en_animal' field does not contain specified text.

=item * B<en_animal.not_in> => I<array[str]>

Only return records where the 'en_animal' field is not in the specified values.

=item * B<en_animal.xmax> => I<str>

Only return records where the 'en_animal' field is less than specified value.

=item * B<en_animal.xmin> => I<str>

Only return records where the 'en_animal' field is greater than specified value.

=item * B<end_date> => I<date>

Only return records where the 'end_date' field equals specified value.

=item * B<end_date.in> => I<array[date]>

Only return records where the 'end_date' field is in the specified values.

=item * B<end_date.is> => I<date>

Only return records where the 'end_date' field equals specified value.

=item * B<end_date.isnt> => I<date>

Only return records where the 'end_date' field does not equal specified value.

=item * B<end_date.max> => I<date>

Only return records where the 'end_date' field is less than or equal to specified value.

=item * B<end_date.min> => I<date>

Only return records where the 'end_date' field is greater than or equal to specified value.

=item * B<end_date.not_in> => I<array[date]>

Only return records where the 'end_date' field is not in the specified values.

=item * B<end_date.xmax> => I<date>

Only return records where the 'end_date' field is less than specified value.

=item * B<end_date.xmin> => I<date>

Only return records where the 'end_date' field is greater than specified value.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<heavenly_stem> => I<str>

Only return records where the 'heavenly_stem' field equals specified value.

=item * B<heavenly_stem.contains> => I<str>

Only return records where the 'heavenly_stem' field contains specified text.

=item * B<heavenly_stem.in> => I<array[str]>

Only return records where the 'heavenly_stem' field is in the specified values.

=item * B<heavenly_stem.is> => I<str>

Only return records where the 'heavenly_stem' field equals specified value.

=item * B<heavenly_stem.isnt> => I<str>

Only return records where the 'heavenly_stem' field does not equal specified value.

=item * B<heavenly_stem.max> => I<str>

Only return records where the 'heavenly_stem' field is less than or equal to specified value.

=item * B<heavenly_stem.min> => I<str>

Only return records where the 'heavenly_stem' field is greater than or equal to specified value.

=item * B<heavenly_stem.not_contains> => I<str>

Only return records where the 'heavenly_stem' field does not contain specified text.

=item * B<heavenly_stem.not_in> => I<array[str]>

Only return records where the 'heavenly_stem' field is not in the specified values.

=item * B<heavenly_stem.xmax> => I<str>

Only return records where the 'heavenly_stem' field is less than specified value.

=item * B<heavenly_stem.xmin> => I<str>

Only return records where the 'heavenly_stem' field is greater than specified value.

=item * B<query> => I<str>

Search.

=item * B<random> => I<bool> (default: 0)

Return records in random order.

=item * B<result_limit> => I<int>

Only return a certain number of records.

=item * B<result_start> => I<int> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<array[str]>

Order records according to certain field(s).

A list of field names separated by comma. Each field can be prefixed with '-' to
specify descending order instead of the default ascending.

=item * B<start_date> => I<date>

Only return records where the 'start_date' field equals specified value.

=item * B<start_date.in> => I<array[date]>

Only return records where the 'start_date' field is in the specified values.

=item * B<start_date.is> => I<date>

Only return records where the 'start_date' field equals specified value.

=item * B<start_date.isnt> => I<date>

Only return records where the 'start_date' field does not equal specified value.

=item * B<start_date.max> => I<date>

Only return records where the 'start_date' field is less than or equal to specified value.

=item * B<start_date.min> => I<date>

Only return records where the 'start_date' field is greater than or equal to specified value.

=item * B<start_date.not_in> => I<array[date]>

Only return records where the 'start_date' field is not in the specified values.

=item * B<start_date.xmax> => I<date>

Only return records where the 'start_date' field is less than specified value.

=item * B<start_date.xmin> => I<date>

Only return records where the 'start_date' field is greater than specified value.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hashE<sol>associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).

=item * B<yin_yang> => I<str>

Only return records where the 'yin_yang' field equals specified value.

=item * B<yin_yang.contains> => I<str>

Only return records where the 'yin_yang' field contains specified text.

=item * B<yin_yang.in> => I<array[str]>

Only return records where the 'yin_yang' field is in the specified values.

=item * B<yin_yang.is> => I<str>

Only return records where the 'yin_yang' field equals specified value.

=item * B<yin_yang.isnt> => I<str>

Only return records where the 'yin_yang' field does not equal specified value.

=item * B<yin_yang.max> => I<str>

Only return records where the 'yin_yang' field is less than or equal to specified value.

=item * B<yin_yang.min> => I<str>

Only return records where the 'yin_yang' field is greater than or equal to specified value.

=item * B<yin_yang.not_contains> => I<str>

Only return records where the 'yin_yang' field does not contain specified text.

=item * B<yin_yang.not_in> => I<array[str]>

Only return records where the 'yin_yang' field is not in the specified values.

=item * B<yin_yang.xmax> => I<str>

Only return records where the 'yin_yang' field is less than specified value.

=item * B<yin_yang.xmin> => I<str>

Only return records where the 'yin_yang' field is greater than specified value.

=item * B<zh_animal> => I<str>

Only return records where the 'zh_animal' field equals specified value.

=item * B<zh_animal.contains> => I<str>

Only return records where the 'zh_animal' field contains specified text.

=item * B<zh_animal.in> => I<array[str]>

Only return records where the 'zh_animal' field is in the specified values.

=item * B<zh_animal.is> => I<str>

Only return records where the 'zh_animal' field equals specified value.

=item * B<zh_animal.isnt> => I<str>

Only return records where the 'zh_animal' field does not equal specified value.

=item * B<zh_animal.max> => I<str>

Only return records where the 'zh_animal' field is less than or equal to specified value.

=item * B<zh_animal.min> => I<str>

Only return records where the 'zh_animal' field is greater than or equal to specified value.

=item * B<zh_animal.not_contains> => I<str>

Only return records where the 'zh_animal' field does not contain specified text.

=item * B<zh_animal.not_in> => I<array[str]>

Only return records where the 'zh_animal' field is not in the specified values.

=item * B<zh_animal.xmax> => I<str>

Only return records where the 'zh_animal' field is less than specified value.

=item * B<zh_animal.xmin> => I<str>

Only return records where the 'zh_animal' field is greater than specified value.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ZodiacUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ZodiacUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ZodiacUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
