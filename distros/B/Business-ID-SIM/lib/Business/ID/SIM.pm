package Business::ID::SIM;

use 5.010001;
use warnings;
use strict;

use DateTime;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-11'; # DATE
our $DIST = 'Business-ID-SIM'; # DIST
our $VERSION = '0.081'; # VERSION

our @EXPORT_OK = qw(parse_sim);

# legend: S = lack of samples

# less organized than the convoluted code in NIK

my %provinces = (
    '06' => "Nanggroe Aceh Darussalam",
    '07' => "Sumatera Utara",
    '08' => "Sumatera Barat",
    '09' => "Riau, Kepulauan Riau",
    '10' => undef, # S
    '11' => "Sumatera Selatan",
    '12' => "DKI Jakarta", # most frequently encountered
    '13' => "Jawa Barat",
    '14' => "Jawa Tengah, DI Yogyakarta",
    '15' => "Jawa Timur",
    '16' => "Bali",
    '17' => "Kalimantan Timur",
    '18' => "Kalimantan Selatan",
    '19' => "Sulawesi Selatan",
    '20' => "Sulawesi Utara, Gorontalo",
    '21' => undef, # S
    '22' => 'Papua',
    '23' => 'Kalimantan Tengah',
    '24' => 'Sulawesi Tengah',
    '25' => 'Lampung',
    #'30' => "Banten", # ?, SS

    );

our %SPEC;

$SPEC{parse_sim} = {
    v => 1.1,
    summary => 'Validate Indonesian driving license number (nomor SIM)',
    args => {
        sim => {
            summary => 'Input to be parsed',
            schema => 'str*',
            pos => 0,
            req => 1,
        },
    },
};
sub parse_sim {
    my %args = @_;

    my $sim = $args{sim} or return [400, "Please specify sim"];
    my $res = {};

    $sim =~ s/\D+//g;
    return [400, "Not 12 digit"] unless length($sim) == 12;

    $res->{prov_code} = substr($sim, 4, 2);
    return [400, "Unknown province code"] unless $provinces{$res->{prov_code}};
    $res->{area_code} = substr($sim, 4, 4);

    my ($y, $m) = $sim =~ /^(..)(..)/;
    my $today = DateTime->today;
    $y += int($today->year / 100) * 100;
    $y -= 100 if $y > $today->year;
    eval { $res->{dob} = DateTime->new(day=>1, month=>$m, year=>$y) };
    return [400, "Invalid year and month of birth: $y, $m"] if $@;
    $res->{serial} = $sim =~ /(....)$/;
    return [400, "Serial starts from 1, not 0"] if $res->{serial} < 1;

    [200, "OK", $res];
}

1;
# ABSTRACT: Validate Indonesian driving license number (nomor SIM)

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::ID::SIM - Validate Indonesian driving license number (nomor SIM)

=head1 VERSION

This document describes version 0.081 of Business::ID::SIM (from Perl distribution Business-ID-SIM), released on 2024-07-11.

=head1 SYNOPSIS

 use Business::ID::SIM qw(parse_sim);

 my $res = parse_sim(sim => "0113 40 00 0001");

=head1 DESCRIPTION

This module can be used to validate Indonesian driving license number, Nomor
Surat Izin Mengemudi (SIM).

SIM is composed of 12 digits as follow:

 yymm.pp.aa.ssss

yy and mm are year and month of birth, pp and aa are area code
(province+district of some sort), ssss is 4-digit serial most probably starting
from 1.

Note that there are several kinds of SIM (A, B1, B2, C) but this is not encoded
in the SIM number and all SIM's have the same number.

=head1 FUNCTIONS


=head2 parse_sim

Usage:

 parse_sim(%args) -> [$status_code, $reason, $payload, \%result_meta]

Validate Indonesian driving license number (nomor SIM).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<sim>* => I<str>

Input to be parsed.


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

Please visit the project's homepage at L<https://metacpan.org/release/Business-ID-SIM>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Business-ID-SIM>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Business-ID-SIM>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
