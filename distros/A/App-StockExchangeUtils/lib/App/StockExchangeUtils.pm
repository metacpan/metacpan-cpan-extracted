package App::StockExchangeUtils;

our $DATE = '2018-09-19'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Finance::SE::Catalog ();
use Perinci::Sub::Gen::AccessTable;

our %SPEC;

my $res = Perinci::Sub::Gen::AccessTable::gen_read_table_func(
    name => 'list_stock_exchanges',
    table_data => $Finance::SE::Catalog::data,
    table_spec => $Finance::SE::Catalog::meta,
);
die "Can't generate list_stock_exchanges(): $res->[0] - $res->[1]"
    unless $res->[0] == 200;

1;
# ABSTRACT: Command-line utilities related to stock exchanges

__END__

=pod

=encoding UTF-8

=head1 NAME

App::StockExchangeUtils - Command-line utilities related to stock exchanges

=head1 VERSION

This document describes version 0.001 of App::StockExchangeUtils (from Perl distribution App-StockExchangeUtils), released on 2018-09-19.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to stock exchanges:

=over

=item * L<list-stock-exchanges>

=back

=head1 FUNCTIONS


=head2 list_stock_exchanges

Usage:

 list_stock_exchanges(%args) -> [status, msg, result, meta]

Catalog (list) of stock exchanges.

REPLACE ME

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<add_codes> => I<str>

Only return records where the 'add_codes' field equals specified value.

=item * B<add_codes.contains> => I<str>

Only return records where the 'add_codes' field contains specified text.

=item * B<add_codes.in> => I<array[str]>

Only return records where the 'add_codes' field is in the specified values.

=item * B<add_codes.is> => I<str>

Only return records where the 'add_codes' field equals specified value.

=item * B<add_codes.isnt> => I<str>

Only return records where the 'add_codes' field does not equal specified value.

=item * B<add_codes.max> => I<str>

Only return records where the 'add_codes' field is less than or equal to specified value.

=item * B<add_codes.min> => I<str>

Only return records where the 'add_codes' field is greater than or equal to specified value.

=item * B<add_codes.not_contains> => I<str>

Only return records where the 'add_codes' field does not contain specified text.

=item * B<add_codes.not_in> => I<array[str]>

Only return records where the 'add_codes' field is not in the specified values.

=item * B<add_codes.xmax> => I<str>

Only return records where the 'add_codes' field is less than specified value.

=item * B<add_codes.xmin> => I<str>

Only return records where the 'add_codes' field is greater than specified value.

=item * B<add_names> => I<str>

Only return records where the 'add_names' field equals specified value.

=item * B<add_names.contains> => I<str>

Only return records where the 'add_names' field contains specified text.

=item * B<add_names.in> => I<array[str]>

Only return records where the 'add_names' field is in the specified values.

=item * B<add_names.is> => I<str>

Only return records where the 'add_names' field equals specified value.

=item * B<add_names.isnt> => I<str>

Only return records where the 'add_names' field does not equal specified value.

=item * B<add_names.max> => I<str>

Only return records where the 'add_names' field is less than or equal to specified value.

=item * B<add_names.min> => I<str>

Only return records where the 'add_names' field is greater than or equal to specified value.

=item * B<add_names.not_contains> => I<str>

Only return records where the 'add_names' field does not contain specified text.

=item * B<add_names.not_in> => I<array[str]>

Only return records where the 'add_names' field is not in the specified values.

=item * B<add_names.xmax> => I<str>

Only return records where the 'add_names' field is less than specified value.

=item * B<add_names.xmin> => I<str>

Only return records where the 'add_names' field is greater than specified value.

=item * B<add_yf_codes> => I<str>

Only return records where the 'add_yf_codes' field equals specified value.

=item * B<add_yf_codes.contains> => I<str>

Only return records where the 'add_yf_codes' field contains specified text.

=item * B<add_yf_codes.in> => I<array[str]>

Only return records where the 'add_yf_codes' field is in the specified values.

=item * B<add_yf_codes.is> => I<str>

Only return records where the 'add_yf_codes' field equals specified value.

=item * B<add_yf_codes.isnt> => I<str>

Only return records where the 'add_yf_codes' field does not equal specified value.

=item * B<add_yf_codes.max> => I<str>

Only return records where the 'add_yf_codes' field is less than or equal to specified value.

=item * B<add_yf_codes.min> => I<str>

Only return records where the 'add_yf_codes' field is greater than or equal to specified value.

=item * B<add_yf_codes.not_contains> => I<str>

Only return records where the 'add_yf_codes' field does not contain specified text.

=item * B<add_yf_codes.not_in> => I<array[str]>

Only return records where the 'add_yf_codes' field is not in the specified values.

=item * B<add_yf_codes.xmax> => I<str>

Only return records where the 'add_yf_codes' field is less than specified value.

=item * B<add_yf_codes.xmin> => I<str>

