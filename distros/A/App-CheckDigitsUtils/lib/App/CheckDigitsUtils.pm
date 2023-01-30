package App::CheckDigitsUtils;

use 5.010001;
use strict;
use warnings;

use Algorithm::CheckDigits;
use Perinci::Object;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-28'; # DATE
our $DIST = 'App-CheckDigitsUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to check digits (CLI for Algorithm::CheckDigits)',
};

our $schreq_num = ['str*', match=>qr/\A[0-9]+\z/, prefilters=>['Str::remove_nondigit']];

our @known_methods;
our @known_methods_summaries;
{
    my %md = Algorithm::CheckDigits->method_descriptions();
    for (sort keys %md) {
        push @known_methods, $_;
        push @known_methods_summaries, $md{$_};
    }
}

our %argspecs_common = (
    method => {
        schema => ['str*', in=>\@known_methods, 'x.in.summaries'=>\@known_methods_summaries],
        cmdline_aliases => {m=>{}},
    },
);

our %argspecopt_quiet = (
    quiet => {
        summary => "If set to true, don't output message to STDOUT",
        schema => 'bool*',
        cmdline_aliases => {q=>{}},
    },
);

$SPEC{calc_check_digits} = {
    v => 1.1,
    summary => "Calculate check digit(s) of number(s)",
    description => <<'_',

Given a number without the check digit(s), e.g. the first 12 digits of an
EAN-13, generate/complete the check digits.

Keywords: complete

_
    args => {
        %argspecs_common,
        numbers => {
            summary => 'Numbers without the check digit(s)',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'number',
            schema => ['array*', of=>$schreq_num],
            req => 1,
            pos => 0,
            slurpy => 1,
            cmdline_src => 'stdin_or_args',
        },
    },
    examples => [
        {
            summary => 'Calculate a single EAN-8 number',
            argv => ['-m', 'ean', '9638-507'],
        },
        {
            summary => 'Calculate a couple of EAN-8 numbers, via pipe',
            src_plang => 'bash',
            src => 'echo -e "9638-507\\n1234567" | [[prog]] -m ean',
        },
    ],
};
sub calc_check_digits {
    require Algorithm::CheckDigits;

    my %args = @_;

    my $cd = Algorithm::CheckDigits::CheckDigits($args{method});

    my $res = [200, "OK", []];
    for my $num (@{ $args{numbers} }) {
        push @{$res->[2]}, $cd->complete($num);
    }
    $res;
}

$SPEC{check_check_digits} = {
    v => 1.1,
    summary => "Check the check digit(s) of numbers",
    description => <<'_',

Given a list of numbers, e.g. EAN-8 numbers, will check the check digit(s) of
each number.

Exit code will be non-zero all numbers are invalid. To check for individual
numbers, use the JSON output.

_
    args => {
        %argspecs_common,
        numbers => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'number',
            schema => ['array*', of=>$schreq_num],
            req => 1,
            pos => 0,
            slurpy => 1,
            cmdline_src => 'stdin_or_args',
        },
        %argspecopt_quiet,
    },
    examples => [
        {
            summary => 'Check a single EAN-8 number (valid, exit code will be zero, message output to STDOUT)',
            argv => ['-m', 'ean', '9638-5074'],
        },
        {
            summary => 'Check a single EAN-8 number (valid, exit code will be zero, no message)',
            argv => ['-m', 'ean', '-q', '9638-5074'],
        },
        {
            summary => 'Check a single EAN-8 number (invalid, exit code is non-zero, message output to STDOUT)',
            argv => ['-m', 'ean', '9638-5070'],
            status => 400,
        },
        {
            summary => 'Check a single EAN-8 number (invalid, exit code is non-zero, no message)',
            argv => ['-m', 'ean', '-q', '9638-5070'],
            status => 400,
        },
        {
            summary => 'Check a couple of EAN-8 numbers, via pipe, JSON output',
            src_plang => 'bash',
            src => 'echo -e "9638-5074\\n12345678" | [[prog]] -m ean --json',
        },
    ],
};
sub check_check_digits {
    require Algorithm::CheckDigits;

    my %args = @_;

    my $cd = Algorithm::CheckDigits::CheckDigits($args{method});
    my $envres = envresmulti();
    for my $num (@{ $args{numbers} }) {
        if (!$cd->is_valid($num)) {
            $envres->add_result(400, "Incorrect check digit(s)", {item_id=>$num}) ;
            print "$num is INVALID (incorrect check digit(s))\n" unless $args{quiet};
        } else {
            $envres->add_result(200, "OK", {item_id=>$num});
            print "$num is valid\n" unless $args{quiet};
        }
    }
    $envres->as_struct;
}

