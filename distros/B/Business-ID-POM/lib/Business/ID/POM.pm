package Business::ID::POM;

our $DATE = '2019-11-25'; # DATE
our $DIST = 'Business-ID-POM'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use warnings;
use strict;
use Log::ger;

use Exporter qw(import);
our @EXPORT_OK = qw(parse_pom_reg_code);

our %SPEC;

sub _2to4_dig_year {
    ($_[0] >= 78 ? 1900 : 2000) + $_[0];
}

$SPEC{parse_pom_reg_code} = {
    v => 1.1,
    summary => 'Parse food/drug registration code published by '.
        'the Indonesian National Agency of Drug and Food Control (POM)',
    description => <<'_',

This routine does not check whether the code actually exists. Use
<https://cekbpom.pom.go.id/> for that.

_
    args => {
        code => {
            summary => 'Input POM code to be parsed',
            schema  => 'str*',
            pos => 0,
            req => 1,
        },
    },
    examples => [
        {args=>{code=>'MD 224510107115'}},
        {args=>{code=>'DBL9624502804A1'}},
        {args=>{code=>'NC14191300159'}},
        {args=>{code=>'TR092699241'}},
        {args=>{code=>'FF182600791'}},
    ],
};
sub parse_pom_reg_code {
    my %args = @_;

    my $code = $args{code} or return [400, "Please specify code"];
    my $res = {};

    $code = uc($code);
    $code =~ s/[^0-9A-Z]+//g;

    $code =~ /\A([A-Z]+)([0-9A-Z]+)\z/
        or return [400, "Invalid syntax, code needs to be letters followed by digits/letters"];

    $res->{category_code} = $1;
    $res->{number} = $2;

    if ($res->{category_code} =~ /\AM[DL]\z/) {

        $res->{category_id} = $res->{category_code} eq 'MD' ? 'Makanan (M), dalam negeri (D)' : 'Makanan (M), impor (L)';
        $res->{number} =~ /\A([0-9])([0-9]{3})([0-9]{2})([0-9]{3})([0-9]{3})\z/
            or return [400, "MD/ML number needs to be 12-digit number"];

        $res->{food_packaging_code} = $1;
        $res->{food_type_code} = $2;
        $res->{food_province_code} = $3;
        $res->{food_company_code} = $4;
        $res->{food_company_product_code} = $5;

    } elsif ($res->{category_code} =~ /\A[DG](.?)(.?)\z/) {

        $res->{drug_category_code} = $1;
        $res->{drug_origin_code} = $2;

        $res->{category_id} = $res->{category_code} =~ /\AD/ ? 'Obat merek dagang (D)' : 'Obat generik (G)';
        if    ($res->{drug_category_code} eq 'B') { $res->{category_id} .= ", bebas (B)" }
        elsif ($res->{drug_category_code} eq 'T') { $res->{category_id} .= ", bebas terbatas (T)" }
        elsif ($res->{drug_category_code} eq 'K') { $res->{category_id} .= ", obat keras (K)" }
        elsif ($res->{drug_category_code} eq 'N') { $res->{category_id} .= ", narkotik (N)" }
        elsif ($res->{drug_category_code} eq 'P') { $res->{category_id} .= ", psikotropik (P)" }
        else { return [400, "Invalid drug category code '$res->{drug_category_code}', valid codes are B/T/K/N/P"] }

        if    ($res->{drug_origin_code} eq 'L') { $res->{category_id} .= ", lokal (L)" }
        elsif ($res->{drug_origin_code} eq 'I') { $res->{category_id} .= ", impor (I)" }
        elsif ($res->{drug_origin_code} eq 'E') { $res->{category_id} .= ", ekspor (E)" }
        elsif ($res->{drug_origin_code} eq 'X') { $res->{category_id} .= ", keperluan khusus (X)" }
        else { return [400, "Invalid drug origin code '$res->{drug_origin_code}', valid codes are L/I/E/X"] }

        $res->{number} =~ /\A([0-9]{2})([0-9]{3})([0-9]{3})([0-9]{2})([A-Z])([0-9])\z/
            or return [400, "Dxx/Gxx number needs to be 12-digit number/letter"];

        $res->{drug_year} = _2to4_dig_year($1);
        $res->{drug_company_code} = $2;
        $res->{drug_company_product_code} = $3;
        $res->{drug_dosage_form_code} = $4;
        $res->{drug_strength_serial} = $5;
        $res->{drug_packaging_serial} = $6;
        if    ($res->{drug_dosage_form_code} eq '01') { $res->{drug_dosage_form_id} = "kapsul (01)" }
        elsif ($res->{drug_dosage_form_code} eq '02') { $res->{drug_dosage_form_id} = "kapsul lunak (02)" }
        elsif ($res->{drug_dosage_form_code} eq '04') { $res->{drug_dosage_form_id} = "kaplet (04)" }
        elsif ($res->{drug_dosage_form_code} eq '09') { $res->{drug_dosage_form_id} = "kaplet salut film (09)" }
        elsif ($res->{drug_dosage_form_code} eq '10') { $res->{drug_dosage_form_id} = "tablet (10)" }
        elsif ($res->{drug_dosage_form_code} eq '11') { $res->{drug_dosage_form_id} = "tablet effervescent (11)" }
        elsif ($res->{drug_dosage_form_code} eq '12') { $res->{drug_dosage_form_id} = "tablet hisap (12)" }
        elsif ($res->{drug_dosage_form_code} eq '14') { $res->{drug_dosage_form_id} = "tablet lepas terkontrol (14)" }
        elsif ($res->{drug_dosage_form_code} eq '15') { $res->{drug_dosage_form_id} = "tablet salut enterik (15)" }
        elsif ($res->{drug_dosage_form_code} eq '16') { $res->{drug_dosage_form_id} = "pil (16)" }
        elsif ($res->{drug_dosage_form_code} eq '17') { $res->{drug_dosage_form_id} = "tablet salut selaput (17)" }
        elsif ($res->{drug_dosage_form_code} eq '22') { $res->{drug_dosage_form_id} = "granul (22)" }
        elsif ($res->{drug_dosage_form_code} eq '23') { $res->{drug_dosage_form_id} = "serbuk oral (23)" }
        elsif ($res->{drug_dosage_form_code} eq '24') { $res->{drug_dosage_form_id} = "bedak (24)" }
        elsif ($res->{drug_dosage_form_code} eq '28') { $res->{drug_dosage_form_id} = "gel (28)" }
        elsif ($res->{drug_dosage_form_code} eq '29') { $res->{drug_dosage_form_id} = "krim (29)" }
        elsif ($res->{drug_dosage_form_code} eq '30') { $res->{drug_dosage_form_id} = "salep (30)" }
        elsif ($res->{drug_dosage_form_code} eq '31') { $res->{drug_dosage_form_id} = "salep mata (31)" }
        elsif ($res->{drug_dosage_form_code} eq '32') { $res->{drug_dosage_form_id} = "emulsi (32)" }
        elsif ($res->{drug_dosage_form_code} eq '33') { $res->{drug_dosage_form_id} = "suspensi (33)" }
        elsif ($res->{drug_dosage_form_code} eq '34') { $res->{drug_dosage_form_id} = "elixir (34)" }
        elsif ($res->{drug_dosage_form_code} eq '36') { $res->{drug_dosage_form_id} = "drops (36)" }
        elsif ($res->{drug_dosage_form_code} eq '37') { $res->{drug_dosage_form_id} = "sirup (37)" }
        elsif ($res->{drug_dosage_form_code} eq '38') { $res->{drug_dosage_form_id} = "suspensi kering (38)" }
        elsif ($res->{drug_dosage_form_code} eq '41') { $res->{drug_dosage_form_id} = "lotion/solusio (41)" }
        elsif ($res->{drug_dosage_form_code} eq '43') { $res->{drug_dosage_form_id} = "injeksi (43)" }
        elsif ($res->{drug_dosage_form_code} eq '44') { $res->{drug_dosage_form_id} = "injeksi suspensi kering (44)" }
        elsif ($res->{drug_dosage_form_code} eq '46') { $res->{drug_dosage_form_id} = "tetes mata steril (46)" }
        elsif ($res->{drug_dosage_form_code} eq '47') { $res->{drug_dosage_form_id} = "tetes hidung (47)" }
        elsif ($res->{drug_dosage_form_code} eq '48') { $res->{drug_dosage_form_id} = "tetes telinga (48)" }
        elsif ($res->{drug_dosage_form_code} eq '49') { $res->{drug_dosage_form_id} = "infus (49)" }
        elsif ($res->{drug_dosage_form_code} eq '53') { $res->{drug_dosage_form_id} = "supositoria, ovula (53)" }
        elsif ($res->{drug_dosage_form_code} eq '56') { $res->{drug_dosage_form_id} = "nasal spray (56)" }
        elsif ($res->{drug_dosage_form_code} eq '58') { $res->{drug_dosage_form_id} = "rectal tube (58)" }
        elsif ($res->{drug_dosage_form_code} eq '62') { $res->{drug_dosage_form_id} = "inhalasi (62)" }
        elsif ($res->{drug_dosage_form_code} eq '63') { $res->{drug_dosage_form_id} = "tablet kunyah (63)" }
        elsif ($res->{drug_dosage_form_code} eq '81') { $res->{drug_dosage_form_id} = "tablet dispersi (81)" }
        else { log_warn "Unknown drug dosage form code ($res->{drug_dosage_form_code}), known codes include 01/02/04/10/etc" }

    } elsif ($res->{category_code} =~ /\AN(.?)\z/) {

        $res->{cosmetic_category_code} = $1;
        $res->{category_id} = "Kosmetik (N)";
        if    ($res->{cosmetic_category_code} eq 'A') { $res->{category_id} .= ", Asia termasuk lokal (A)" }
        elsif ($res->{cosmetic_category_code} eq 'B') { $res->{category_id} .= ", Australia (B)" }
        elsif ($res->{cosmetic_category_code} eq 'C') { $res->{category_id} .= ", Eropa (C)" }
        elsif ($res->{cosmetic_category_code} eq 'D') { $res->{category_id} .= ", Afrika (D)" }
        elsif ($res->{cosmetic_category_code} eq 'E') { $res->{category_id} .= ", Amerika (E)" }
        else { return [400, "Invalid cosmetic category code ($res->{cosmetic_category_code}), valid code is A-E"] }

        $res->{number} =~ /\A([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{5})\z/
            or return [400, "Nx number needs to be 11-digit number"];

        $res->{cosmetic_country_code} = $1;
        $res->{cosmetic_year} = _2to4_dig_year($2);
        $res->{cosmetic_group_code} = $3;
        $res->{cosmetic_notification_code} = $4;

    } elsif ($res->{category_code} =~ /\AB?T(.)\z/) {

        $res->{trad_origin} = $1;
        $res->{category_id} = $res->{category_code} =~ /\AB/ ? 'Obat traditional berbatasan dengan obat produksi (BT)' : 'Obat traditional (T)';
        if    ($res->{trad_origin} eq 'R') { $res->{category_id} .= ', dalam negeri (R)' }
        elsif ($res->{trad_origin} eq 'I') { $res->{category_id} .= ', impor (I)' }
        elsif ($res->{trad_origin} eq 'L') { $res->{category_id} .= ', dalam negeri dengan lisensi  (L)' }
        else { return [400, "Invalid traditional medicine origin code ($res->{trad_origin}), valid code is R/I/L"] }

        $res->{number} =~ /\A([0-9]{2})([0-9]{1})([0-9]{1})([0-9]{4})([0-9]{1})\z/
            or return [400, "BTx/Tx number needs to be 9-digit number"];

        $res->{trad_year} = _2to4_dig_year($1);
        $res->{trad_company_type_code} = $2;
        $res->{trad_packaging_code} = $3;
        $res->{trad_company_product_serial} = $4;
        $res->{trad_packaging_volume_code} = $5;

        if    ($res->{trad_company_type_code} == 1) { $res->{trad_company_type_id} = 'pabrik farmasi' }
        elsif ($res->{trad_company_type_code} == 2) { $res->{trad_company_type_id} = 'pabrik jamu' }
        elsif ($res->{trad_company_type_code} == 3) { $res->{trad_company_type_id} = 'perusahaan jamu' }
        else { return [400, "Invalid traditional medicine company type code ($res->{trad_company_type_code}), valid code is 1/2/3"] }

        if    ($res->{trad_packaging_code} == 1) { $res->{trad_packaging_id} = 'rajangan' }
        elsif ($res->{trad_packaging_code} == 2) { $res->{trad_packaging_id} = 'serbuk' }
        elsif ($res->{trad_packaging_code} == 3) { $res->{trad_packaging_id} = 'kapsul' }
        elsif ($res->{trad_packaging_code} == 4) { $res->{trad_packaging_id} = 'pil, granul, boli, pastiles, jenang, tablet/kaplet' }
        elsif ($res->{trad_packaging_code} == 5) { $res->{trad_packaging_id} = 'dodol, majun' }
        elsif ($res->{trad_packaging_code} == 6) { $res->{trad_packaging_id} = 'cairan' }
        elsif ($res->{trad_packaging_code} == 7) { $res->{trad_packaging_id} = 'salep, krim' }
        elsif ($res->{trad_packaging_code} == 8) { $res->{trad_packaging_id} = 'plester, koyo' }
        elsif ($res->{trad_packaging_code} == 9) { $res->{trad_packaging_id} = 'bentuk lain (mis: dupa, ratus, mangir, permen)' }

        if    ($res->{trad_packaging_volume_code} == 1) { $res->{trad_packaging_volume} = '15ml' }
        elsif ($res->{trad_packaging_volume_code} == 2) { $res->{trad_packaging_volume} = '30ml' }
        elsif ($res->{trad_packaging_volume_code} == 3) { $res->{trad_packaging_volume} = '45ml' }
        else { log_warn "Unknown traditional medicine package volume code ($res->{trad_packaging_volume_code}), known code is 1/2/3" }

    } elsif ($res->{category_code} =~ /\AFF\z/) {

        $res->{category_id} = 'Fitofarma (FF)';
        $res->{number} =~ /\A([0-9]{9})\z/
            or return [400, "FF number needs to be 9-digit number"];

    } else {

        return [400, "Unknown category code ($res->{category_code}), known category codes include MD/ML/TR/TI/SD/SI/etc"];

    }

    [200, "OK", $res];
}

1;
# ABSTRACT: Parse food/drug registration code published by the Indonesian National Agency of Drug and Food Control (POM)

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::ID::POM - Parse food/drug registration code published by the Indonesian National Agency of Drug and Food Control (POM)

=head1 VERSION

This document describes version 0.002 of Business::ID::POM (from Perl distribution Business-ID-POM), released on 2019-11-25.

=head1 DESCRIPTION

This module can be used to validate food/drug registration codes published by
the Indonesian National Agency of Drug and Food Control (BPOM, Badan Pengawas
Obat dan Makanan). These codes include:

 MD, ML - food
 SI, SD - health supplements
 NA, NB, NC, ND, NE - cosmetics
 TR, TI - traditional medicine
 D, G - pharmaceutical products
 FF - phytopharmaceutical products

Not yet included BPOM codes:

 CA, CD, CL - cosmetics?
 HT - standardized herbal (herbal terstandar)

Related codes:

SNI

P-IRT

=head1 FUNCTIONS


=head2 parse_pom_reg_code

Usage:

 parse_pom_reg_code(%args) -> [status, msg, payload, meta]

Parse food/drug registration code published by the Indonesian National Agency of Drug and Food Control (POM).

Examples:

=over

=item * Example #1:

 parse_pom_reg_code(code => "MD 224510107115");

Result:

 {
   category_code             => "MD",
   category_id               => "Makanan (M), dalam negeri (D)",
   food_company_code         => 107,
   food_company_product_code => 115,
   food_packaging_code       => 2,
   food_province_code        => 10,
   food_type_code            => 245,
   number                    => 224510107115,
 }

=item * Example #2:

 parse_pom_reg_code(code => "DBL9624502804A1");

Result:

 {
   category_code             => "DBL",
   category_id               => "Obat merek dagang (D), bebas (B), lokal (L)",
   drug_category_code        => "B",
   drug_company_code         => 245,
   drug_company_product_code => "028",
   drug_dosage_form_code     => "04",
   drug_dosage_form_id       => "kaplet (04)",
   drug_origin_code          => "L",
   drug_packaging_serial     => 1,
   drug_strength_serial      => "A",
   drug_year                 => 1996,
   number                    => "9624502804A1",
 }

=item * Example #3:

 parse_pom_reg_code(code => "NC14191300159");

Result:

 {
   category_code => "NC",
   category_id => "Kosmetik (N), Eropa (C)",
   cosmetic_category_code => "C",
   cosmetic_country_code => 14,
   cosmetic_group_code => 13,
   cosmetic_notification_code => "00159",
   cosmetic_year => 2019,
   number => 14191300159,
 }

=item * Example #4:

 parse_pom_reg_code(code => "TR092699241");

Result:

 {
   category_code => "TR",
   category_id => "Obat traditional (T), dalam negeri (R)",
   number => "092699241",
   trad_company_product_serial => 9924,
   trad_company_type_code => 2,
   trad_company_type_id => "pabrik jamu",
   trad_origin => "R",
   trad_packaging_code => 6,
   trad_packaging_id => "cairan",
   trad_packaging_volume => "15ml",
   trad_packaging_volume_code => 1,
   trad_year => 2009,
 }

=item * Example #5:

 parse_pom_reg_code(code => "FF182600791");

Result:

 {
   category_code => "FF",
   category_id => "Fitofarma (FF)",
   number => 182600791,
 }

=back

This routine does not check whether the code actually exists. Use
L<https://cekbpom.pom.go.id/> for that.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<code>* => I<str>

Input POM code to be parsed.

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

Please visit the project's homepage at L<https://metacpan.org/release/Business-ID-POM>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Business-ID-POM>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Business-ID-POM>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Business::ID::PIRT>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