Only return records where the 'add_yf_codes' field is greater than specified value.

=item * B<city> => I<str>

Only return records where the 'city' field equals specified value.

=item * B<city.contains> => I<str>

Only return records where the 'city' field contains specified text.

=item * B<city.in> => I<array[str]>

Only return records where the 'city' field is in the specified values.

=item * B<city.is> => I<str>

Only return records where the 'city' field equals specified value.

=item * B<city.isnt> => I<str>

Only return records where the 'city' field does not equal specified value.

=item * B<city.max> => I<str>

Only return records where the 'city' field is less than or equal to specified value.

=item * B<city.min> => I<str>

Only return records where the 'city' field is greater than or equal to specified value.

=item * B<city.not_contains> => I<str>

Only return records where the 'city' field does not contain specified text.

=item * B<city.not_in> => I<array[str]>

Only return records where the 'city' field is not in the specified values.

=item * B<city.xmax> => I<str>

Only return records where the 'city' field is less than specified value.

=item * B<city.xmin> => I<str>

Only return records where the 'city' field is greater than specified value.

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

=item * B<country> => I<str>

Only return records where the 'country' field equals specified value.

=item * B<country.contains> => I<str>

Only return records where the 'country' field contains specified text.

=item * B<country.in> => I<array[str]>

Only return records where the 'country' field is in the specified values.

=item * B<country.is> => I<str>

Only return records where the 'country' field equals specified value.

=item * B<country.isnt> => I<str>

Only return records where the 'country' field does not equal specified value.

=item * B<country.max> => I<str>

Only return records where the 'country' field is less than or equal to specified value.

=item * B<country.min> => I<str>

Only return records where the 'country' field is greater than or equal to specified value.

=item * B<country.not_contains> => I<str>

Only return records where the 'country' field does not contain specified text.

=item * B<country.not_in> => I<array[str]>

Only return records where the 'country' field is not in the specified values.

=item * B<country.xmax> => I<str>

Only return records where the 'country' field is less than specified value.

=item * B<country.xmin> => I<str>

Only return records where the 'country' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<eng_name> => I<str>

Only return records where the 'eng_name' field equals specified value.

=item * B<eng_name.contains> => I<str>

Only return records where the 'eng_name' field contains specified text.

=item * B<eng_name.in> => I<array[str]>

Only return records where the 'eng_name' field is in the specified values.

=item * B<eng_name.is> => I<str>

Only return records where the 'eng_name' field equals specified value.

=item * B<eng_name.isnt> => I<str>

Only return records where the 'eng_name' field does not equal specified value.

=item * B<eng_name.max> => I<str>

Only return records where the 'eng_name' field is less than or equal to specified value.

=item * B<eng_name.min> => I<str>

Only return records where the 'eng_name' field is greater than or equal to specified value.

=item * B<eng_name.not_contains> => I<str>

Only return records where the 'eng_name' field does not contain specified text.

=item * B<eng_name.not_in> => I<array[str]>

Only return records where the 'eng_name' field is not in the specified values.

=item * B<eng_name.xmax> => I<str>

Only return records where the 'eng_name' field is less than specified value.

=item * B<eng_name.xmin> => I<str>

Only return records where the 'eng_name' field is greater than specified value.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<founded> => I<str>

Only return records where the 'founded' field equals specified value.

=item * B<founded.contains> => I<str>

Only return records where the 'founded' field contains specified text.

=item * B<founded.in> => I<array[str]>

Only return records where the 'founded' field is in the specified values.

=item * B<founded.is> => I<str>

Only return records where the 'founded' field equals specified value.

=item * B<founded.isnt> => I<str>

Only return records where the 'founded' field does not equal specified value.

=item * B<founded.max> => I<str>

Only return records where the 'founded' field is less than or equal to specified value.

=item * B<founded.min> => I<str>

Only return records where the 'founded' field is greater than or equal to specified value.

=item * B<founded.not_contains> => I<str>

Only return records where the 'founded' field does not contain specified text.

=item * B<founded.not_in> => I<array[str]>

Only return records where the 'founded' field is not in the specified values.

=item * B<founded.xmax> => I<str>

Only return records where the 'founded' field is less than specified value.

=item * B<founded.xmin> => I<str>

Only return records where the 'founded' field is greater than specified value.

=item * B<local_name> => I<str>

Only return records where the 'local_name' field equals specified value.

=item * B<local_name.contains> => I<str>

Only return records where the 'local_name' field contains specified text.

=item * B<local_name.in> => I<array[str]>

Only return records where the 'local_name' field is in the specified values.

=item * B<local_name.is> => I<str>

Only return records where the 'local_name' field equals specified value.

=item * B<local_name.isnt> => I<str>

Only return records where the 'local_name' field does not equal specified value.

=item * B<local_name.max> => I<str>

Only return records where the 'local_name' field is less than or equal to specified value.

