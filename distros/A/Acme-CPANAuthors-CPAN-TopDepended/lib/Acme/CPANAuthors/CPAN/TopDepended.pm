package Acme::CPANAuthors::CPAN::TopDepended;

our $DATE = '2016-10-20'; # DATE
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;

use Acme::CPANAuthors::Register (
    "EXODIST"   => "Chad Granum",                           #  18261
    "BINGOS"    => "Chris Williams",                        #  16214
    "RJBS"      => "Ricardo SIGNES",                        #  11423
    "ETHER"     => "Karen Etheridge",                       #   9019
    "LEONT"     => "Leon Timmermans",                       #   5635
    "DAGOLDEN"  => "David Golden",                          #   3949
    "GBARR"     => "Graham Barr",                           #   3653
    "PEVANS"    => "Paul Evans",                            #   3291
    "NEILB"     => "Neil Bowers",                           #   2952
    "GAAS"      => "Gisle Aas",                             #   2294
    "TODDR"     => "Todd Rinaldo",                          #   2243
    "SMUELLER"  => "Steffen Mueller",                       #   2173
    "DROLSKY"   => "Dave Rolsky",                           #   2155
    "CORION"    => "Max Maischein",                         #   1461
    "BARBIE"    => "Barbie",                                #   1408
    "TOKUHIROM" => "Tokuhiro Matsuno''<xmp>",               #   1286
    "REHSACK"   => "Jens Rehsack",                          #   1268
    "ADAMK"     => "Adam Kennedy",                          #   1223
    "ISHIGAKI"  => "Kenichi Ishigaki",                      #   1217
    "MIYAGAWA"  => "Tatsuhiko Miyagawa",                    #   1121
    "PERLANCAR" => "perlancar",                             #    968
    "MLEHMANN"  => "Marc A. Lehmann",                       #    967
    "HAARG"     => "Graham Knop",                           #    935
    "DANKOGAI"  => "Dan Kogai",                             #    929
    "JV"        => "Johan Vromans",                         #    906
    "RIBASUSHI" => "Peter Rabbitson",                       #    888
    "SHLOMIF"   => "Shlomi Fish",                           #    879
    "TIMB"      => "Tim Bunce",                             #    855
    "TOBYINK"   => "Toby Inkster",                          #    838
    "TINITA"    => "Tina Muller",                           #    826
    "JHI"       => "Jarkko Hietaniemi",                     #    812
    "BOBTFISH"  => "Tomas Doran",                           #    810
    "RICHE"     => "Richard Elberger",                      #    754
    "PLICEASE"  => "Graham Ollis",                          #    739
    "KASEI"     => "Marty Pauley",                          #    662
    "CHORNY"    => "Alexandr Ciornii",                      #    648
    "OVID"      => "Curtis 'Ovid' Poe",                     #    631
    "JJNAPIORK" => "John Napiorkowski",                     #    618
    "KWILLIAMS" => "Ken Williams",                          #    614
    "INGY"      => "Ingy dot Net",                          #    601
    "SRI"       => "Sebastian Riedel",                      #    600
    "MSCHILLI"  => "Michael Schilli",                       #    594
    "URI"       => "Uri Guttman",                           #    592
    "MAREKR"    => "Marek Rouchal",                         #    574
    "SYOHEX"    => "Syohei Yoshida",                        #    551
    "FREW"      => "Arthur Axel 'fREW' Schmidt",            #    547
    "ZEFRAM"    => "Andrew Main (Zefram)",                  #    532
    "ABW"       => "Andy Wardley",                          #    527
    "KENTNL"    => "Kent Fredric",                          #    524
    "AMS"       => "Abhijit Menon-Sen",                     #    511


);

1;
# ABSTRACT: Authors with the largest number of distributions depending on one of his/her modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::CPAN::TopDepended - Authors with the largest number of distributions depending on one of his/her modules

=head1 VERSION

This document describes version 0.003 of Acme::CPANAuthors::CPAN::TopDepended (from Perl distribution Acme-CPANAuthors-CPAN-TopDepended), released on 2016-10-20.

