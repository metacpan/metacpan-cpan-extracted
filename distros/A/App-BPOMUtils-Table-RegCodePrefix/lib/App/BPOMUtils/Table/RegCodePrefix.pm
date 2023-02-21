package App::BPOMUtils::Table::RegCodePrefix;

use 5.010001;
use strict 'subs', 'vars';
use utf8;
use warnings;
use Log::ger;

use Exporter 'import';
use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-13'; # DATE
our $DIST = 'App-BPOMUtils-Table-RegCodePrefix'; # DIST
our $VERSION = '0.017'; # VERSION

our @EXPORT_OK = qw(
                       bpom_list_reg_code_prefixes
               );

our %SPEC;

our $meta_reg_code_prefixes = {
  summary => "Known alphabetical prefixes in BPOM registered product codes",
  "fields" => {
    code => {
      pos => 0,
      schema => ["str*"],
      sortable => 1,
      summary => "code",
    },
    division => {
      pos      => 1,
      schema   => ["str*"],
      sortable => 1,
      summary  => "Division (food, supplement [including herbal], medicine)",
      unique   => 0,
    },
    summary_eng => {
      pos      => 2,
      schema   => ["str*"],
      sortable => 1,
      summary  => "Summary (in English)",
      unique   => 0,
    },
    summary_ind => {
      pos      => 3,
      schema   => ["str*"],
      sortable => 1,
      summary  => "Summary (in Indonesian)",
      unique   => 0,
    },
  },
  "pk" => "code",
  "summary" => "BPOM registered product code prefixes",
  "summary.alt.lang.id_ID" => "Awalan huruf di kode produk terdaftar BPOM",
};