$SPEC{list_check_digits_methods} = {
    v => 1.1,
    summary => "List methods supported by Algorithm::CheckDigits",
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
    examples => [
        {
            summary => 'List methods',
            argv => [],
        },
        {
            summary => 'List methods with their summaries/descriptions',
            argv => ['-l'],
        },
    ],
};
sub list_check_digits_methods {
    my %args = @_;

    if ($args{detail}) {
        my @rows;
        for (0 .. $#known_methods) {
            push @rows, {method=>$known_methods[$_], summary=>$known_methods_summaries[$_]};
        }
        [200, "OK", \@rows, {'table.fields'=>[qw/method summary/]}];
    } else {
        [200, "OK", \@known_methods];
    }
}
1;
# ABSTRACT: Utilities related to check digits (CLI for Algorithm::CheckDigits)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CheckDigitsUtils - Utilities related to check digits (CLI for Algorithm::CheckDigits)

=head1 VERSION

This document describes version 0.001 of App::CheckDigitsUtils (from Perl distribution App-CheckDigitsUtils), released on 2023-01-28.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution includes several utilities related to check digits. They
provide CLIs for L<Algorithm::CheckDigits>.

=over

=item * L<calc-check-digits>

=item * L<check-check-digits>

=item * L<list-check-digits-methods>

=back

=head1 FUNCTIONS


=head2 calc_check_digits

Usage:

 calc_check_digits(%args) -> [$status_code, $reason, $payload, \%result_meta]

Calculate check digit(s) of number(s).

Examples:

=over

=item * Calculate a single EAN-8 number:

 calc_check_digits(numbers => ["9638-507"], method => "ean"); # -> [200, "OK", [96385074], {}]

=back

Given a number without the check digit(s), e.g. the first 12 digits of an
EAN-13, generate/complete the check digits.

Keywords: complete

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<method> => I<str>

(No description)

=item * B<numbers>* => I<array[str]>

Numbers without the check digit(s).


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 check_check_digits

