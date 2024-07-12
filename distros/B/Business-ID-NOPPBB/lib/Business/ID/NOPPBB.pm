package Business::ID::NOPPBB;

use 5.010001;
use warnings;
use strict;

use Exporter 'import';
use Locale::ID::Province qw(list_idn_provinces);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-11'; # DATE
our $DIST = 'Business-ID-NOPPBB'; # DIST
our $VERSION = '0.092'; # VERSION

our @EXPORT_OK = qw(validate_nop_pbb);

our %SPEC;

$SPEC{validate_nop_pbb} = {
    v => 1.1,
    summary => 'Validate (and parse) Indonesian property tax number (NOP PBB)',
    description => <<'_',

Indonesian property tax object number, or Nomor Objek Pajak Pajak Bumi dan
Bangunan, is a number given to a tax object (a piece of land with its
house/building).

NOP PBB is composed of 18 digits as follow:

 AA.BB.CCC.DDD.EEE-XXXX.Y

AA is the province code from BPS. BB is locality (city/regency a.k.a
kota/kabupaten) code from BPS. CCC is district (kecamatan) code from BPS. DDD is
village (desa/kelurahan) code from BPS. EEE is block code. XXXX is the object
number. Y is a special code (it is most likely not a check digit, since it is
almost always has the value of 0).

The function will return status 200 if syntax is valid and return the parsed
information hash. Otherwise it will return 400.

Currently the length and AA code is checked against valid province code. There
is currently no way to check whether a specific NOP PBB actually exists, because
you would need to query Dirjen Pajak's database for that.

_
    args => {
        str => {
            summary => 'The input string containing number to check',
            pos => 0,
            schema => 'str*',
        },
    },
    result => {
        schema => ['hash*', {each_index=>['str*'=>{
            in=>[qw/province locality district village
                    block object special

                    eng_province_name
                    ind_province_name
                   /]}]}],
    },
};
sub validate_nop_pbb {
    my (%args) = @_;

    my $str = $args{str} or return [400, "Please specify str"];

    # cache provinces, key is code
    state $provs;
    if (!$provs) {
        my $res = list_idn_provinces(
            fields=>['bps_code', 'ind_name', 'eng_name'],
            with_field_names => 1);
        $res->[0] == 200 or die "Can't retrieve list of provinces: ".
            "$res->[0] - $res->[1]";
        $provs = {};
        $provs->{$_->{bps_code}} = $_ for @{$res->[2]};
    }

    $str =~ s/\D+//g;
    length($str) == 18 or return [400, "Length must be 18 digits"];
    my ($aa, $bb, $ccc, $ddd, $eee, $xxxx, $y) =
        $str =~ /(.{2})(.{2})(.{3})(.{3})(.{4})(.{1})/;
    $provs->{$aa} or return [400, "Unknown province code '$aa'"];

    [200, "OK", {
        province => $aa,
        locality => $bb,
        district => $ccc,
        village => $ddd,
        block => $eee,
        object => $xxxx,
        special => $y,

        eng_province_name => $provs->{$aa}{eng_name},
        ind_province_name => $provs->{$aa}{ind_name},
    }];
}

1;
# ABSTRACT: Validate (and parse) Indonesian property tax number (NOP PBB)

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::ID::NOPPBB - Validate (and parse) Indonesian property tax number (NOP PBB)

=head1 VERSION

This document describes version 0.092 of Business::ID::NOPPBB (from Perl distribution Business-ID-NOPPBB), released on 2024-07-11.

=head1 SYNOPSIS

 use Business::ID::NOPPBB qw(validate_nop_pbb);

 my $res = validate_nop_pbb(str => '327311000109900990');
 $res->[0] == 200 or die "Invalid NOP PBB!";

 # get structure
 use Data::Dumper;
 print Dumper $res->[2];

 # will print something like
 {
     province => 32,
     locality => 73,
     district => 110,
     village  => '001',
     block    => '099',
     object   => '0099',
     special  => 0,
     canonical => '32.73.110.001.099-0099.0',
 }

=head1 DESCRIPTION

This module provides one function: B<validate_nop_pbb>.

This module has L<Rinci> metadata.

=head1 FUNCTIONS


=head2 validate_nop_pbb

Usage:

 validate_nop_pbb(%args) -> [$status_code, $reason, $payload, \%result_meta]

Validate (and parse) Indonesian property tax number (NOP PBB).

Indonesian property tax object number, or Nomor Objek Pajak Pajak Bumi dan
Bangunan, is a number given to a tax object (a piece of land with its
house/building).

NOP PBB is composed of 18 digits as follow:

 AA.BB.CCC.DDD.EEE-XXXX.Y

AA is the province code from BPS. BB is locality (city/regency a.k.a
kota/kabupaten) code from BPS. CCC is district (kecamatan) code from BPS. DDD is
village (desa/kelurahan) code from BPS. EEE is block code. XXXX is the object
number. Y is a special code (it is most likely not a check digit, since it is
almost always has the value of 0).

The function will return status 200 if syntax is valid and return the parsed
information hash. Otherwise it will return 400.

Currently the length and AA code is checked against valid province code. There
is currently no way to check whether a specific NOP PBB actually exists, because
you would need to query Dirjen Pajak's database for that.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<str> => I<str>

The input string containing number to check.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (hash)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Business-ID-NOPPBB>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Business-ID-NOPPBB>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

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

This software is copyright (c) 2024, 2023, 2019, 2015, 2014, 2013, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Business-ID-NOPPBB>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