our $data_reg_code_prefixes = [
    ["MD", "food", "Food (local)", "Makanan (dalam negeri)"],
    ["ML", "food", "Food (imported)", "Makanan (impor)"],


    # ?N? and ?P? codes currently are not listed here

    ["DBL", "medicine", "Local (L) OTC (B) patented (D) medicine", "Obat paten (D) bebas (B) lokal (L)"],
    ["DBI", "medicine", "Imported (L) OTC (B) patented (D) medicine", "Obat paten (D) bebas (B) impor (I)"],
    ["DBE", "medicine", "Exported (L) OTC (B) patented (D) medicine", "Obat paten (D) bebas (B) ekspor (E)"],
    ["DBX", "medicine", "Special-purpose (X) OTC (B) patented (D) medicine", "Obat paten (D) bebas (B) keperluan khusus (X)"],

    ["DTL", "medicine", "Local (L) limited-OTC (T) patented (D) medicine", "Obat paten (D) bebas terbatas (T) lokal (L)"],
    ["DTI", "medicine", "Imported (L) limited-OTC (T) patented (D) medicine", "Obat paten (D) bebas terbatas (T) impor (I)"],
    ["DTE", "medicine", "Exported (L) limited-OTC (T) patented (D) medicine", "Obat paten (D) bebas terbatas (T) ekspor (E)"],
    ["DTX", "medicine", "Special-purpose (X) limited-OTC (T) patented (D) medicine", "Obat paten (D) bebas terbatas (T) keperluan khusus (X)"],

    ["DKL", "medicine", "Local (L) hard (K) patented (D) medicine", "Obat paten (D) keras (K) lokal (L)"],
    ["DKI", "medicine", "Imported (L) hard (K) patented (D) medicine", "Obat paten (D) keras (K) impor (I)"],
    ["DKE", "medicine", "Exported (L) hard (K) patented (D) medicine", "Obat paten (D) keras (K) ekspor (E)"],
    ["DKX", "medicine", "Special-purpose (X) hard (K) patented (D) medicine", "Obat paten (D) keras (K) keperluan khusus (X)"],

    ["GBL", "medicine", "Local (L) OTC (B) generic (G) medicine", "Obat generik (G) bebas (B) lokal (L)"],
    ["GBI", "medicine", "Imported (L) OTC (B) generic (G) medicine", "Obat generik (G) bebas (B) impor (I)"],
    ["GBE", "medicine", "Exported (L) OTC (B) generic (G) medicine", "Obat generik (G) bebas (B) ekspor (E)"],
    ["GBX", "medicine", "Special-purpose (X) OTC (B) generic (G) medicine", "Obat generik (G) bebas (B) keperluan khusus (X)"],

    ["GTL", "medicine", "Local (L) limited-OTC (T) generic (G) medicine", "Obat generik (G) bebas terbatas (T) lokal (L)"],
    ["GTI", "medicine", "Imported (L) limited-OTC (T) generic (G) medicine", "Obat generik (G) bebas terbatas (T) impor (I)"],
    ["GTE", "medicine", "Exported (L) limited-OTC (T) generic (G) medicine", "Obat generik (G) bebas terbatas (T) ekspor (E)"],
    ["GTX", "medicine", "Special-purpose (X) limited-OTC (T) generic (G) medicine", "Obat generik (G) bebas terbatas (T) keperluan khusus (X)"],

    ["GKL", "medicine", "Local (L) hard (K) generic (G) medicine", "Obat generik (G) keras (K) lokal (L)"],
    ["GKI", "medicine", "Imported (L) hard (K) generic (G) medicine", "Obat generik (G) keras (K) impor (I)"],
    ["GKE", "medicine", "Exported (L) hard (K) generic (G) medicine", "Obat generik (G) keras (K) ekspor (E)"],
    ["GKX", "medicine", "Special-purpose (X) hard (K) generic (G) medicine", "Obat generik (G) keras (K) keperluan khusus (X)"],


    ["SD", "supplement+cosmetic", "Local supplement", "Suplemen dalam negeri"],
    ["SI", "supplement+cosmetic", "Imported supplement", "Suplemen impor"],
    ["SL", "supplement+cosmetic", "Licensed Supplement", "Suplemen dalam negeri dengan lisensi"],

    ["BTR", "supplement+cosmetic", "Local traditional medicine/production medicine", "Obat tradisional berbatasan dengan obat produksi, dalam negeri"],
    ["BTI", "supplement+cosmetic", "Imported traditional medicine/production medicine", "Obat tradisional berbatasan dengan obat produksi, impor"],
    ["BTL", "supplement+cosmetic", "Licensed traditional medicine/production medicine", "Obat tradisional berbatasan dengan obat produksi, dalam negeri dengan lisensi"],

    ["NA", "supplement+cosmetic", "Cosmetics from Asia including local", "Kosmetik dari Asia termasuk lokal"],
    ["NB", "supplement+cosmetic", "Cosmetics from Australia", "Kosmetik dari Australia"],
    ["NC", "supplement+cosmetic", "Cosmetics from Europe", "Kosmetik dari Eropa"],
    ["ND", "supplement+cosmetic", "Cosmetics from Africa", "Kosmetik dari Afrika"],
    ["NE", "supplement+cosmetic", "Cosmetics from America", "Kosmetik dari Amerika"],
];

my $res = gen_read_table_func(
    name => 'bpom_list_reg_code_prefixes',
    summary => 'List known alphabetical prefixes in BPOM registered product codes',
    table_data => $data_reg_code_prefixes,
    table_spec => $meta_reg_code_prefixes,
    description => <<'_',
_
    extra_props => {
        examples => [
        ],
    },
);
die "Can't generate function: $res->[0] - $res->[1]" unless $res->[0] == 200;

1;
# ABSTRACT: List known alphabetical prefixes in BPOM registered product codes

__END__

=pod

=encoding UTF-8

=head1 NAME

App::BPOMUtils::Table::RegCodePrefix - List known alphabetical prefixes in BPOM registered product codes

=head1 VERSION

This document describes version 0.017 of App::BPOMUtils::Table::RegCodePrefix (from Perl distribution App-BPOMUtils-Table-RegCodePrefix), released on 2023-02-13.

=head1 DESCRIPTION

This distribution contains the following CLIs:

=over

=item * L<bpom-daftar-kode-prefiks-reg>

