package Acme::CPANAuthors::CPAN::MostScripts;

our $DATE = '2016-10-20'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Acme::CPANAuthors::Register (
    "PERLANCAR" => undef,                                   #    539
    "RSAVAGE"   => undef,                                   #    356
    "TRIZEN"    => undef,                                   #    313
    "BDFOY"     => undef,                                   #    173
    "SANTEX"    => undef,                                   #    140
    "MRDVT"     => undef,                                   #    137
    "JWB"       => undef,                                   #    126
    "VVELOX"    => undef,                                   #    125
    "CWEST"     => undef,                                   #    120
    "TSIBLEY"   => undef,                                   #     95
    "SHLOMIF"   => undef,                                   #     94
    "SDAGUE"    => undef,                                   #     91
    "LEOCHARRE" => undef,                                   #     88
    "CMUNGALL"  => undef,                                   #     87
    "LDS"       => undef,                                   #     76
    "RDO"       => undef,                                   #     75
    "AJPAGE"    => undef,                                   #     72
    "EASR"      => undef,                                   #     72
    "INGY"      => undef,                                   #     72
    "GSG"       => undef,                                   #     68
    "AMBS"      => undef,                                   #     67
    "MHOSKEN"   => undef,                                   #     67
    "BPOSTLE"   => undef,                                   #     60
    "MSIMERSON" => undef,                                   #     60
    "TBONE"     => undef,                                   #     57
    "GROUSSE"   => undef,                                   #     56
    "BRYCE"     => undef,                                   #     53
    "NKH"       => undef,                                   #     50
    "KESTEB"    => undef,                                   #     49
    "TIEDEMANN" => undef,                                   #     49
    "IVANWILLS" => undef,                                   #     47
    "MIYAGAWA"  => undef,                                   #     47
    "DHARD"     => undef,                                   #     46
    "PERRAD"    => undef,                                   #     46
    "FREDERICD" => undef,                                   #     45
    "YSAS"      => undef,                                   #     44
    "ADAMK"     => undef,                                   #     41
    "THORGIS"   => undef,                                   #     41
    "GWILLIAMS" => undef,                                   #     40
    "JASONS"    => undef,                                   #     39
    "AGENT"     => undef,                                   #     38
    "CDOLAN"    => undef,                                   #     38
    "GETTY"     => undef,                                   #     38
    "JMACFARLA" => undef,                                   #     38
    "TAPPER"    => undef,                                   #     38
    "AUTRIJUS"  => undef,                                   #     35
    "BEATNIK"   => undef,                                   #     35
    "ALEXMASS"  => undef,                                   #     34
    "BERNARD"   => undef,                                   #     34
    "NOTDOCTOR" => undef,                                   #     34


);

1;
# ABSTRACT: Authors with the most scripts on CPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::CPAN::MostScripts - Authors with the most scripts on CPAN

=head1 VERSION

This document describes version 0.001 of Acme::CPANAuthors::CPAN::MostScripts (from Perl distribution Acme-CPANAuthors-CPAN-MostScripts), released on 2016-10-20.

=head1 SYNOPSIS

   use Acme::CPANAuthors;
   use Acme::CPANAuthors::CPAN::MostScripts;

   my $authors = Acme::CPANAuthors->new('CPAN::MostScripts');

   my $number   = $authors->count;
   my @ids      = $authors->id;
   my @distros  = $authors->distributions('RJBS');
   my $url      = $authors->avatar_url('RJBS');
   my $kwalitee = $authors->kwalitee('RJBS');

=head1 DESCRIPTION

This module lists 50 CPAN authors with the most scripts on CPAN. This list is
produced by querying a local mini CPAN mirror using this command:

 % lcpan authors-by-script-count | head -n 50

Statistics of the CPAN mirror:

 +---------------------+----------------------+
 | key                 | value                |
 +---------------------+----------------------+
 | cpan                | /home/u1/cpan        |
 | index_name          | index.db             |
 | last_index_time     | 2016-10-14T11:06:26Z |
 | raw_last_index_time | 1476443186           |
 +---------------------+----------------------+

Current ranking:

 +------+-----------+--------------+
 | rank | id        | script_count |
 +------+-----------+--------------+
 | 1    | PERLANCAR | 539          |
 | 2    | RSAVAGE   | 356          |
 | 3    | TRIZEN    | 313          |
 | 4    | BDFOY     | 173          |
 | 5    | SANTEX    | 140          |
 | 6    | MRDVT     | 137          |
 | 7    | JWB       | 126          |
 | 8    | VVELOX    | 125          |
 | 9    | CWEST     | 120          |
 | 10   | TSIBLEY   | 95           |
 | 11   | SHLOMIF   | 94           |
 | 12   | SDAGUE    | 91           |
 | 13   | LEOCHARRE | 88           |
 | 14   | CMUNGALL  | 87           |
 | 15   | LDS       | 76           |
 | 16   | RDO       | 75           |
 | 17   | AJPAGE    | 72           |
 | 18   | EASR      | 72           |
 | 19   | INGY      | 72           |
 | 20   | GSG       | 68           |
 | 21   | AMBS      | 67           |
 | 22   | MHOSKEN   | 67           |
 | 23   | BPOSTLE   | 60           |
 | 24   | MSIMERSON | 60           |
 | 25   | TBONE     | 57           |
 | 26   | GROUSSE   | 56           |
 | 27   | BRYCE     | 53           |
 | 28   | NKH       | 50           |
 | 29   | KESTEB    | 49           |
 | 30   | TIEDEMANN | 49           |
 | 31   | IVANWILLS | 47           |
 | 32   | MIYAGAWA  | 47           |
 | 33   | DHARD     | 46           |
 | 34   | PERRAD    | 46           |
 | 35   | FREDERICD | 45           |
 | 36   | YSAS      | 44           |
 | 37   | ADAMK     | 41           |
 | 38   | THORGIS   | 41           |
 | 39   | GWILLIAMS | 40           |
 | 40   | JASONS    | 39           |
 | 41   | AGENT     | 38           |
 | 42   | CDOLAN    | 38           |
 | 43   | GETTY     | 38           |
 | 44   | JMACFARLA | 38           |
 | 45   | TAPPER    | 38           |
 | 46   | AUTRIJUS  | 35           |
 | 47   | BEATNIK   | 35           |
 | 48   | ALEXMASS  | 34           |
 | 49   | BERNARD   | 34           |
 | 50   | NOTDOCTOR | 34           |
 +------+-----------+--------------+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANAuthors-CPAN-MostScripts>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANAuthors-CPAN-MostScripts>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANAuthors-CPAN-MostScripts>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANAuthors>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
