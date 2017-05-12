package Business::ID::NOPPBB;

our $DATE = '2015-09-03'; # DATE
our $VERSION = '0.08'; # VERSION

use 5.010001;
use warnings;
use strict;

use Locale::ID::Province qw(list_id_provinces);

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(validate_nop_pbb);

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
        my $res = list_id_provinces(
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

This document describes version 0.08 of Business::ID::NOPPBB (from Perl distribution Business-ID-NOPPBB), released on 2015-09-03.

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


=head2 validate_nop_pbb(%args) -> [status, msg, result, meta]

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

Arguments ('*' denotes required arguments):

=over 4

=item * B<str> => I<str>

The input string containing number to check.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (hash)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Business-ID-NOPPBB>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Business-ID-NOPPBB>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Business-ID-NOPPBB>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
