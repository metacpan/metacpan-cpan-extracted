package App::LocaleCodesUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-02'; # DATE
our $DIST = 'App-LocaleCodesUtils'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);

my $res;

$res = gen_read_table_func(
    name => 'list_currencies',
    summary => 'List currencies',
    table_data => sub {
        require Locale::Currency;
        my @codes = Locale::Currency::all_currency_codes();
        my @data;
        for (@codes) {
            push @data, [$_, Locale::Currency::code2currency($_)];
        }
        return { data=>\@data };
    },
    table_spec => {
        summary => 'List of currencies',
        fields => {
            code => {
                schema => 'str*',
                pos => 0,
                sortable => 1,
            },
            name => {
                schema => 'str*',
                pos => 1,
                sortable => 1,
            },
        },
        pk => 'code',
    },
);
die "Can't generate list_currencies(): $res->[0] - $res->[1]" unless $res->[0] == 200;

$res = gen_read_table_func(
    name => 'list_countries',
    summary => 'List countries',
    table_data => sub {
        require Locale::Country;
        my @alpha2s = Locale::Country::all_country_codes('alpha-2');
        my @data;
        for my $alpha2 (@alpha2s) {
            my $country = Locale::Country::code2country($alpha2, 'alpha-2');
            my $alpha3  = Locale::Country::country2code($country, 'alpha-3');
            push @data, [$alpha2, $country, $alpha3];
        }
        return { data=>\@data };
    },
    table_spec => {
        summary => 'List of countries',
        fields => {
            alpha2 => {
                schema => 'str*',
                pos => 0,
                sortable => 1,
            },
            name => {
                schema => 'str*',
                pos => 1,
                sortable => 1,
            },
            alpha3 => {
                schema => 'str*',
                pos => 2,
                sortable => 1,
            },
        },
        pk => 'alpha2',
    },
);
die "Can't generate list_countries(): $res->[0] - $res->[1]" unless $res->[0] == 200;

$res = gen_read_table_func(
    name => 'list_languages',
    summary => 'List languages',
    table_data => sub {
        require Locale::Language;
        my @alpha2s = Locale::Language::all_language_codes('alpha-2');
        my @data;
        for my $alpha2 (@alpha2s) {
            my $lang   = Locale::Language::code2language($alpha2, 'alpha-2');
            my $alpha3 = Locale::Language::language2code($lang, 'alpha-3');
            push @data, [$alpha2, $lang, $alpha3];
        }
        return { data=>\@data };
    },
    table_spec => {
        summary => 'List of languages',
        fields => {
            alpha2 => {
                schema => 'str*',
                pos => 0,
                sortable => 1,
            },
            name => {
                schema => 'str*',
                pos => 1,
                sortable => 1,
            },
            alpha3 => {
                schema => 'str*',
                pos => 2,
                sortable => 1,
            },
        },
        pk => 'alpha2',
    },
);
die "Can't generate list_languages(): $res->[0] - $res->[1]" unless $res->[0] == 200;

$res = gen_read_table_func(
    name => 'list_scripts',
    summary => 'List scripts',
    table_data => sub {
        require Locale::Script;
        my @codes = Locale::Script::all_script_codes();
        my @data;
        for (@codes) {
            push @data, [$_, Locale::Script::code2script($_)];
        }
        return { data=>\@data };
    },
    table_spec => {
        summary => 'List of scripts',
        fields => {
            code => {
                schema => 'str*',
                pos => 0,
                sortable => 1,
            },
            name => {
                schema => 'str*',
                pos => 1,
                sortable => 1,
            },
        },
        pk => 'code',
    },
);
die "Can't generate list_scripts(): $res->[0] - $res->[1]" unless $res->[0] == 200;

1;
# ABSTRACT: Utilities related to locale codes

__END__

=pod

=encoding UTF-8

=head1 NAME

App::LocaleCodesUtils - Utilities related to locale codes

=head1 VERSION

