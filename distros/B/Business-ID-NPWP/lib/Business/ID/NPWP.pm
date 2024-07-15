package Business::ID::NPWP;

use 5.010001;
use warnings;
use strict;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-11'; # DATE
our $DIST = 'Business-ID-NPWP'; # DIST
our $VERSION = '0.092'; # VERSION

our @EXPORT_OK = qw(parse_npwp);

our %SPEC;

sub _z { $_[0] > 9 ? $_[0]-9 : $_[0] }

$SPEC{parse_npwp} = {
    v => 1.1,
    summary => 'Parse Indonesian taxpayer registration number (NPWP)',
    args => {
        npwp => {
            summary => 'Input NPWP to be parsed',
            schema  => 'str',
            pos => 0,
            req => 1,
        },
        allow_nik => {
            schema => 'bool*',
            description => <<'MARKDOWN',

Based on PMK 112 Tahun 2022, Indonesian citizenship registration number (NIK -
nomor induk kependudukan) is also allowed as NPWP. NIK has 16 digits, while the
traditional NPWP is 15 digits. A prefix 0 will be added later so all NPWP will
be 16 digits in the future.

By default, NPWP is allowed to have 16 digits but the first digit must be 0. If
this setting is set to true, NPWP with the first digit other than 0 is also
allowed but will be checked for NIK validness.

MARKDOWN
            default => 0,
        },
    },
};
sub parse_npwp {
    my %args = @_;

    my $npwp = $args{npwp} or return [400, "Please specify npwp"];
    my $res = {};

    $npwp =~ s/^\s+//;
    # assume A = 0 if not specified
    if ($npwp =~ /^\d\./) { $npwp = "0$npwp" }

    $npwp =~ s/\D+//g;
    # assume BBB = 000 if not specified
    if (length($npwp) == 12) { $npwp .= "000" }

    if (length $npwp == 16) {
        if ($npwp =~ s/\A0//) {
            # will be checked as traditional NPWP
        } elsif ($args{allow_nik}) {
            require Business::ID::NIK;
            my $nik_res = Business::ID::NIK::parse_nik(nik => $npwp);
            return $nik_res unless $nik_res->[0] == 200;
            $nik_res->[2]{is_nik} = 1;
            return $nik_res;
        } else {
            return [400, "For 16-digit NPWP, the first digit must be 0"];
        }
    } elsif (length $npwp != 15) {
        return [400, "Must be 15 or 16 digit"];
    }

    $npwp =~ /^(.)(.)(.)(.)(.)(.)(.)(.)(.)/;
    if ((_z(1*$1) + _z(2*$2) + _z(1*$3) +
	 _z(2*$4) + _z(1*$5) + _z(2*$6) +
         _z(1*$7) + _z(2*$8) + _z(1*$9)) % 10) {
        return [400, "Wrong check digit"];
    }

    (
        $res->{taxpayer_code}, $res->{serial}, $res->{check_digit},
        $res->{tax_office_code}, $res->{branch_code},
    ) = $npwp =~ /(..)(.{6})(.)(...)(...)/;

    return [400, "Serial starts from 1, not 0"] if $res->{serial} < 1;

    $res->{normalized} = join(
        "",
        $res->{taxpayer_code}, ".",
        substr($res->{serial}, 0, 3), ".", substr($res->{serial}, 3), ".",
        $res->{check_digit}, "-",
        $res->{tax_office_code}, ".", $res->{branch_code},
    );

    [200, "OK", $res];
}

1;
# ABSTRACT: Parse Indonesian taxpayer registration number (NPWP)

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::ID::NPWP - Parse Indonesian taxpayer registration number (NPWP)

=head1 VERSION

This document describes version 0.092 of Business::ID::NPWP (from Perl distribution Business-ID-NPWP), released on 2024-07-11.

=head1 SYNOPSIS

 use Business::ID::NPWP qw(parse_npwp);

 my $res = parse_npwp(npwp => "02.183.241.5-000.000");

=head1 DESCRIPTION

This module can be used to validate Indonesian taxpayer registration number,
Nomor Pokok Wajib Pajak (NPWP).

NPWP is composed of 15 digits as follow:

 ST.sss.sss.C-OOO.BBB

C<S> is a serial number from 0-9 (so far haven't seen 7 and up, but it's
probably possible).

C<T> denotes taxpayer type code (0 = government treasury [bendahara pemerintah],
1-3 = company/organization [badan], 4/6 = invidual entrepreneur [pengusaha
perorangan], 5 = civil servants [pegawai negeri, PNS], 7-9 = individual employee
[pegawai perorangan]).

C<sss.sss> is a 6-digit serial code for the taxpayer, probably starts from 1. It
is distributed in blocks by the central tax office (kantor pusat dirjen pajak,
DJP) to the local tax offices (kantor pelayanan pajak, KPP) throughout the
country for allocation to taypayers.

C<C> is a check digit. It is apparently using Luhn (modulus 10) algorithm on the
first 9 digits on the NPWP.

C<OOO> is a 3-digit local tax office code (kode KPP).

C<BBB> is a 3-digit branch code. C<000> means the taxpayer is the sole branch
(or, for individuals, the head of the family). C<001>, C<002>, and so on denote
each branch.

=head1 FUNCTIONS


=head2 parse_npwp

Usage:

 parse_npwp(%args) -> [$status_code, $reason, $payload, \%result_meta]

Parse Indonesian taxpayer registration number (NPWP).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<allow_nik> => I<bool> (default: 0)

Based on PMK 112 Tahun 2022, Indonesian citizenship registration number (NIK -
nomor induk kependudukan) is also allowed as NPWP. NIK has 16 digits, while the
traditional NPWP is 15 digits. A prefix 0 will be added later so all NPWP will
be 16 digits in the future.

By default, NPWP is allowed to have 16 digits but the first digit must be 0. If
this setting is set to true, NPWP with the first digit other than 0 is also
allowed but will be checked for NIK validness.

=item * B<npwp>* => I<str>

Input NPWP to be parsed.


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

Please visit the project's homepage at L<https://metacpan.org/release/Business-ID-NPWP>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Business-ID-NPWP>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Steven Haryanto

=over 4

=item *

Steven Haryanto <stevenharyanto@gmail.com>

=item *

Steven Haryanto <steven@masterweb.net>

=back

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

This software is copyright (c) 2024, 2019, 2015, 2014, 2013 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Business-ID-NPWP>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
