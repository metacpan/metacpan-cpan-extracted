package Acme::CPANAuthors::CPAN::MostScripts;

our $DATE = '2021-06-07'; # DATE
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

use Acme::CPANAuthors::Register (
    "PERLANCAR" => undef,                                   #   1400
    "RSAVAGE"   => undef,                                   #    302
    "TULAMILI"  => undef,                                   #    226
    "BDFOY"     => undef,                                   #    175
    "TRIZEN"    => undef,                                   #    173
    "JWB"       => undef,                                   #    166
    "MRDVT"     => undef,                                   #    157
    "SANTEX"    => undef,                                   #    140
    "VVELOX"    => undef,                                   #    137
    "SHLOMIF"   => undef,                                   #    137
    "OLIVER"    => undef,                                   #    103
    "LDS"       => undef,                                   #    101
    "TSIBLEY"   => undef,                                   #     95
    "LEOCHARRE" => undef,                                   #     88
    "CMUNGALL"  => undef,                                   #     87
    "RDO"       => undef,                                   #     75
    "EASR"      => undef,                                   #     72
    "GSG"       => undef,                                   #     69
    "AMBS"      => undef,                                   #     68
    "BPOSTLE"   => undef,                                   #     63
    "INGY"      => undef,                                   #     61
    "IVANWILLS" => undef,                                   #     58
    "TBONE"     => undef,                                   #     57
    "TIEDEMANN" => undef,                                   #     56
    "MOOCOW"    => undef,                                   #     53
    "BRYCE"     => undef,                                   #     53
    "WOLDRICH"  => undef,                                   #     50
    "NKH"       => undef,                                   #     50
    "KESTEB"    => undef,                                   #     50
    "GROUSSE"   => undef,                                   #     48
    "CORION"    => undef,                                   #     47
    "PLICEASE"  => undef,                                   #     46
    "DHARD"     => undef,                                   #     46
    "YSAS"      => undef,                                   #     44
    "PERRAD"    => undef,                                   #     44
    "BEATNIK"   => undef,                                   #     44
    "MTW"       => undef,                                   #     43
    "MSIMERSON" => undef,                                   #     43
    "AJPAGE"    => undef,                                   #     43
    "DBAURAIN"  => undef,                                   #     42
    "GWILLIAMS" => undef,                                   #     41
    "CJFIELDS"  => undef,                                   #     41
    "VOJ"       => undef,                                   #     40
    "JILLROWE"  => undef,                                   #     40
    "TAPPER"    => undef,                                   #     39
    "JASONS"    => undef,                                   #     39
    "ADAMK"     => undef,                                   #     39
    "JMACFARLA" => undef,                                   #     38
    "GETTY"     => undef,                                   #     38
    "CDOLAN"    => undef,                                   #     38
);

1;
# ABSTRACT: Authors with the most scripts on CPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::CPAN::MostScripts - Authors with the most scripts on CPAN

=head1 VERSION

This document describes version 0.003 of Acme::CPANAuthors::CPAN::MostScripts (from Perl distribution Acme-CPANAuthors-CPAN-MostScripts), released on 2021-06-07.

=head1 SYNOPSIS

   use Acme::CPANAuthors;
   use Acme::CPANAuthors::CPAN::MostScripts;

   my $authors = Acme::CPANAuthors->new('CPAN::MostScripts');

   my $number   = $authors->count;
   my @ids      = $authors->id;
   my @distros  = $authors->distributions('PERLANCAR');
   my $url      = $authors->avatar_url('PERLANCAR');
   my $kwalitee = $authors->kwalitee('PERLANCAR');

=head1 DESCRIPTION

This module lists 50 CPAN authors with the most scripts on CPAN. This list is
produced by querying a local mini CPAN mirror using this command:

 % lcpan authors-by-script-count | head -n 50

Statistics of the CPAN mirror:

 +---------------------+--------------------------------+
 | key                 | value                          |
 +---------------------+--------------------------------+
 | cpan                | /home/u1/cpan                  |
 | index_name          | /media/minicpan-index/index.db |
 | last_index_time     | 2021-06-06T16:59:14Z           |
 | raw_last_index_time | 1622998754                     |
 +---------------------+--------------------------------+

Current ranking:

 +------+-----------+--------------+
 | rank | id        | script_count |
 +------+-----------+--------------+
 | 1    | PERLANCAR | 1400         |
 | 2    | RSAVAGE   | 302          |
 | 3    | TULAMILI  | 226          |
 | 4    | BDFOY     | 175          |
 | 5    | TRIZEN    | 173          |
 | 6    | JWB       | 166          |
 | 7    | MRDVT     | 157          |
 | 8    | SANTEX    | 140          |
 | 9    | VVELOX    | 137          |
 | 10   | SHLOMIF   | 137          |
 | 11   | OLIVER    | 103          |
 | 12   | LDS       | 101          |
 | 13   | TSIBLEY   | 95           |
 | 14   | LEOCHARRE | 88           |
 | 15   | CMUNGALL  | 87           |
 | 16   | RDO       | 75           |
 | 17   | EASR      | 72           |
 | 18   | GSG       | 69           |
 | 19   | AMBS      | 68           |
 | 20   | BPOSTLE   | 63           |
 | 21   | INGY      | 61           |
 | 22   | IVANWILLS | 58           |
 | 23   | TBONE     | 57           |
 | 24   | TIEDEMANN | 56           |
 | 25   | MOOCOW    | 53           |
 | 26   | BRYCE     | 53           |
 | 27   | WOLDRICH  | 50           |
 | 28   | NKH       | 50           |
 | 29   | KESTEB    | 50           |
 | 30   | GROUSSE   | 48           |
 | 31   | CORION    | 47           |
 | 32   | PLICEASE  | 46           |
 | 33   | DHARD     | 46           |
 | 34   | YSAS      | 44           |
 | 35   | PERRAD    | 44           |
 | 36   | BEATNIK   | 44           |
 | 37   | MTW       | 43           |
 | 38   | MSIMERSON | 43           |
 | 39   | AJPAGE    | 43           |
 | 40   | DBAURAIN  | 42           |
 | 41   | GWILLIAMS | 41           |
 | 42   | CJFIELDS  | 41           |
 | 43   | VOJ       | 40           |
 | 44   | JILLROWE  | 40           |
 | 45   | TAPPER    | 39           |
 | 46   | JASONS    | 39           |
 | 47   | ADAMK     | 39           |
 | 48   | JMACFARLA | 38           |
 | 49   | GETTY     | 38           |
 | 50   | CDOLAN    | 38           |
 +------+-----------+--------------+

=head1 CONTRIBUTOR

=for stopwords perlancar (@netbook-zenbook-ux305)

perlancar (@netbook-zenbook-ux305) <perlancar@gmail.com>

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

This software is copyright (c) 2021, 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