=head1 SYNOPSIS

   use Acme::CPANAuthors;
   use Acme::CPANAuthors::TopDepended;

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
 | 1    | EXODIST   | Chad Granum                | 18261      |
 | 2    | BINGOS    | Chris Williams             | 16214      |
 | 3    | RJBS      | Ricardo SIGNES             | 11423      |
 | 4    | ETHER     | Karen Etheridge            | 9019       |
 | 5    | LEONT     | Leon Timmermans            | 5635       |
 | 6    | DAGOLDEN  | David Golden               | 3949       |
 | 7    | GBARR     | Graham Barr                | 3653       |
 | 8    | PEVANS    | Paul Evans                 | 3291       |
 | 9    | NEILB     | Neil Bowers                | 2952       |
 | 10   | GAAS      | Gisle Aas                  | 2294       |
 | 11   | TODDR     | Todd Rinaldo               | 2243       |
 | 12   | SMUELLER  | Steffen Mueller            | 2173       |
 | 13   | DROLSKY   | Dave Rolsky                | 2155       |
 | 14   | CORION    | Max Maischein              | 1461       |
 | 15   | BARBIE    | Barbie                     | 1408       |
 | 16   | TOKUHIROM | Tokuhiro Matsuno''<xmp>    | 1286       |
 | 17   | REHSACK   | Jens Rehsack               | 1268       |
 | 18   | ADAMK     | Adam Kennedy               | 1223       |
 | 19   | ISHIGAKI  | Kenichi Ishigaki           | 1217       |
 | 20   | MIYAGAWA  | Tatsuhiko Miyagawa         | 1121       |
 | 21   | PERLANCAR | perlancar                  | 968        |
 | 22   | MLEHMANN  | Marc A. Lehmann            | 967        |
 | 23   | HAARG     | Graham Knop                | 935        |
 | 24   | DANKOGAI  | Dan Kogai                  | 929        |
 | 25   | JV        | Johan Vromans              | 906        |
 | 26   | RIBASUSHI | Peter Rabbitson            | 888        |
 | 27   | SHLOMIF   | Shlomi Fish                | 879        |
 | 28   | TIMB      | Tim Bunce                  | 855        |
 | 29   | TOBYINK   | Toby Inkster               | 838        |
 | 30   | TINITA    | Tina Muller                | 826        |
 | 31   | JHI       | Jarkko Hietaniemi          | 812        |
 | 32   | BOBTFISH  | Tomas Doran                | 810        |
 | 33   | RICHE     | Richard Elberger           | 754        |
 | 34   | PLICEASE  | Graham Ollis               | 739        |
 | 35   | KASEI     | Marty Pauley               | 662        |
 | 36   | CHORNY    | Alexandr Ciornii           | 648        |
 | 37   | OVID      | Curtis 'Ovid' Poe          | 631        |
 | 38   | JJNAPIORK | John Napiorkowski          | 618        |
 | 39   | KWILLIAMS | Ken Williams               | 614        |
 | 40   | INGY      | Ingy dot Net               | 601        |
 | 41   | SRI       | Sebastian Riedel           | 600        |
 | 42   | MSCHILLI  | Michael Schilli            | 594        |
 | 43   | URI       | Uri Guttman                | 592        |
 | 44   | MAREKR    | Marek Rouchal              | 574        |
 | 45   | SYOHEX    | Syohei Yoshida             | 551        |
 | 46   | FREW      | Arthur Axel 'fREW' Schmidt | 547        |
 | 47   | ZEFRAM    | Andrew Main (Zefram)       | 532        |
 | 48   | ABW       | Andy Wardley               | 527        |
 | 49   | KENTNL    | Kent Fredric               | 524        |
 | 50   | AMS       | Abhijit Menon-Sen          | 511        |
 +------+-----------+----------------------------+------------+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANAuthors-CPAN-TopDepended>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANAuthors-CPAN-TopDepended>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANAuthors-CPAN-TopDepended>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANAuthors>

L<Acme::CPANAuthors::CPAN::TopDepended::ByOthers>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