Usage:

 check_check_digits(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check the check digit(s) of numbers.

Examples:

=over

=item * Check a single EAN-8 number (valid, exit code will be zero, message output to STDOUT):

 check_check_digits(numbers => ["9638-5074"], method => "ean");

Result:

 [
   200,
   "All success",
   undef,
   {
     results => [{ item_id => 96385074, message => "OK", status => 200 }],
   },
 ]

=item * Check a single EAN-8 number (valid, exit code will be zero, no message):

 check_check_digits(numbers => ["9638-5074"], method => "ean", quiet => 1);

Result:

 [
   200,
   "All success",
   undef,
   {
     results => [{ item_id => 96385074, message => "OK", status => 200 }],
   },
 ]

=item * Check a single EAN-8 number (invalid, exit code is non-zero, message output to STDOUT):

 check_check_digits(numbers => ["9638-5070"], method => "ean");

Result:

 [
   400,
   "Incorrect check digit(s)",
   undef,
   {
     results => [
       {
         item_id => 96385070,
         message => "Incorrect check digit(s)",
         status  => 400,
       },
     ],
   },
 ]

=item * Check a single EAN-8 number (invalid, exit code is non-zero, no message):

 check_check_digits(numbers => ["9638-5070"], method => "ean", quiet => 1);

Result:

 [
   400,
   "Incorrect check digit(s)",
   undef,
   {
     results => [
       {
         item_id => 96385070,
         message => "Incorrect check digit(s)",
         status  => 400,
       },
     ],
   },
 ]

=back

Given a list of numbers, e.g. EAN-8 numbers, will check the check digit(s) of
each number.

Exit code will be non-zero all numbers are invalid. To check for individual
numbers, use the JSON output.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<method> => I<str>

(No description)

=item * B<numbers>* => I<array[str]>

(No description)

=item * B<quiet> => I<bool>

If set to true, don't output message to STDOUT.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_check_digits_methods

Usage:

 list_check_digits_methods(%args) -> [$status_code, $reason, $payload, \%result_meta]

List methods supported by Algorithm::CheckDigits.

Examples:

=over

=item * List methods:

 list_check_digits_methods();

Result:

 [
   200,
   "OK",
   [
     "2aus5",
     "aba_rn",
     "ahv_ch",
     "amex",
     "bahncard",
     "betriebsnummer",
     "blutbeutel",
     "bwpk_de",
     "bzue_de",
     "cas",
     "ccc_es",
     "code_39",
     "cpf",
     "cusip",
     "dem",
     "diners",
     "discover",
     "dni_es",
     "ean",
     "ecno",
     "einecs",
     "elincs",
     "enroute",
     "esr5_ch",
     "esr9_ch",
     "eurocard",
     "euronote",
     "happydigits",
     "hkid",
     "iban",
     "identcode_dp",
     "iln",
     "imei",
     "imeisv",
     "isan",
     "isbn",
     "isbn13",
     "isin",
     "ismn",
     "issn",
     "jcb",
     "klubkarstadt",
     "leitcode_dp",
     "mastercard",
     "miles&more",
     "nhs_gb",
     "nip",
     "nric_sg",
     "nve",
     "pa_de",
     "pkz",
     "postcheckkonti",
     "pzn",
     "rentenversicherung",
     "sedol",
     "sici",
     "siren",
     "siret",
     "tin_ie",
     "titulo_eleitor",
     "upc",
     "ups",
     "ustid_at",
     "ustid_be",
     "ustid_de",
     "ustid_dk",
     "ustid_fi",
     "ustid_gr",
     "ustid_ie",
     "ustid_lu",
     "ustid_nl",
     "ustid_pl",
     "ustid_pt",
     "vat_sl",
     "vatrn_at",
     "vatrn_be",
     "vatrn_dk",
     "vatrn_fi",
     "vatrn_gr",
     "vatrn_ie",
     "vatrn_lu",
     "vatrn_nl",
     "vatrn_pl",
     "vatrn_pt",
     "verhoeff",
     "visa",
     "wagonnr_br",
   ],
   {},
 ]

=item * List methods with their summariesE<sol>descriptions:

 list_check_digits_methods(detail => 1);

Result:

 [
   200,
   "OK",
   [
     { method => "2aus5", summary => "2 aus 5, 2 of 5, 2/5" },
     {
       method  => "aba_rn",
       summary => "American Bankers Association routing number (ABA RN)",
     },
     {
       method  => "ahv_ch",
       summary => "Alters- und Hinterlassenenversicherungsnummer, AHV (CH)",
     },
     { method => "amex", summary => "American Express credit cards" },
     { method => "bahncard", summary => "DB Bahncard (DE)" },
     { method => "betriebsnummer", summary => "Betriebsnummer (DE)" },
     { method => "blutbeutel", summary => "Eurocode, blood bags" },
     {
       method  => "bwpk_de",
       summary => "Personenkennummer der Bundeswehr (DE)",
     },
     {
       method  => "bzue_de",
       summary => "Beleglose Zahlschein\xC3\xBCberweisung, BZ\xC3\x9C (DE)",
     },
     { method => "cas", summary => "Chemical abstract service, CAS" },
     {
       method  => "ccc_es",
       summary => "C\xC3\xB3digo de Cuenta Corriente, CCC (ES)",
     },
     { method => "code_39", summary => "Code39, 3 of 9" },
     {
       method  => "cpf",
       summary => "Cadastro de Pessoas F\xC3\xADsicas, CPF (BR)",
     },
     {
       method  => "cusip",
       summary => "Committee on Uniform Security Identification Procedures, CUSIP (US)",
     },
     { method => "dem", summary => "Deutsche Mark Banknoten, DEM" },
     { method => "diners", summary => "Diner's club credit cards" },
     { method => "discover", summary => "Discover credit cards" },
     {
       method  => "dni_es",
       summary => "Documento nacional de identidad (ES)",
     },
     { method => "ean", summary => "European Article Number, EAN" },
     {
       method  => "ecno",
       summary => "European Commission number, EC-No (for chemicals)",
     },
     {
       method  => "einecs",
       summary => "European Inventory of Existing Commercial Chemical Substances, EINECS",
     },
     {
       method  => "elincs",
       summary => "European List of Notified Chemical Substances, ELINCS",
     },
     { method => "enroute", summary => "EnRoute credit cards" },
     {
       method  => "esr5_ch",
       summary => "Einzahlungsschein mit Referenz, ESR5 (CH)",
     },
     {
       method  => "esr9_ch",
       summary => "Einzahlungsschein mit Referenz, ESR9 (CH)",
     },
     { method => "eurocard", summary => "Eurocard credit cards" },
     { method => "euronote", summary => "Euro bank notes, EUR" },
     { method => "happydigits", summary => "Happy Digits (DE)" },
     { method => "hkid", summary => "Hong Kong Identity Card, HKID (HK)" },
     {
       method  => "iban",
       summary => "International Bank Account Number (IBAN)",
     },
     {
       method  => "identcode_dp",
       summary => "Identcode Deutsche Post AG (DE)",
     },
     { method => "iln", summary => "Global Location Number, GLN" },
     {
       method  => "imei",
       summary => "International Mobile Station Equipment Identity, IMEI",
     },
     {
       method  => "imeisv",
       summary => "International Mobile Station Equipment Identity and Software Version Number",
     },
     {
       method  => "isan",
       summary => "International Standard Audiovisual Number, ISAN",
     },
     {
       method  => "isbn",
       summary => "International Standard Book Number, ISBN10",
     },
     {
       method  => "isbn13",
       summary => "International Standard Book Number, ISBN13",
     },
     {
       method  => "isin",
       summary => "International Securities Identifikation Number, ISIN",
     },
     {
       method  => "ismn",
       summary => "International Standard Music Number, ISMN",
     },
     {
       method  => "issn",
       summary => "International Standard Serial Number, ISSN",
     },
     { method => "jcb", summary => "JCB credit cards" },
     { method => "klubkarstadt", summary => "Klub Karstadt (DE)" },
     {
       method  => "leitcode_dp",
       summary => "Leitcode Deutsche Post AG (DE)",
     },
     { method => "mastercard", summary => "Mastercard credit cards" },
     { method => "miles&more", summary => "Miles & More, Lufthansa (DE)" },
     { method => "nhs_gb", summary => "National Health Service, NHS (GB)" },
     { method => "nip", summary => "numer identyfikacji podatkowej, NIP" },
     {
       method  => "nric_sg",
       summary => "National Registration Identity Card, NRIC (SG)",
     },
     { method => "nve", summary => "Nummer der Versandeinheit, NVE, SSCC" },
     { method => "pa_de", summary => "Personalausweis (DE)" },
     { method => "pkz", summary => "Personenkennzahl der DDR" },
     { method => "postcheckkonti", summary => "Postscheckkonti (CH)" },
     { method => "pzn", summary => "Pharmazentralnummer (DE)" },
     {
       method  => "rentenversicherung",
       summary => "Rentenversicherungsnummer, VSNR (DE)",
     },
     {
       method  => "sedol",
       summary => "Stock Exchange Daily Official List, SEDOL (GB)",
     },
     { method => "sici", summary => "Value Added Tax number, VAT (DE)" },
     { method => "siren", summary => "SIREN (FR)" },
     { method => "siret", summary => "SIRET (FR)" },
     { method => "tin_ie", summary => "Tax Identification Number (IE)" },
     {
       method  => "titulo_eleitor",
       summary => "T\xC3\xADtulo Eleitoral (BR)",
     },
     { method => "upc", summary => "Universal Product Code, UPC (US, CA)" },
     { method => "ups", summary => "United Parcel Service, UPS" },
     {
       method  => "ustid_at",
       summary => "Umsatzsteuer-Identifikationsnummer (AT)",
     },
     {
       method  => "ustid_be",
       summary => "Umsatzsteuer-Identifikationsnummer (BE)",
     },
     {
       method  => "ustid_de",
       summary => "Umsatzsteuer-Identifikationsnummer (DE)",
     },
     {
       method  => "ustid_dk",
       summary => "Umsatzsteuer-Identifikationsnummer (DK)",
     },
     {
       method  => "ustid_fi",
       summary => "Umsatzsteuer-Identifikationsnummer (FI)",
     },
     {
       method  => "ustid_gr",
       summary => "Umsatzsteuer-Identifikationsnummer (GR)",
     },
     {
       method  => "ustid_ie",
       summary => "Umsatzsteuer-Identifikationsnummer (IE)",
     },
     {
       method  => "ustid_lu",
       summary => "Umsatzsteuer-Identifikationsnummer (LU)",
     },
     {
       method  => "ustid_nl",
       summary => "Umsatzsteuer-Identifikationsnummer (NL)",
     },
     {
       method  => "ustid_pl",
       summary => "Umsatzsteuer-Identifikationsnummer (PL)",
     },
     {
       method  => "ustid_pt",
       summary => "Umsatzsteuer-Identifikationsnummer (PT)",
     },
     { method => "vat_sl", summary => "Value Added Tax number, VAT (SL)" },
     { method => "vatrn_at", summary => "Value Added Tax number, VAT (AT)" },
     { method => "vatrn_be", summary => "Value Added Tax number, VAT (BE)" },
     { method => "vatrn_dk", summary => "Value Added Tax number, VAT (DK)" },
     { method => "vatrn_fi", summary => "Value Added Tax number, VAT (FI)" },
     { method => "vatrn_gr", summary => "Value Added Tax number, VAT (GR)" },
     { method => "vatrn_ie", summary => "Value Added Tax number, VAT (IE)" },
     { method => "vatrn_lu", summary => "Value Added Tax number, VAT (LU)" },
     { method => "vatrn_nl", summary => "Value Added Tax number, VAT (NL)" },
     { method => "vatrn_pl", summary => "Value Added Tax number, VAT (PL)" },
     { method => "vatrn_pt", summary => "Value Added Tax number, VAT (PT)" },
     { method => "verhoeff", summary => "Verhoeff scheme" },
     { method => "visa", summary => "VISA credit cards" },
     {
       method  => "wagonnr_br",
       summary => "Codifica\xC3\xA7\xC3\xA3o dos vag\xC3\xB5es (BR)",
     },
   ],
   { "table.fields" => ["method", "summary"] },
 ]

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-CheckDigitsUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CheckDigitsUtils>.

=head1 SEE ALSO

L<Algorithm::CheckDigits>

For EAN-8 and EAN-13 only, there is L<App::EANUtils>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CheckDigitsUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
