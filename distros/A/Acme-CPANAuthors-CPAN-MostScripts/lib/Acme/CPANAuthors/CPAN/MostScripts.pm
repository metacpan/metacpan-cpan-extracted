package Acme::CPANAuthors::CPAN::MostScripts;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-17'; # DATE
our $DIST = 'Acme-CPANAuthors-CPAN-MostScripts'; # DIST
our $VERSION = '0.004'; # VERSION

use Acme::CPANAuthors::Register (
    "PERLANCAR" => undef,                                   #   1436
    "RSAVAGE"   => undef,                                   #    302
    "TULAMILI"  => undef,                                   #    224
    "BDFOY"     => undef,                                   #    176
    "TRIZEN"    => undef,                                   #    173
    "JWB"       => undef,                                   #    166
    "SANTEX"    => undef,                                   #    140
    "MRDVT"     => undef,                                   #    140
    "SHLOMIF"   => undef,                                   #    138
    "VVELOX"    => undef,                                   #    137
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
    "WOLDRICH"  => undef,                                   #     52
    "NKH"       => undef,                                   #     50
    "KESTEB"    => undef,                                   #     50
    "CORION"    => undef,                                   #     49
    "PLICEASE"  => undef,                                   #     48
    "GROUSSE"   => undef,                                   #     48
    "DHARD"     => undef,                                   #     46
    "DBAURAIN"  => undef,                                   #     46
    "YSAS"      => undef,                                   #     44
    "PERRAD"    => undef,                                   #     44
    "BEATNIK"   => undef,                                   #     44
    "MTW"       => undef,                                   #     43
    "MSIMERSON" => undef,                                   #     43
    "AJPAGE"    => undef,                                   #     43
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

This document describes version 0.004 of Acme::CPANAuthors::CPAN::MostScripts (from Perl distribution Acme-CPANAuthors-CPAN-MostScripts), released on 2021-11-17.

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
 | last_index_time     | 2021-11-16T19:50:46Z           |
 | raw_last_index_time | 1637092246                     |
 +---------------------+--------------------------------+

Current ranking:

 +------+-----------+--------------+
 | rank | id        | script_count |
 +------+-----------+--------------+
 | 1    | PERLANCAR | 1436         |
 | 2    | RSAVAGE   | 302          |
 | 3    | TULAMILI  | 224          |
 | 4    | BDFOY     | 176          |
 | 5    | TRIZEN    | 173          |
 | 6    | JWB       | 166          |
 | =7   | SANTEX    | 140          |
 | =7   | MRDVT     | 140          |
 | 9    | SHLOMIF   | 138          |
 | 10   | VVELOX    | 137          |
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
 | =25  | MOOCOW    | 53           |
 | =25  | BRYCE     | 53           |
 | 27   | WOLDRICH  | 52           |
 | =28  | NKH       | 50           |
 | =28  | KESTEB    | 50           |
 | 30   | CORION    | 49           |
 | =31  | PLICEASE  | 48           |
 | =31  | GROUSSE   | 48           |
 | =33  | DHARD     | 46           |
 | =33  | DBAURAIN  | 46           |
 | =35  | YSAS      | 44           |
 | =35  | PERRAD    | 44           |
 | =35  | BEATNIK   | 44           |
 | =38  | MTW       | 43           |
 | =38  | MSIMERSON | 43           |
 | =38  | AJPAGE    | 43           |
 | =41  | GWILLIAMS | 41           |
 | =41  | CJFIELDS  | 41           |
 | =43  | VOJ       | 40           |
 | =43  | JILLROWE  | 40           |
 | =45  | TAPPER    | 39           |
 | =45  | JASONS    | 39           |
 | =45  | ADAMK     | 39           |
 | =48  | JMACFARLA | 38           |
 | =48  | GETTY     | 38           |
 | =48  | CDOLAN    | 38           |
 +------+-----------+--------------+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANAuthors-CPAN-MostScripts>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANAuthors-CPAN-MostScripts>.

=head1 SEE ALSO

L<Acme::CPANAuthors>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANAuthors-CPAN-MostScripts>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
