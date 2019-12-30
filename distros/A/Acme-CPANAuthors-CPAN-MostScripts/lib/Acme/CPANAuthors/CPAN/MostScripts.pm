package Acme::CPANAuthors::CPAN::MostScripts;

our $DATE = '2019-12-23'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use Acme::CPANAuthors::Register (
    "PERLANCAR" => undef,                                   #   1115
    "RSAVAGE"   => undef,                                   #    375
    "BDFOY"     => undef,                                   #    174
    "JWB"       => undef,                                   #    166
    "SANTEX"    => undef,                                   #    140
    "MRDVT"     => undef,                                   #    139
    "VVELOX"    => undef,                                   #    134
    "CWEST"     => undef,                                   #    120
    "SHLOMIF"   => undef,                                   #    112
    "LDS"       => undef,                                   #    101
    "TSIBLEY"   => undef,                                   #     95
    "TULAMILI"  => undef,                                   #     95
    "SDAGUE"    => undef,                                   #     91
    "OLIVER"    => undef,                                   #     90
    "LEOCHARRE" => undef,                                   #     88
    "CMUNGALL"  => undef,                                   #     87
    "RDO"       => undef,                                   #     75
    "EASR"      => undef,                                   #     72
    "GSG"       => undef,                                   #     69
    "AMBS"      => undef,                                   #     68
    "BPOSTLE"   => undef,                                   #     63
    "INGY"      => undef,                                   #     60
    "IVANWILLS" => undef,                                   #     58
    "TBONE"     => undef,                                   #     57
    "GROUSSE"   => undef,                                   #     56
    "BRYCE"     => undef,                                   #     53
    "MOOCOW"    => undef,                                   #     51
    "KESTEB"    => undef,                                   #     50
    "NKH"       => undef,                                   #     50
    "WOLDRICH"  => undef,                                   #     50
    "TIEDEMANN" => undef,                                   #     49
    "DHARD"     => undef,                                   #     46
    "PERRAD"    => undef,                                   #     46
    "BEATNIK"   => undef,                                   #     44
    "YSAS"      => undef,                                   #     44
    "AJPAGE"    => undef,                                   #     43
    "MSIMERSON" => undef,                                   #     43
    "MTW"       => undef,                                   #     43
    "CORION"    => undef,                                   #     41
    "JLMARTIN"  => undef,                                   #     41
    "ADAMK"     => undef,                                   #     40
    "JILLROWE"  => undef,                                   #     40
    "PLICEASE"  => undef,                                   #     40
    "GETTY"     => undef,                                   #     39
    "JASONS"    => undef,                                   #     39
    "TAPPER"    => undef,                                   #     39
    "CDOLAN"    => undef,                                   #     38
    "JMACFARLA" => undef,                                   #     38
    "PEVANS"    => undef,                                   #     38
    "GWILLIAMS" => undef,                                   #     37


);

1;
# ABSTRACT: Authors with the most scripts on CPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::CPAN::MostScripts - Authors with the most scripts on CPAN

=head1 VERSION

This document describes version 0.002 of Acme::CPANAuthors::CPAN::MostScripts (from Perl distribution Acme-CPANAuthors-CPAN-MostScripts), released on 2019-12-23.

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

 +---------------------+--------------------------------+
 | key                 | value                          |
 +---------------------+--------------------------------+
 | cpan                | /home/s1/cpan                  |
 | index_name          | /media/minicpan-index/index.db |
 | last_index_time     | 2019-12-22T12:19:08Z           |
 | raw_last_index_time | 1577017148                     |
 +---------------------+--------------------------------+

Current ranking:

 +------+-----------+--------------+
 | rank | id        | script_count |
 +------+-----------+--------------+
 | 1    | PERLANCAR | 1115         |
 | 2    | RSAVAGE   | 375          |
 | 3    | BDFOY     | 174          |
 | 4    | JWB       | 166          |
 | 5    | SANTEX    | 140          |
 | 6    | MRDVT     | 139          |
 | 7    | VVELOX    | 134          |
 | 8    | CWEST     | 120          |
 | 9    | SHLOMIF   | 112          |
 | 10   | LDS       | 101          |
 | 11   | TSIBLEY   | 95           |
 | 12   | TULAMILI  | 95           |
 | 13   | SDAGUE    | 91           |
 | 14   | OLIVER    | 90           |
 | 15   | LEOCHARRE | 88           |
 | 16   | CMUNGALL  | 87           |
 | 17   | RDO       | 75           |
 | 18   | EASR      | 72           |
 | 19   | GSG       | 69           |
 | 20   | AMBS      | 68           |
 | 21   | BPOSTLE   | 63           |
 | 22   | INGY      | 60           |
 | 23   | IVANWILLS | 58           |
 | 24   | TBONE     | 57           |
 | 25   | GROUSSE   | 56           |
 | 26   | BRYCE     | 53           |
 | 27   | MOOCOW    | 51           |
 | 28   | KESTEB    | 50           |
 | 29   | NKH       | 50           |
 | 30   | WOLDRICH  | 50           |
 | 31   | TIEDEMANN | 49           |
 | 32   | DHARD     | 46           |
 | 33   | PERRAD    | 46           |
 | 34   | BEATNIK   | 44           |
 | 35   | YSAS      | 44           |
 | 36   | AJPAGE    | 43           |
 | 37   | MSIMERSON | 43           |
 | 38   | MTW       | 43           |
 | 39   | CORION    | 41           |
 | 40   | JLMARTIN  | 41           |
 | 41   | ADAMK     | 40           |
 | 42   | JILLROWE  | 40           |
 | 43   | PLICEASE  | 40           |
 | 44   | GETTY     | 39           |
 | 45   | JASONS    | 39           |
 | 46   | TAPPER    | 39           |
 | 47   | CDOLAN    | 38           |
 | 48   | JMACFARLA | 38           |
 | 49   | PEVANS    | 38           |
 | 50   | GWILLIAMS | 37           |
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

This software is copyright (c) 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
