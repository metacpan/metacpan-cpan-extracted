package App::KBLIUtils;

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-06-26'; # DATE
our $DIST = 'App-KBLIUtils'; # DIST
our $VERSION = '0.003'; # VERSION

our %SPEC;

my $res;

$res = gen_read_table_func(
    name => 'list_kbli_2020_codes',
    summary => 'List KBLI 2020 codes',
    table_data => do { require TableData::Business::ID::KBLI::2020::Code; TableData::Business::ID::KBLI::2020::Code->new },
);
die "Can't generate function: $res->[0] - $res->[1]" unless $res->[0] == 200;


$res = gen_read_table_func(
    name => 'list_kbli_2025_codes',
    summary => 'List KBLI 2025 codes',
    table_data => do { require TableData::Business::ID::KBLI::2025::Code; TableData::Business::ID::KBLI::2025::Code->new },
);
die "Can't generate function: $res->[0] - $res->[1]" unless $res->[0] == 200;

$SPEC{compare_kbli_2020_2025_codes} = {
    v => 1.1,
    summary => 'Compare codes in KBLI 2020 vs 2025',
    args => {
        codes => {
            schema => ['array*', of=>'str*', min_len=>1],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
    },
};
sub compare_kbli_2020_2025_codes {
    my %args = @_;
    my $codes = $args{codes}; $codes && @$codes or return [400, "Please specify one or more codes"];

    my $td_2020 = do { require TableData::Business::ID::KBLI::2020::Code; TableData::Business::ID::KBLI::2020::Code->new };
    my $td_2025 = do { require TableData::Business::ID::KBLI::2025::Code; TableData::Business::ID::KBLI::2025::Code->new };

    my $res = [200, "OK", [], {"table.fields"=>[qw/code status title_2020 title_2025 description_2020 description_2025/]}];

    my %rows_in_2020;
    my %rows_in_2025;
    $td_2020->each_item(sub { my ($row, $table, $index) = @_; if (grep { $_ == $row->[0] } @$codes) { $rows_in_2020{$row->[0]} = $row }; 1 });
    $td_2025->each_item(sub { my ($row, $table, $index) = @_; if (grep { $_ == $row->[0] } @$codes) { $rows_in_2025{$row->[0]} = $row }; 1 });

    #use DD; dd \%rows_in_2020; dd \%rows_in_2025;

    for my $code (@$codes) {
        my $row = {code => $code};
        if    (!$rows_in_2020{$code} && !$rows_in_2025{$code}) { $row->{status} = "UNKNOWN" }
        elsif ( $rows_in_2020{$code} &&  $rows_in_2025{$code}) { $row->{status} = "both exists" }
        elsif (!$rows_in_2020{$code} &&  $rows_in_2025{$code}) { $row->{status} = "NEW IN 2025" }
        elsif ( $rows_in_2020{$code} && !$rows_in_2025{$code}) { $row->{status} = "DELETED IN 2025" }

        if ($rows_in_2020{$code}) { $row->{title_2020} = $rows_in_2020{$code}[1]; $row->{description_2020} = $rows_in_2020{$code}[2] }
        if ($rows_in_2025{$code}) { $row->{title_2025} = $rows_in_2025{$code}[1]; $row->{description_2025} = $rows_in_2025{$code}[2] }

        push @{$res->[2]}, $row;
    }

    $res;
}

$SPEC{get_kbli_2020_title} = {
    v => 1.1,
    summary => 'Get title for a KBLI 2020 code',
    args => {
        code => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
};
sub get_kbli_2020_title {
    my %args = @_;
    my $code = $args{code}; $code or return [400, "Please specify one or more codes"];

    my $td = do { require TableData::Business::ID::KBLI::2020::Code; TableData::Business::ID::KBLI::2020::Code->new };

    my $title;
    $td->each_item(sub { my ($row, $table, $index) = @_; if ($code == $row->[0]) { $title = $row->[1]; 0 } else { 1 } });
    if ($title) { [200, "OK", $title] } else { [404, "Code not found"] }
}

$SPEC{get_kbli_2020_description} = {
    v => 1.1,
    summary => 'Get description for a KBLI 2020 code',
    args => {
        code => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
};
sub get_kbli_2020_description {
    my %args = @_;
    my $code = $args{code}; $code or return [400, "Please specify one or more codes"];

    my $td = do { require TableData::Business::ID::KBLI::2020::Code; TableData::Business::ID::KBLI::2020::Code->new };

    my $description;
    $td->each_item(sub { my ($row, $table, $index) = @_; if ($code == $row->[0]) { $description = $row->[2]; 0 } else { 1 } });
    if ($description) { [200, "OK", $description] } else { [404, "Code not found"] }
}

$SPEC{get_kbli_2025_title} = {
    v => 1.1,
    summary => 'Get title for a KBLI 2025 code',
    args => {
        code => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
};
sub get_kbli_2025_title {
    my %args = @_;
    my $code = $args{code}; $code or return [400, "Please specify one or more codes"];

    my $td = do { require TableData::Business::ID::KBLI::2025::Code; TableData::Business::ID::KBLI::2025::Code->new };

    my $title;
    $td->each_item(sub { my ($row, $table, $index) = @_; if ($code == $row->[0]) { $title = $row->[1]; 0 } else { 1 } });
    if ($title) { [200, "OK", $title] } else { [404, "Code not found"] }
}

$SPEC{get_kbli_2025_description} = {
    v => 1.1,
    summary => 'Get description for a KBLI 2025 code',
    args => {
        code => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
};
sub get_kbli_2025_description {
    my %args = @_;
    my $code = $args{code}; $code or return [400, "Please specify one or more codes"];

    my $td = do { require TableData::Business::ID::KBLI::2025::Code; TableData::Business::ID::KBLI::2025::Code->new };

    my $description;
    $td->each_item(sub { my ($row, $table, $index) = @_; if ($code == $row->[0]) { $description = $row->[2]; 0 } else { 1 } });
    if ($description) { [200, "OK", $description] } else { [404, "Code not found"] }
}

1;
# ABSTRACT: Utilities related to Indonesian KBLI ("Klasifikasi Baku Lapangan Usaha Indonesia" a.k.a. the Indonesian ISIC "International Standard Industrial Classification of All Economic Activities")

__END__

=pod

=encoding UTF-8

=head1 NAME

App::KBLIUtils - Utilities related to Indonesian KBLI ("Klasifikasi Baku Lapangan Usaha Indonesia" a.k.a. the Indonesian ISIC "International Standard Industrial Classification of All Economic Activities")

=head1 VERSION

This document describes version 0.003 of App::KBLIUtils (from Perl distribution App-KBLIUtils), released on 2026-06-26.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item 1. L<compare-kbli-2020-2025-codes>

=item 2. L<get-kbli-2020-description>

=item 3. L<get-kbli-2020-title>

=item 4. L<get-kbli-2025-description>

=item 5. L<get-kbli-2025-title>

=item 6. L<list-kbli-2020-codes>

=item 7. L<list-kbli-2025-codes>

=back

Keywords: KBLI, Klasifikasi Baku Lapangan Usaha Indonesia, ISIC, International Standard Industrial Classification of All Economic Activities

=head1 FUNCTIONS


=head2 compare_kbli_2020_2025_codes

Usage:

 compare_kbli_2020_2025_codes(%args) -> [$status_code, $reason, $payload, \%result_meta]

Compare codes in KBLI 2020 vs 2025.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<codes>* => I<array[str]>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 get_kbli_2020_description

Usage:

 get_kbli_2020_description(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get description for a KBLI 2020 code.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<code>* => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 get_kbli_2020_title

Usage:

 get_kbli_2020_title(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get title for a KBLI 2020 code.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<code>* => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 get_kbli_2025_description

Usage:

 get_kbli_2025_description(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get description for a KBLI 2025 code.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<code>* => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 get_kbli_2025_title

Usage:

 get_kbli_2025_title(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get title for a KBLI 2025 code.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<code>* => I<str>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_kbli_2020_codes

Usage:

 list_kbli_2020_codes(%args) -> [$status_code, $reason, $payload, \%result_meta]

List KBLI 2020 codes.

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

=item * B<description> => I<str>

Only return records where the 'description' field equals specified value.

=item * B<description.contains> => I<str>

Only return records where the 'description' field contains specified text.

=item * B<description.in> => I<array[str]>

Only return records where the 'description' field is in the specified values.

=item * B<description.is> => I<str>

Only return records where the 'description' field equals specified value.

=item * B<description.isnt> => I<str>

Only return records where the 'description' field does not equal specified value.

=item * B<description.max> => I<str>

Only return records where the 'description' field is less than or equal to specified value.

=item * B<description.min> => I<str>

Only return records where the 'description' field is greater than or equal to specified value.

=item * B<description.not_contains> => I<str>

Only return records where the 'description' field does not contain specified text.

=item * B<description.not_in> => I<array[str]>

Only return records where the 'description' field is not in the specified values.

=item * B<description.xmax> => I<str>

Only return records where the 'description' field is less than specified value.

=item * B<description.xmin> => I<str>

Only return records where the 'description' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<queries> => I<array[str]>

Search.

This will search all searchable fields with one or more specified queries. Each
query can be in the form of C<-FOO> (dash prefix notation) to require that the
fields do not contain specified string, or C</FOO/> to use regular expression.
All queries must match if the C<query_boolean> option is set to C<and>; only one
query should match if the C<query_boolean> option is set to C<or>.

=item * B<query_boolean> => I<str> (default: "and")

Whether records must match all search queries ('and') or just one ('or').

If set to C<and>, all queries must match; if set to C<or>, only one query should
match. See the C<queries> option for more details on searching.

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

=item * B<title> => I<str>

Only return records where the 'title' field equals specified value.

=item * B<title.contains> => I<str>

Only return records where the 'title' field contains specified text.

=item * B<title.in> => I<array[str]>

Only return records where the 'title' field is in the specified values.

=item * B<title.is> => I<str>

Only return records where the 'title' field equals specified value.

=item * B<title.isnt> => I<str>

Only return records where the 'title' field does not equal specified value.

=item * B<title.max> => I<str>

Only return records where the 'title' field is less than or equal to specified value.

=item * B<title.min> => I<str>

Only return records where the 'title' field is greater than or equal to specified value.

=item * B<title.not_contains> => I<str>

Only return records where the 'title' field does not contain specified text.

=item * B<title.not_in> => I<array[str]>

Only return records where the 'title' field is not in the specified values.

=item * B<title.xmax> => I<str>

Only return records where the 'title' field is less than specified value.

=item * B<title.xmin> => I<str>

Only return records where the 'title' field is greater than specified value.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hashE<sol>associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_kbli_2025_codes

Usage:

 list_kbli_2025_codes(%args) -> [$status_code, $reason, $payload, \%result_meta]

List KBLI 2025 codes.

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

=item * B<description> => I<str>

Only return records where the 'description' field equals specified value.

=item * B<description.contains> => I<str>

Only return records where the 'description' field contains specified text.

=item * B<description.in> => I<array[str]>

Only return records where the 'description' field is in the specified values.

=item * B<description.is> => I<str>

Only return records where the 'description' field equals specified value.

=item * B<description.isnt> => I<str>

Only return records where the 'description' field does not equal specified value.

=item * B<description.max> => I<str>

Only return records where the 'description' field is less than or equal to specified value.

=item * B<description.min> => I<str>

Only return records where the 'description' field is greater than or equal to specified value.

=item * B<description.not_contains> => I<str>

Only return records where the 'description' field does not contain specified text.

=item * B<description.not_in> => I<array[str]>

Only return records where the 'description' field is not in the specified values.

=item * B<description.xmax> => I<str>

Only return records where the 'description' field is less than specified value.

=item * B<description.xmin> => I<str>

Only return records where the 'description' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<queries> => I<array[str]>

Search.

This will search all searchable fields with one or more specified queries. Each
query can be in the form of C<-FOO> (dash prefix notation) to require that the
fields do not contain specified string, or C</FOO/> to use regular expression.
All queries must match if the C<query_boolean> option is set to C<and>; only one
query should match if the C<query_boolean> option is set to C<or>.

=item * B<query_boolean> => I<str> (default: "and")

Whether records must match all search queries ('and') or just one ('or').

If set to C<and>, all queries must match; if set to C<or>, only one query should
match. See the C<queries> option for more details on searching.

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

=item * B<title> => I<str>

Only return records where the 'title' field equals specified value.

=item * B<title.contains> => I<str>

Only return records where the 'title' field contains specified text.

=item * B<title.in> => I<array[str]>

Only return records where the 'title' field is in the specified values.

=item * B<title.is> => I<str>

Only return records where the 'title' field equals specified value.

=item * B<title.isnt> => I<str>

Only return records where the 'title' field does not equal specified value.

=item * B<title.max> => I<str>

Only return records where the 'title' field is less than or equal to specified value.

=item * B<title.min> => I<str>

Only return records where the 'title' field is greater than or equal to specified value.

=item * B<title.not_contains> => I<str>

Only return records where the 'title' field does not contain specified text.

=item * B<title.not_in> => I<array[str]>

Only return records where the 'title' field is not in the specified values.

=item * B<title.xmax> => I<str>

Only return records where the 'title' field is less than specified value.

=item * B<title.xmin> => I<str>

Only return records where the 'title' field is greater than specified value.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hashE<sol>associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-KBLIUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-KBLIUtils>.

=head1 SEE ALSO

L<https://www.bps.go.id/klasifikasi/app/kbli> (you can also browse the KBLI
codes from L<https://oss.go.id/informasi/kbli-berbasis-risiko> but that
website's UI is an abomination).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords perlancar

perlancar <perlancar@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-KBLIUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
