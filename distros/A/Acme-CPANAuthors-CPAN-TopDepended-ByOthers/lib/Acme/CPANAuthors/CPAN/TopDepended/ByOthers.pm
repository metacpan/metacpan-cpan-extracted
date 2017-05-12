package Acme::CPANAuthors::CPAN::TopDepended::ByOthers;

our $DATE = '2016-10-20'; # DATE
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

use Acme::CPANAuthors::Register (
    "EXODIST"   => "Chad Granum",                           #  18222
    "BINGOS"    => "Chris Williams",                        #  16017
    "RJBS"      => "Ricardo SIGNES",                        #  11190
    "ETHER"     => "Karen Etheridge",                       #   8831
    "LEONT"     => "Leon Timmermans",                       #   5579
    "DAGOLDEN"  => "David Golden",                          #   3805
    "GBARR"     => "Graham Barr",                           #   3650
    "PEVANS"    => "Paul Evans",                            #   3179
    "NEILB"     => "Neil Bowers",                           #   2930
    "GAAS"      => "Gisle Aas",                             #   2284
    "TODDR"     => "Todd Rinaldo",                          #   2240
    "SMUELLER"  => "Steffen Mueller",                       #   2094
    "DROLSKY"   => "Dave Rolsky",                           #   2086
    "CORION"    => "Max Maischein",                         #   1452
    "BARBIE"    => "Barbie",                                #   1297
    "REHSACK"   => "Jens Rehsack",                          #   1241
    "TOKUHIROM" => "Tokuhiro Matsuno''<xmp>",               #   1174
    "ISHIGAKI"  => "Kenichi Ishigaki",                      #   1173
    "ADAMK"     => "Adam Kennedy",                          #   1087
    "MIYAGAWA"  => "Tatsuhiko Miyagawa",                    #   1060
    "HAARG"     => "Graham Knop",                           #    927
    "DANKOGAI"  => "Dan Kogai",                             #    925
    "MLEHMANN"  => "Marc A. Lehmann",                       #    912
    "JV"        => "Johan Vromans",                         #    894
    "RIBASUSHI" => "Peter Rabbitson",                       #    887
    "TIMB"      => "Tim Bunce",                             #    847
    "SHLOMIF"   => "Shlomi Fish",                           #    845
    "TINITA"    => "Tina Muller",                           #    818
    "JHI"       => "Jarkko Hietaniemi",                     #    810
    "BOBTFISH"  => "Tomas Doran",                           #    773
    "RICHE"     => "Richard Elberger",                      #    754
    "TOBYINK"   => "Toby Inkster",                          #    681
    "KASEI"     => "Marty Pauley",                          #    662
    "PLICEASE"  => "Graham Ollis",                          #    661
    "CHORNY"    => "Alexandr Ciornii",                      #    646
    "OVID"      => "Curtis 'Ovid' Poe",                     #    619
    "KWILLIAMS" => "Ken Williams",                          #    612
    "SRI"       => "Sebastian Riedel",                      #    598
    "URI"       => "Uri Guttman",                           #    591
    "MAREKR"    => "Marek Rouchal",                         #    573
    "JJNAPIORK" => "John Napiorkowski",                     #    572
    "SYOHEX"    => "Syohei Yoshida",                        #    545
    "MSCHILLI"  => "Michael Schilli",                       #    541
    "FREW"      => "Arthur Axel 'fREW' Schmidt",            #    530
    "ABW"       => "Andy Wardley",                          #    524
    "AMS"       => "Abhijit Menon-Sen",                     #    511
    "INGY"      => "Ingy dot Net",                          #    504
    "ZEFRAM"    => "Andrew Main (Zefram)",                  #    491
    "SARTAK"    => "Shawn M Moore",                         #    472
    "GRANTM"    => "Grant McLean",                          #    463


);

1;
# ABSTRACT: Authors with the largest number of other authors' distributions depending on one of his/her modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::CPAN::TopDepended::ByOthers - Authors with the largest number of other authors' distributions depending on one of his/her modules

=head1 VERSION

This document describes version 0.003 of Acme::CPANAuthors::CPAN::TopDepended::ByOthers (from Perl distribution Acme-CPANAuthors-CPAN-TopDepended-ByOthers), released on 2016-10-20.

=head1 SYNOPSIS

   use Acme::CPANAuthors;
   use Acme::CPANAuthors::TopDepended::ByOthers;

   my $authors = Acme::CPANAuthors->new('CPAN::TopDepended::ByOthers');

   my $number   = $authors->count;
   my @ids      = $authors->id;
   my @distros  = $authors->distributions('RJBS');
   my $url      = $authors->avatar_url('RJBS');
   my $kwalitee = $authors->kwalitee('RJBS');

=head1 DESCRIPTION