This document describes version 0.003 of App::LocaleCodesUtils (from Perl distribution App-LocaleCodesUtils), released on 2020-03-02.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<list-countries>

=item * L<list-currencies>

=item * L<list-languages>

=item * L<list-scripts>

=back

=head1 FUNCTIONS


=head2 list_countries

Usage:

 list_countries(%args) -> [status, msg, payload, meta]

List countries.

REPLACE ME

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<alpha2> => I<str>

Only return records where the 'alpha2' field equals specified value.

=item * B<alpha2.contains> => I<str>

Only return records where the 'alpha2' field contains specified text.

=item * B<alpha2.in> => I<array[str]>

Only return records where the 'alpha2' field is in the specified values.

=item * B<alpha2.is> => I<str>

Only return records where the 'alpha2' field equals specified value.

=item * B<alpha2.isnt> => I<str>

Only return records where the 'alpha2' field does not equal specified value.

=item * B<alpha2.max> => I<str>

Only return records where the 'alpha2' field is less than or equal to specified value.

=item * B<alpha2.min> => I<str>

Only return records where the 'alpha2' field is greater than or equal to specified value.

=item * B<alpha2.not_contains> => I<str>

Only return records where the 'alpha2' field does not contain specified text.

=item * B<alpha2.not_in> => I<array[str]>

Only return records where the 'alpha2' field is not in the specified values.

=item * B<alpha2.xmax> => I<str>

Only return records where the 'alpha2' field is less than specified value.

=item * B<alpha2.xmin> => I<str>

Only return records where the 'alpha2' field is greater than specified value.

=item * B<alpha3> => I<str>

Only return records where the 'alpha3' field equals specified value.

=item * B<alpha3.contains> => I<str>

Only return records where the 'alpha3' field contains specified text.

=item * B<alpha3.in> => I<array[str]>

Only return records where the 'alpha3' field is in the specified values.

=item * B<alpha3.is> => I<str>

Only return records where the 'alpha3' field equals specified value.

=item * B<alpha3.isnt> => I<str>

Only return records where the 'alpha3' field does not equal specified value.

=item * B<alpha3.max> => I<str>

Only return records where the 'alpha3' field is less than or equal to specified value.

=item * B<alpha3.min> => I<str>

Only return records where the 'alpha3' field is greater than or equal to specified value.

=item * B<alpha3.not_contains> => I<str>

Only return records where the 'alpha3' field does not contain specified text.

=item * B<alpha3.not_in> => I<array[str]>

Only return records where the 'alpha3' field is not in the specified values.

=item * B<alpha3.xmax> => I<str>

Only return records where the 'alpha3' field is less than specified value.

=item * B<alpha3.xmin> => I<str>

Only return records where the 'alpha3' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<name> => I<str>

Only return records where the 'name' field equals specified value.

=item * B<name.contains> => I<str>

Only return records where the 'name' field contains specified text.

=item * B<name.in> => I<array[str]>

Only return records where the 'name' field is in the specified values.

=item * B<name.is> => I<str>

Only return records where the 'name' field equals specified value.

=item * B<name.isnt> => I<str>

Only return records where the 'name' field does not equal specified value.

=item * B<name.max> => I<str>

Only return records where the 'name' field is less than or equal to specified value.

=item * B<name.min> => I<str>

Only return records where the 'name' field is greater than or equal to specified value.

=item * B<name.not_contains> => I<str>

Only return records where the 'name' field does not contain specified text.

=item * B<name.not_in> => I<array[str]>

Only return records where the 'name' field is not in the specified values.

=item * B<name.xmax> => I<str>

Only return records where the 'name' field is less than specified value.

=item * B<name.xmin> => I<str>

Only return records where the 'name' field is greater than specified value.

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

=item * B<with_field_names> => I<bool>