=item * B<local_name.min> => I<str>

Only return records where the 'local_name' field is greater than or equal to specified value.

=item * B<local_name.not_contains> => I<str>

Only return records where the 'local_name' field does not contain specified text.

=item * B<local_name.not_in> => I<array[str]>

Only return records where the 'local_name' field is not in the specified values.

=item * B<local_name.xmax> => I<str>

Only return records where the 'local_name' field is less than specified value.

=item * B<local_name.xmin> => I<str>

Only return records where the 'local_name' field is greater than specified value.

=item * B<mic> => I<str>

Only return records where the 'mic' field equals specified value.

=item * B<mic.contains> => I<str>

Only return records where the 'mic' field contains specified text.

=item * B<mic.in> => I<array[str]>

Only return records where the 'mic' field is in the specified values.

=item * B<mic.is> => I<str>

Only return records where the 'mic' field equals specified value.

=item * B<mic.isnt> => I<str>

Only return records where the 'mic' field does not equal specified value.

=item * B<mic.max> => I<str>

Only return records where the 'mic' field is less than or equal to specified value.

=item * B<mic.min> => I<str>

Only return records where the 'mic' field is greater than or equal to specified value.

=item * B<mic.not_contains> => I<str>

Only return records where the 'mic' field does not contain specified text.

=item * B<mic.not_in> => I<array[str]>

Only return records where the 'mic' field is not in the specified values.

=item * B<mic.xmax> => I<str>

Only return records where the 'mic' field is less than specified value.

=item * B<mic.xmin> => I<str>

Only return records where the 'mic' field is greater than specified value.

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

=item * B<status> => I<str>

Only return records where the 'status' field equals specified value.

=item * B<status.contains> => I<str>

Only return records where the 'status' field contains specified text.

=item * B<status.in> => I<array[str]>

Only return records where the 'status' field is in the specified values.

=item * B<status.is> => I<str>

Only return records where the 'status' field equals specified value.

=item * B<status.isnt> => I<str>

Only return records where the 'status' field does not equal specified value.

=item * B<status.max> => I<str>

Only return records where the 'status' field is less than or equal to specified value.

=item * B<status.min> => I<str>

Only return records where the 'status' field is greater than or equal to specified value.

=item * B<status.not_contains> => I<str>

Only return records where the 'status' field does not contain specified text.

=item * B<status.not_in> => I<array[str]>

Only return records where the 'status' field is not in the specified values.

=item * B<status.xmax> => I<str>

Only return records where the 'status' field is less than specified value.

=item * B<status.xmin> => I<str>

Only return records where the 'status' field is greater than specified value.

=item * B<types> => I<str>

Only return records where the 'types' field equals specified value.

=item * B<types.contains> => I<str>

Only return records where the 'types' field contains specified text.

=item * B<types.in> => I<array[str]>

Only return records where the 'types' field is in the specified values.

=item * B<types.is> => I<str>

Only return records where the 'types' field equals specified value.

=item * B<types.isnt> => I<str>

Only return records where the 'types' field does not equal specified value.

=item * B<types.max> => I<str>

Only return records where the 'types' field is less than or equal to specified value.

=item * B<types.min> => I<str>

Only return records where the 'types' field is greater than or equal to specified value.

=item * B<types.not_contains> => I<str>

Only return records where the 'types' field does not contain specified text.

=item * B<types.not_in> => I<array[str]>

Only return records where the 'types' field is not in the specified values.

=item * B<types.xmax> => I<str>

Only return records where the 'types' field is less than specified value.

=item * B<types.xmin> => I<str>

Only return records where the 'types' field is greater than specified value.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hash/associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).

=item * B<yf_code> => I<str>

Only return records where the 'yf_code' field equals specified value.

=item * B<yf_code.contains> => I<str>

Only return records where the 'yf_code' field contains specified text.

=item * B<yf_code.in> => I<array[str]>

Only return records where the 'yf_code' field is in the specified values.

=item * B<yf_code.is> => I<str>

Only return records where the 'yf_code' field equals specified value.

=item * B<yf_code.isnt> => I<str>

Only return records where the 'yf_code' field does not equal specified value.

=item * B<yf_code.max> => I<str>

Only return records where the 'yf_code' field is less than or equal to specified value.

=item * B<yf_code.min> => I<str>

Only return records where the 'yf_code' field is greater than or equal to specified value.

=item * B<yf_code.not_contains> => I<str>

Only return records where the 'yf_code' field does not contain specified text.

=item * B<yf_code.not_in> => I<array[str]>

Only return records where the 'yf_code' field is not in the specified values.

=item * B<yf_code.xmax> => I<str>

Only return records where the 'yf_code' field is less than specified value.

=item * B<yf_code.xmin> => I<str>

Only return records where the 'yf_code' field is greater than specified value.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-StockExchangeUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-StockExchangeUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-StockExchangeUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
