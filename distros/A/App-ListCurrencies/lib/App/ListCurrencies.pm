package App::ListCurrencies;

our $DATE = '2019-09-28'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);

our %SPEC;
use Exporter qw(import);
our @EXPORT_OK = qw(list_languages);

our $data;
{
    require Locale::Codes::Currency_Codes;
    $data = [];
    my $id2names  = $Locale::Codes::Data{'currency'}{'id2names'};
    my $id2alpha  = $Locale::Codes::Data{'currency'}{'id2code'}{'alpha'};

    for my $id (keys %$id2names) {
        push @$data, [$id2alpha->{$id}, $id2names->{$id}[0]];
    }

    $data = [sort {$a->[0] cmp $b->[0]} @$data];
}

my $res = gen_read_table_func(
    name => 'list_currencies',
    summary => 'List currencies',
    table_data => $data,
    table_spec => {
        summary => 'List of currencies',
        fields => {
            alpha => {
                summary => 'ISO 4217 alpha code',
                schema => 'str*',
                pos => 0,
                sortable => 1,
            },
            en_name => {
                summary => 'English name',
                schema => 'str*',
                pos => 1,
                sortable => 1,
            },
        },
        pk => 'alpha',
    },
    description => <<'_',

Source data is generated from `Locale::Codes::Currency_Codes`. so make sure you
have a relatively recent version of the module.

_
    extra_props => {
        examples => [
            {
                args => {query=>'rup'},
                test => 0,
            },
            {
                args => {query=>'rup', detail=>1},
                test => 0,
            },
        ],
    },
);
die "Can't generate function: $res->[0] - $res->[1]" unless $res->[0] == 200;

1;
# ABSTRACT: List currencies

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ListCurrencies - List currencies

=head1 VERSION

This document describes version 0.004 of App::ListCurrencies (from Perl distribution App-ListCurrencies), released on 2019-09-28.

=head1 SYNOPSIS

 # Use via list-currencies CLI script

=head1 FUNCTIONS


=head2 list_currencies

Usage:

 list_currencies(%args) -> [status, msg, payload, meta]

List currencies.

Examples:

=over

=item * Example #1:

 list_currencies(query => "rup"); # -> ["IDR", "INR", "LKR", "MUR", "NPR", "PKR", "SCR"]

=item * Example #2:

 list_currencies(query => "rup", detail => 1);

Result:

 [
   { alpha => "IDR", en_name => "Rupiah" },
   { alpha => "INR", en_name => "Indian Rupee" },
   { alpha => "LKR", en_name => "Sri Lanka Rupee" },
   { alpha => "MUR", en_name => "Mauritius Rupee" },
   { alpha => "NPR", en_name => "Nepalese Rupee" },
   { alpha => "PKR", en_name => "Pakistan Rupee" },
   { alpha => "SCR", en_name => "Seychelles Rupee" },
 ]

=back

Source data is generated from C<Locale::Codes::Currency_Codes>. so make sure you
have a relatively recent version of the module.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<alpha> => I<str>

Only return records where the 'alpha' field equals specified value.

=item * B<alpha.contains> => I<str>

Only return records where the 'alpha' field contains specified text.

=item * B<alpha.in> => I<array[str]>

Only return records where the 'alpha' field is in the specified values.

=item * B<alpha.is> => I<str>

Only return records where the 'alpha' field equals specified value.

=item * B<alpha.isnt> => I<str>

Only return records where the 'alpha' field does not equal specified value.

=item * B<alpha.max> => I<str>

Only return records where the 'alpha' field is less than or equal to specified value.

=item * B<alpha.min> => I<str>

Only return records where the 'alpha' field is greater than or equal to specified value.

=item * B<alpha.not_contains> => I<str>

Only return records where the 'alpha' field does not contain specified text.

=item * B<alpha.not_in> => I<array[str]>

Only return records where the 'alpha' field is not in the specified values.

=item * B<alpha.xmax> => I<str>

Only return records where the 'alpha' field is less than specified value.

=item * B<alpha.xmin> => I<str>

Only return records where the 'alpha' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<en_name> => I<str>

Only return records where the 'en_name' field equals specified value.

=item * B<en_name.contains> => I<str>

Only return records where the 'en_name' field contains specified text.

=item * B<en_name.in> => I<array[str]>

Only return records where the 'en_name' field is in the specified values.

=item * B<en_name.is> => I<str>

Only return records where the 'en_name' field equals specified value.

=item * B<en_name.isnt> => I<str>

Only return records where the 'en_name' field does not equal specified value.

=item * B<en_name.max> => I<str>

Only return records where the 'en_name' field is less than or equal to specified value.

=item * B<en_name.min> => I<str>

Only return records where the 'en_name' field is greater than or equal to specified value.

=item * B<en_name.not_contains> => I<str>

Only return records where the 'en_name' field does not contain specified text.

=item * B<en_name.not_in> => I<array[str]>

Only return records where the 'en_name' field is not in the specified values.

=item * B<en_name.xmax> => I<str>

Only return records where the 'en_name' field is less than specified value.

=item * B<en_name.xmin> => I<str>

Only return records where the 'en_name' field is greater than specified value.

=item * B<fields> => I<array[str]>

Select fields to return.

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

Return field names in each record (as hash/associative array).

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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ListCurrencies>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ListCurrencies>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ListCurrencies>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Locale::Codes>

L<list-countries> from L<App::ListCountries>

L<list-languages> from L<App::ListLanguages>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