This module, like L<Acme::CPANAuthors::CPAN::TopDepended>, lists 50 CPAN authors
with the largest number of distributions directly depending to one of his/her
modules. The difference is, only distributions by other authors are counted.
This in some cases might be a better indication of how "depended upon" an author
is, as some authors might have modules that are mostly depended by his/her own
distributions.

This list is produced by querying a local mini CPAN mirror using this command:

 % lcpan authors-by-rdep-count --exclude-same-author | head -n 50

Statistics of the CPAN mirror:

 +---------------------+----------------------+
 | key                 | value                |
 +---------------------+----------------------+
 | cpan                | /home/s1/cpan        |
 | index_name          | index.db             |
 | last_index_time     | 2016-10-20T11:45:05Z |
 | raw_last_index_time | 1476963905           |
 +---------------------+----------------------+

Current ranking:

 +------+-----------+----------------------------+------------+
 | rank | id        | name                       | rdep_count |
 +------+-----------+----------------------------+------------+
 | 1    | EXODIST   | Chad Granum                | 18222      |
 | 2    | BINGOS    | Chris Williams             | 16017      |
 | 3    | RJBS      | Ricardo SIGNES             | 11190      |
 | 4    | ETHER     | Karen Etheridge            | 8831       |
 | 5    | LEONT     | Leon Timmermans            | 5579       |
 | 6    | DAGOLDEN  | David Golden               | 3805       |
 | 7    | GBARR     | Graham Barr                | 3650       |
 | 8    | PEVANS    | Paul Evans                 | 3179       |
 | 9    | NEILB     | Neil Bowers                | 2930       |
 | 10   | GAAS      | Gisle Aas                  | 2284       |
 | 11   | TODDR     | Todd Rinaldo               | 2240       |
 | 12   | SMUELLER  | Steffen Mueller            | 2094       |
 | 13   | DROLSKY   | Dave Rolsky                | 2086       |
 | 14   | CORION    | Max Maischein              | 1452       |
 | 15   | BARBIE    | Barbie                     | 1297       |
 | 16   | REHSACK   | Jens Rehsack               | 1241       |
 | 17   | TOKUHIROM | Tokuhiro Matsuno''<xmp>    | 1174       |
 | 18   | ISHIGAKI  | Kenichi Ishigaki           | 1173       |
 | 19   | ADAMK     | Adam Kennedy               | 1087       |
 | 20   | MIYAGAWA  | Tatsuhiko Miyagawa         | 1060       |
 | 21   | HAARG     | Graham Knop                | 927        |
 | 22   | DANKOGAI  | Dan Kogai                  | 925        |
 | 23   | MLEHMANN  | Marc A. Lehmann            | 912        |
 | 24   | JV        | Johan Vromans              | 894        |
 | 25   | RIBASUSHI | Peter Rabbitson            | 887        |
 | 26   | TIMB      | Tim Bunce                  | 847        |
 | 27   | SHLOMIF   | Shlomi Fish                | 845        |
 | 28   | TINITA    | Tina Muller                | 818        |
 | 29   | JHI       | Jarkko Hietaniemi          | 810        |
 | 30   | BOBTFISH  | Tomas Doran                | 773        |
 | 31   | RICHE     | Richard Elberger           | 754        |
 | 32   | TOBYINK   | Toby Inkster               | 681        |
 | 33   | KASEI     | Marty Pauley               | 662        |
 | 34   | PLICEASE  | Graham Ollis               | 661        |
 | 35   | CHORNY    | Alexandr Ciornii           | 646        |
 | 36   | OVID      | Curtis 'Ovid' Poe          | 619        |
 | 37   | KWILLIAMS | Ken Williams               | 612        |
 | 38   | SRI       | Sebastian Riedel           | 598        |
 | 39   | URI       | Uri Guttman                | 591        |
 | 40   | MAREKR    | Marek Rouchal              | 573        |
 | 41   | JJNAPIORK | John Napiorkowski          | 572        |
 | 42   | SYOHEX    | Syohei Yoshida             | 545        |
 | 43   | MSCHILLI  | Michael Schilli            | 541        |
 | 44   | FREW      | Arthur Axel 'fREW' Schmidt | 530        |
 | 45   | ABW       | Andy Wardley               | 524        |
 | 46   | AMS       | Abhijit Menon-Sen          | 511        |
 | 47   | INGY      | Ingy dot Net               | 504        |
 | 48   | ZEFRAM    | Andrew Main (Zefram)       | 491        |
 | 49   | SARTAK    | Shawn M Moore              | 472        |
 | 50   | GRANTM    | Grant McLean               | 463        |
 +------+-----------+----------------------------+------------+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANAuthors-CPAN-TopDepended-ByOthers>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANAuthors-CPAN-TopDepended-ByOthers>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANAuthors-CPAN-TopDepended-ByOthers>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANAuthors>

L<Acme::CPANAuthors::CPAN::TopDepended>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
