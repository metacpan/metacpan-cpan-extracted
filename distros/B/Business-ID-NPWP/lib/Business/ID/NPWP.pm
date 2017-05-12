package Business::ID::NPWP;

our $DATE = '2015-09-03'; # DATE
our $VERSION = '0.07'; # VERSION

use 5.010001;
use warnings;
use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(parse_npwp);

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
    return [400, "Not 15 digit"] unless length($npwp) == 15;

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

This document describes version 0.07 of Business::ID::NPWP (from Perl distribution Business-ID-NPWP), released on 2015-09-03.

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


=head2 parse_npwp(%args) -> [status, msg, result, meta]

Parse Indonesian taxpayer registration number (NPWP).

Arguments ('*' denotes required arguments):

=over 4

=item * B<npwp>* => I<str>

Input NPWP to be parsed.

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

Please visit the project's homepage at L<https://metacpan.org/release/Business-ID-NPWP>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Business-ID-NPWP>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Business-ID-NPWP>

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
