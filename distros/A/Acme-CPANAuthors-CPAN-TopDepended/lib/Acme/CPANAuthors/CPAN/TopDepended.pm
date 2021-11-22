package Acme::CPANAuthors::CPAN::TopDepended;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-17'; # DATE
our $DIST = 'Acme-CPANAuthors-CPAN-TopDepended'; # DIST
our $VERSION = '0.004'; # VERSION

use Acme::CPANAuthors::Register (
    "EXODIST"   => "Chad Granum",                           #  23543
    "BINGOS"    => "Chris Williams",                        #  21688
    "ETHER"     => "Karen Etheridge",                       #  14188
    "XSAWYERX"  => "Sawyer X",                              #  14045
    "TODDR"     => "Todd Rinaldo",                          #   9500
    "RJBS"      => "Ricardo SIGNES",                        #   9223
    "LEONT"     => "Leon Timmermans",                       #   7905
    "NEILB"     => "Neil Bowers",                           #   6666
    "HAARG"     => "Graham Knop",                           #   5168
    "OALDERS"   => "Olaf Alders",                           #   4678
    "PEVANS"    => "Paul Evans",                            #   4574
    "DAGOLDEN"  => "David Golden",                          #   4315
    "PETDANCE"  => "Andy Lester",                           #   2975
    "DROLSKY"   => "Dave Rolsky",                           #   2918
    "ISHIGAKI"  => "Kenichi Ishigaki",                      #   2913
    "BARBIE"    => "Barbie",                                #   2715
    "ATOOMIC"   => "icolas .",                              #   2703
    "CAPOEIRAB" => "Chase Whitener",                        #   2656
    "NWCLARK"   => "Nicholas Clark",                        #   2317
    "CORION"    => "Max Maischein",                         #   2017
    "PERLANCAR" => "perlancar",                             #   2011
    "REHSACK"   => "Jens Rehsack",                          #   1940
    "MIYAGAWA"  => "Tatsuhiko Miyagawa",                    #   1896
    "TOKUHIROM" => "Tokuhiro Matsuno''<xmp>",               #   1828
    "PLICEASE"  => "Graham Ollis",                          #   1823
    "SMUELLER"  => "Steffen Mueller",                       #   1559
    "DANKOGAI"  => "Dan Kogai",                             #   1416
    "TOBYINK"   => "Toby Inkster",                          #   1348
    "SKAJI"     => "Shoichi Kaji",                          #   1346
    "SHLOMIF"   => "Shlomi Fish",                           #   1307
    "JV"        => "Johan Vromans",                         #   1265
    "MLEHMANN"  => "Marc A. Lehmann",                       #   1250
    "TINITA"    => "Tina Muller",                           #   1246
    "JKEENAN"   => "James E Keenan",                        #   1165
    "APOCAL"    => "Apocalypse",                            #   1129
    "RIBASUSHI" => "Peter Rabbitson",                       #   1106
    "TIMB"      => "Tim Bunce",                             #   1048
    "SRI"       => "Sebastian Riedel",                      #    980
    "OVID"      => "Curtis 'Ovid' Poe",                     #    935
    "KENTNL"    => "Kent Fredric (PAUSE Custodial Account)", #    909
    "ZEFRAM"    => "Andrew Main (Zefram)",                  #    736
    "ETJ"       => "Ed J",                                  #    730
    "KASEI"     => "Marty Pauley",                          #    713
    "KWILLIAMS" => "Ken Williams",                          #    704
    "ABRAXXA"   => "Alexander Hartmaier",                   #    651
    "SYP"       => "Stanislaw Pusep",                       #    651
    "INGY"      => "Ingy dot Net",                          #    622
    "DOHERTY"   => "Mike Doherty",                          #    580
    "RTHOMPSON" => "Ryan C. Thompson",                      #    574
    "DOLMEN"    => "Olivier Mengue",                        #    570
);

1;
# ABSTRACT: Authors with the largest number of distributions depending on one of his/her modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::CPAN::TopDepended - Authors with the largest number of distributions depending on one of his/her modules

=head1 VERSION

This document describes version 0.004 of Acme::CPANAuthors::CPAN::TopDepended (from Perl distribution Acme-CPANAuthors-CPAN-TopDepended), released on 2021-11-17.

=head1 SYNOPSIS

   use Acme::CPANAuthors;
   use Acme::CPANAuthors::CPAN::TopDepended;

   my $authors = Acme::CPANAuthors->new('CPAN::TopDepended');

   my $number   = $authors->count;
   my @ids      = $authors->id;
   my @distros  = $authors->distributions('RJBS');
   my $url      = $authors->avatar_url('RJBS');
   my $kwalitee = $authors->kwalitee('RJBS');