=item * L<bpom-list-reg-code-prefixes>

=back

=head1 FUNCTIONS


=head2 bpom_list_reg_code_prefixes

Usage:

 bpom_list_reg_code_prefixes(%args) -> [$status_code, $reason, $payload, \%result_meta]

List known alphabetical prefixes in BPOM registered product codes.

This function is not exported by default, but exportable.

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

=item * B<division> => I<str>

Only return records where the 'division' field equals specified value.

=item * B<division.contains> => I<str>

Only return records where the 'division' field contains specified text.

=item * B<division.in> => I<array[str]>

Only return records where the 'division' field is in the specified values.

=item * B<division.is> => I<str>

Only return records where the 'division' field equals specified value.

=item * B<division.isnt> => I<str>

Only return records where the 'division' field does not equal specified value.

=item * B<division.max> => I<str>

Only return records where the 'division' field is less than or equal to specified value.

=item * B<division.min> => I<str>

Only return records where the 'division' field is greater than or equal to specified value.

=item * B<division.not_contains> => I<str>

Only return records where the 'division' field does not contain specified text.

=item * B<division.not_in> => I<array[str]>

Only return records where the 'division' field is not in the specified values.

=item * B<division.xmax> => I<str>

Only return records where the 'division' field is less than specified value.

=item * B<division.xmin> => I<str>

Only return records where the 'division' field is greater than specified value.

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

=item * B<summary_eng> => I<str>

Only return records where the 'summary_eng' field equals specified value.

=item * B<summary_eng.contains> => I<str>

Only return records where the 'summary_eng' field contains specified text.

=item * B<summary_eng.in> => I<array[str]>

Only return records where the 'summary_eng' field is in the specified values.

=item * B<summary_eng.is> => I<str>

Only return records where the 'summary_eng' field equals specified value.

=item * B<summary_eng.isnt> => I<str>

Only return records where the 'summary_eng' field does not equal specified value.

=item * B<summary_eng.max> => I<str>

Only return records where the 'summary_eng' field is less than or equal to specified value.

=item * B<summary_eng.min> => I<str>

Only return records where the 'summary_eng' field is greater than or equal to specified value.

=item * B<summary_eng.not_contains> => I<str>

Only return records where the 'summary_eng' field does not contain specified text.

=item * B<summary_eng.not_in> => I<array[str]>

Only return records where the 'summary_eng' field is not in the specified values.

=item * B<summary_eng.xmax> => I<str>

Only return records where the 'summary_eng' field is less than specified value.

=item * B<summary_eng.xmin> => I<str>

Only return records where the 'summary_eng' field is greater than specified value.

=item * B<summary_ind> => I<str>

Only return records where the 'summary_ind' field equals specified value.

=item * B<summary_ind.contains> => I<str>

Only return records where the 'summary_ind' field contains specified text.

=item * B<summary_ind.in> => I<array[str]>

Only return records where the 'summary_ind' field is in the specified values.

=item * B<summary_ind.is> => I<str>

Only return records where the 'summary_ind' field equals specified value.

=item * B<summary_ind.isnt> => I<str>

Only return records where the 'summary_ind' field does not equal specified value.

=item * B<summary_ind.max> => I<str>

Only return records where the 'summary_ind' field is less than or equal to specified value.

=item * B<summary_ind.min> => I<str>

Only return records where the 'summary_ind' field is greater than or equal to specified value.

=item * B<summary_ind.not_contains> => I<str>

Only return records where the 'summary_ind' field does not contain specified text.

=item * B<summary_ind.not_in> => I<array[str]>

Only return records where the 'summary_ind' field is not in the specified values.

=item * B<summary_ind.xmax> => I<str>

Only return records where the 'summary_ind' field is less than specified value.

=item * B<summary_ind.xmin> => I<str>

Only return records where the 'summary_ind' field is greater than specified value.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-BPOMUtils-Table-RegCodePrefix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BPOMUtils-Table-RegCodePrefix>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-BPOMUtils-Table-RegCodePrefix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