Return field names in each record (as hashE<sol>associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_currencies

Usage:

 list_currencies(%args) -> [status, msg, payload, meta]

List currencies.

REPLACE ME

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<code> => I<str>

Only return records where the 'code' field equals specified value.

=item * B<code.contains> => I<str>

Only return records where the 'code' field contains specified text.

=item * B<code.in> => I<array[str]>

Only return records where the 'code' field is in the specified values.

=item * B<code.is> => I<str>

Only return records where the 'code' field equals specified value.

=item * B<code.isnt> => I<str>

Only return records where the 'code' field does not equal specified value.

=item * B<code.max> => I<str>

Only return records where the 'code' field is less than or equal to specified value.

=item * B<code.min> => I<str>

Only return records where the 'code' field is greater than or equal to specified value.

=item * B<code.not_contains> => I<str>

Only return records where the 'code' field does not contain specified text.

=item * B<code.not_in> => I<array[str]>

Only return records where the 'code' field is not in the specified values.

=item * B<code.xmax> => I<str>

Only return records where the 'code' field is less than specified value.

=item * B<code.xmin> => I<str>

Only return records where the 'code' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<name> => I<str>

Only return records where the 'name' field equals specified value.

=item * B<name.contains> => I<str>

Only return records where the 'name' field contains specified text.

=item * B<name.in> => I<array[str]>

Only return records where the 'name' field is in the specified values.

=item * B<name.is> => I<str>

Only return records where the 'name' field equals specified value.

=item * B<name.isnt> => I<str>

Only return records where the 'name' field does not equal specified value.

=item * B<name.max> => I<str>

Only return records where the 'name' field is less than or equal to specified value.

=item * B<name.min> => I<str>

Only return records where the 'name' field is greater than or equal to specified value.

=item * B<name.not_contains> => I<str>

Only return records where the 'name' field does not contain specified text.

=item * B<name.not_in> => I<array[str]>

Only return records where the 'name' field is not in the specified values.

=item * B<name.xmax> => I<str>

Only return records where the 'name' field is less than specified value.

=item * B<name.xmin> => I<str>

Only return records where the 'name' field is greater than specified value.

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

=item * B<with_field_names> => I<bool>

Return field names in each record (as hashE<sol>associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_languages

Usage:

 list_languages(%args) -> [status, msg, payload, meta]

List languages.

REPLACE ME

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<alpha2> => I<str>

Only return records where the 'alpha2' field equals specified value.

=item * B<alpha2.contains> => I<str>

Only return records where the 'alpha2' field contains specified text.

=item * B<alpha2.in> => I<array[str]>

Only return records where the 'alpha2' field is in the specified values.

=item * B<alpha2.is> => I<str>

Only return records where the 'alpha2' field equals specified value.

=item * B<alpha2.isnt> => I<str>

Only return records where the 'alpha2' field does not equal specified value.

=item * B<alpha2.max> => I<str>

Only return records where the 'alpha2' field is less than or equal to specified value.

=item * B<alpha2.min> => I<str>

Only return records where the 'alpha2' field is greater than or equal to specified value.

=item * B<alpha2.not_contains> => I<str>

Only return records where the 'alpha2' field does not contain specified text.

=item * B<alpha2.not_in> => I<array[str]>

Only return records where the 'alpha2' field is not in the specified values.

=item * B<alpha2.xmax> => I<str>

Only return records where the 'alpha2' field is less than specified value.

=item * B<alpha2.xmin> => I<str>

Only return records where the 'alpha2' field is greater than specified value.

=item * B<alpha3> => I<str>

Only return records where the 'alpha3' field equals specified value.

=item * B<alpha3.contains> => I<str>

Only return records where the 'alpha3' field contains specified text.

=item * B<alpha3.in> => I<array[str]>

Only return records where the 'alpha3' field is in the specified values.

=item * B<alpha3.is> => I<str>

Only return records where the 'alpha3' field equals specified value.

=item * B<alpha3.isnt> => I<str>

Only return records where the 'alpha3' field does not equal specified value.

=item * B<alpha3.max> => I<str>

Only return records where the 'alpha3' field is less than or equal to specified value.

=item * B<alpha3.min> => I<str>

Only return records where the 'alpha3' field is greater than or equal to specified value.

=item * B<alpha3.not_contains> => I<str>

Only return records where the 'alpha3' field does not contain specified text.

=item * B<alpha3.not_in> => I<array[str]>

Only return records where the 'alpha3' field is not in the specified values.

=item * B<alpha3.xmax> => I<str>

Only return records where the 'alpha3' field is less than specified value.

=item * B<alpha3.xmin> => I<str>

Only return records where the 'alpha3' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<name> => I<str>

Only return records where the 'name' field equals specified value.

=item * B<name.contains> => I<str>

Only return records where the 'name' field contains specified text.

=item * B<name.in> => I<array[str]>

Only return records where the 'name' field is in the specified values.

=item * B<name.is> => I<str>

Only return records where the 'name' field equals specified value.

=item * B<name.isnt> => I<str>

Only return records where the 'name' field does not equal specified value.

=item * B<name.max> => I<str>

Only return records where the 'name' field is less than or equal to specified value.

=item * B<name.min> => I<str>

Only return records where the 'name' field is greater than or equal to specified value.

=item * B<name.not_contains> => I<str>

Only return records where the 'name' field does not contain specified text.

=item * B<name.not_in> => I<array[str]>

Only return records where the 'name' field is not in the specified values.

=item * B<name.xmax> => I<str>

Only return records where the 'name' field is less than specified value.

=item * B<name.xmin> => I<str>

Only return records where the 'name' field is greater than specified value.

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

=item * B<with_field_names> => I<bool>

Return field names in each record (as hashE<sol>associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_scripts

Usage:

 list_scripts(%args) -> [status, msg, payload, meta]

List scripts.

REPLACE ME

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<code> => I<str>

Only return records where the 'code' field equals specified value.

=item * B<code.contains> => I<str>

Only return records where the 'code' field contains specified text.

=item * B<code.in> => I<array[str]>

Only return records where the 'code' field is in the specified values.

=item * B<code.is> => I<str>

Only return records where the 'code' field equals specified value.

=item * B<code.isnt> => I<str>

Only return records where the 'code' field does not equal specified value.

=item * B<code.max> => I<str>

Only return records where the 'code' field is less than or equal to specified value.

=item * B<code.min> => I<str>

Only return records where the 'code' field is greater than or equal to specified value.

=item * B<code.not_contains> => I<str>

Only return records where the 'code' field does not contain specified text.

=item * B<code.not_in> => I<array[str]>

Only return records where the 'code' field is not in the specified values.

=item * B<code.xmax> => I<str>

Only return records where the 'code' field is less than specified value.

=item * B<code.xmin> => I<str>

Only return records where the 'code' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<name> => I<str>

Only return records where the 'name' field equals specified value.

=item * B<name.contains> => I<str>

Only return records where the 'name' field contains specified text.

=item * B<name.in> => I<array[str]>

Only return records where the 'name' field is in the specified values.

=item * B<name.is> => I<str>

Only return records where the 'name' field equals specified value.

=item * B<name.isnt> => I<str>

Only return records where the 'name' field does not equal specified value.

=item * B<name.max> => I<str>

Only return records where the 'name' field is less than or equal to specified value.

=item * B<name.min> => I<str>

Only return records where the 'name' field is greater than or equal to specified value.

=item * B<name.not_contains> => I<str>

Only return records where the 'name' field does not contain specified text.

=item * B<name.not_in> => I<array[str]>

Only return records where the 'name' field is not in the specified values.

=item * B<name.xmax> => I<str>

Only return records where the 'name' field is less than specified value.

=item * B<name.xmin> => I<str>

Only return records where the 'name' field is greater than specified value.

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

=item * B<with_field_names> => I<bool>

Return field names in each record (as hashE<sol>associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-LocaleCodesUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-LocaleCodesUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-LocaleCodesUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Locale::Codes>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