=head1 DESCRIPTION

This module lists 50 CPAN authors with the largest number of distributions
directly depending to one of his/her modules. This list is produced by querying
a local mini CPAN mirror using this command:

 % lcpan authors-by-rdep-count | head -n 50

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

 +-----------+----------------------------------------+------------+------+
 | id        | name                                   | rdep_count | rank |
 +-----------+----------------------------------------+------------+------+
 | EXODIST   | Chad Granum                            | 23543      | 1    |
 | BINGOS    | Chris Williams                         | 21688      | 2    |
 | ETHER     | Karen Etheridge                        | 14188      | 3    |
 | XSAWYERX  | Sawyer X                               | 14045      | 4    |
 | TODDR     | Todd Rinaldo                           | 9500       | 5    |
 | RJBS      | Ricardo SIGNES                         | 9223       | 6    |
 | LEONT     | Leon Timmermans                        | 7905       | 7    |
 | NEILB     | Neil Bowers                            | 6666       | 8    |
 | HAARG     | Graham Knop                            | 5168       | 9    |
 | OALDERS   | Olaf Alders                            | 4678       | 10   |
 | PEVANS    | Paul Evans                             | 4574       | 11   |
 | DAGOLDEN  | David Golden                           | 4315       | 12   |
 | PETDANCE  | Andy Lester                            | 2975       | 13   |
 | DROLSKY   | Dave Rolsky                            | 2918       | 14   |
 | ISHIGAKI  | Kenichi Ishigaki                       | 2913       | 15   |
 | BARBIE    | Barbie                                 | 2715       | 16   |
 | ATOOMIC   | icolas .                               | 2703       | 17   |
 | CAPOEIRAB | Chase Whitener                         | 2656       | 18   |
 | NWCLARK   | Nicholas Clark                         | 2317       | 19   |
 | CORION    | Max Maischein                          | 2017       | 20   |
 | PERLANCAR | perlancar                              | 2011       | 21   |
 | REHSACK   | Jens Rehsack                           | 1940       | 22   |
 | MIYAGAWA  | Tatsuhiko Miyagawa                     | 1896       | 23   |
 | TOKUHIROM | Tokuhiro Matsuno''<xmp>                | 1828       | 24   |
 | PLICEASE  | Graham Ollis                           | 1823       | 25   |
 | SMUELLER  | Steffen Mueller                        | 1559       | 26   |
 | DANKOGAI  | Dan Kogai                              | 1416       | 27   |
 | TOBYINK   | Toby Inkster                           | 1348       | 28   |
 | SKAJI     | Shoichi Kaji                           | 1346       | 29   |
 | SHLOMIF   | Shlomi Fish                            | 1307       | 30   |
 | JV        | Johan Vromans                          | 1265       | 31   |
 | MLEHMANN  | Marc A. Lehmann                        | 1250       | 32   |
 | TINITA    | Tina Muller                            | 1246       | 33   |
 | JKEENAN   | James E Keenan                         | 1165       | 34   |
 | APOCAL    | Apocalypse                             | 1129       | 35   |
 | RIBASUSHI | Peter Rabbitson                        | 1106       | 36   |
 | TIMB      | Tim Bunce                              | 1048       | 37   |
 | SRI       | Sebastian Riedel                       | 980        | 38   |
 | OVID      | Curtis 'Ovid' Poe                      | 935        | 39   |
 | KENTNL    | Kent Fredric (PAUSE Custodial Account) | 909        | 40   |
 | ZEFRAM    | Andrew Main (Zefram)                   | 736        | 41   |
 | ETJ       | Ed J                                   | 730        | 42   |
 | KASEI     | Marty Pauley                           | 713        | 43   |
 | KWILLIAMS | Ken Williams                           | 704        | 44   |
 | ABRAXXA   | Alexander Hartmaier                    | 651        | =45  |
 | SYP       | Stanislaw Pusep                        | 651        | =45  |
 | INGY      | Ingy dot Net                           | 622        | 47   |
 | DOHERTY   | Mike Doherty                           | 580        | 48   |
 | RTHOMPSON | Ryan C. Thompson                       | 574        | 49   |
 | DOLMEN    | Olivier Mengue                         | 570        | 50   |
 +-----------+----------------------------------------+------------+------+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANAuthors-CPAN-TopDepended>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANAuthors-CPAN-TopDepended>.

=head1 SEE ALSO

L<Acme::CPANAuthors>

L<Acme::CPANAuthors::CPAN::TopDepended::ByOthers>

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

This software is copyright (c) 2021, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANAuthors-CPAN-TopDepended>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
