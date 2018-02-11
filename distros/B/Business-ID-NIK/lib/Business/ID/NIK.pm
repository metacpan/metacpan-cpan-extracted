package Business::ID::NIK;

our $DATE = '2018-02-07'; # DATE
our $VERSION = '0.090'; # VERSION

use 5.010001;
use warnings;
use strict;

use DateTime;
use Locale::ID::Locality qw(list_id_localities);
use Locale::ID::Province qw(list_id_provinces);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parse_nik);

our %SPEC;

$SPEC{parse_nik} = {
    v => 1.1,
    summary => 'Parse Indonesian citizenship registration number (NIK)',
    args => {
        nik => {
            summary => 'Input NIK to be validated',
            schema => 'str*',
            pos => 0,
            req => 1,
        },
        check_province => {
            summary => 'Whether to check for known province codes',
            schema  => [bool => default => 1],
        },
        check_locality => {
            summary => 'Whether to check for known locality (city) codes',
            schema  => [bool => default => 1],
        },
    },
};
sub parse_nik {
    my %args = @_;

    state $provinces;
    if (!$provinces) {
        my $res = list_id_provinces(detail => 1);
        return [500, "Can't get list of provinces: $res->[0] - $res->[1]"]
            if $res->[0] != 200;
        $provinces = { map {$_->{bps_code} => $_} @{$res->[2]} };
    }

    my $nik = $args{nik} or return [400, "Please specify nik"];
    my $res = {};

    $nik =~ s/\D+//g;
    return [400, "Not 16 digit"] unless length($nik) == 16;

    $res->{prov_code} = substr($nik, 0, 2);
    if ($args{check_province} // 1) {
        my $p = $provinces->{ $res->{prov_code} };
        $p or return [400, "Unknown province code"];
        $res->{prov_eng_name} = $p->{eng_name};
        $res->{prov_ind_name} = $p->{ind_name};
    }

    $res->{loc_code}  = substr($nik, 0, 4);
    if ($args{check_locality} // 1) {
        my $lres = list_id_localities(
            detail => 1, bps_code => $res->{loc_code});
        return [500, "Can't check locality: $lres->[0] - $lres->[1]"]
            unless $lres->[0] == 200;
        my $l = $lres->[2][0];
        $l or return [400, "Unknown locality code"];
        #$res->{loc_eng_name} = $p->{eng_name};
        $res->{loc_ind_name} = $l->{ind_name};
        $res->{loc_type} = $l->{type};
    }

    my ($d, $m, $y) = $nik =~ /^\d{6}(..)(..)(..)/;
    if ($d > 40) {
        $res->{gender} = 'F';
        $d -= 40;
    } else {
        $res->{gender} = 'M';
    }
    my $today = DateTime->today;
    $y += int($today->year / 100) * 100;
    $y -= 100 if $y > $today->year;
    eval { $res->{dob} = DateTime->new(day=>$d, month=>$m, year=>$y)->ymd };
    if ($@) {
        return [400, "Invalid date of birth: $d-$m-$y"];
    }

    $res->{serial} = substr($nik, 12);
    return [400, "Serial starts from 1, not 0"] if $res->{serial} < 1;

    [200, "OK", $res];
}

1;
# ABSTRACT: Parse Indonesian citizenship registration number (NIK)

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::ID::NIK - Parse Indonesian citizenship registration number (NIK)

=head1 VERSION

This document describes version 0.090 of Business::ID::NIK (from Perl distribution Business-ID-NIK), released on 2018-02-07.

=head1 SYNOPSIS

    use Business::ID::NIK qw(parse_nik);

    my $res = parse_nik(nik => "3273010119800002");

=head1 DESCRIPTION

This module can be used to validate Indonesian citizenship registration number,
Nomor Induk Kependudukan (NIK), or more popularly known as Nomor Kartu Tanda
Penduduk (Nomor KTP), because NIK is displayed on the KTP (citizen identity
card).

NIK is composed of 16 digits as follow:

 pp.DDSS.ddmmyy.ssss

pp.DDSS is a 6-digit area code where the NIK was registered (it used to be but
nowadays not always [citation needed] composed as: pp 2-digit province code, DD
2-digit city/district [kota/kabupaten] code, SS 2-digit subdistrict [kecamatan]
code), ddmmyy is date of birth of the citizen (dd will be added by 40 for
female), ssss is 4-digit serial starting from 1.

=head1 FUNCTIONS


=head2 parse_nik

Usage:

 parse_nik(%args) -> [status, msg, result, meta]

Parse Indonesian citizenship registration number (NIK).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<check_locality> => I<bool> (default: 1)

Whether to check for known locality (city) codes.

=item * B<check_province> => I<bool> (default: 1)

Whether to check for known province codes.

=item * B<nik>* => I<str>

Input NIK to be validated.

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

Please visit the project's homepage at L<https://metacpan.org/release/Business-ID-NIK>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Business-ID-NIK>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Business-ID-NIK>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2015, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
