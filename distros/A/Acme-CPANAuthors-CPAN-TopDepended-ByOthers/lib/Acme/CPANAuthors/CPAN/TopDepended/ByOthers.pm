package Acme::CPANAuthors::CPAN::TopDepended::ByOthers;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-17'; # DATE
our $DIST = 'Acme-CPANAuthors-CPAN-TopDepended-ByOthers'; # DIST
our $VERSION = '0.004'; # VERSION

use Acme::CPANAuthors::Register (
    "EXODIST"   => "Chad Granum",                           #  23489
    "BINGOS"    => "Chris Williams",                        #  21476
    "XSAWYERX"  => "Sawyer X",                              #  13998
    "ETHER"     => "Karen Etheridge",                       #  13938
    "TODDR"     => "Todd Rinaldo",                          #   9492
    "RJBS"      => "Ricardo SIGNES",                        #   9053
    "LEONT"     => "Leon Timmermans",                       #   7833
    "NEILB"     => "Neil Bowers",                           #   6642
    "HAARG"     => "Graham Knop",                           #   5143
    "OALDERS"   => "Olaf Alders",                           #   4634
    "PEVANS"    => "Paul Evans",                            #   4398
    "DAGOLDEN"  => "David Golden",                          #   4184
    "PETDANCE"  => "Andy Lester",                           #   2967
    "ISHIGAKI"  => "Kenichi Ishigaki",                      #   2868
    "DROLSKY"   => "Dave Rolsky",                           #   2824
    "ATOOMIC"   => "icolas .",                              #   2698
    "CAPOEIRAB" => "Chase Whitener",                        #   2631
    "BARBIE"    => "Barbie",                                #   2603
    "NWCLARK"   => "Nicholas Clark",                        #   2316
    "CORION"    => "Max Maischein",                         #   1988
    "REHSACK"   => "Jens Rehsack",                          #   1905
    "MIYAGAWA"  => "Tatsuhiko Miyagawa",                    #   1819
    "TOKUHIROM" => "Tokuhiro Matsuno''<xmp>",               #   1711
    "PLICEASE"  => "Graham Ollis",                          #   1635
    "SMUELLER"  => "Steffen Mueller",                       #   1488
    "DANKOGAI"  => "Dan Kogai",                             #   1411
    "SKAJI"     => "Shoichi Kaji",                          #   1337
    "JV"        => "Johan Vromans",                         #   1251
    "TINITA"    => "Tina Muller",                           #   1229
    "MLEHMANN"  => "Marc A. Lehmann",                       #   1188
    "SHLOMIF"   => "Shlomi Fish",                           #   1166
    "JKEENAN"   => "James E Keenan",                        #   1154
    "TOBYINK"   => "Toby Inkster",                          #   1142
    "APOCAL"    => "Apocalypse",                            #   1122
    "RIBASUSHI" => "Peter Rabbitson",                       #   1104
    "TIMB"      => "Tim Bunce",                             #   1042
    "SRI"       => "Sebastian Riedel",                      #    976
    "OVID"      => "Curtis 'Ovid' Poe",                     #    919
    "KENTNL"    => "Kent Fredric (PAUSE Custodial Account)", #    741
    "KASEI"     => "Marty Pauley",                          #    713
    "KWILLIAMS" => "Ken Williams",                          #    702
    "ZEFRAM"    => "Andrew Main (Zefram)",                  #    694
    "ETJ"       => "Ed J",                                  #    685
    "SYP"       => "Stanislaw Pusep",                       #    647
    "ABRAXXA"   => "Alexander Hartmaier",                   #    640
    "DOHERTY"   => "Mike Doherty",                          #    574
    "RTHOMPSON" => "Ryan C. Thompson",                      #    570
    "DOLMEN"    => "Olivier Mengue",                        #    567
    "GARU"      => "Breno G. de Oliveira",                  #    552
    "RURBAN"    => "Reini Urban",                           #    549
);

1;
# ABSTRACT: Authors with the largest number of other authors' distributions depending on one of his/her modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::CPAN::TopDepended::ByOthers - Authors with the largest number of other authors' distributions depending on one of his/her modules

=head1 VERSION

This document describes version 0.004 of Acme::CPANAuthors::CPAN::TopDepended::ByOthers (from Perl distribution Acme-CPANAuthors-CPAN-TopDepended-ByOthers), released on 2021-11-17.

=head1 SYNOPSIS

   use Acme::CPANAuthors;
   use Acme::CPANAuthors::CPAN::TopDepended::ByOthers;

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
 | EXODIST   | Chad Granum                            | 23489      | 1    |
 | BINGOS    | Chris Williams                         | 21476      | 2    |
 | XSAWYERX  | Sawyer X                               | 13998      | 3    |
 | ETHER     | Karen Etheridge                        | 13938      | 4    |
 | TODDR     | Todd Rinaldo                           | 9492       | 5    |
 | RJBS      | Ricardo SIGNES                         | 9053       | 6    |
 | LEONT     | Leon Timmermans                        | 7833       | 7    |
 | NEILB     | Neil Bowers                            | 6642       | 8    |
 | HAARG     | Graham Knop                            | 5143       | 9    |
 | OALDERS   | Olaf Alders                            | 4634       | 10   |
 | PEVANS    | Paul Evans                             | 4398       | 11   |
 | DAGOLDEN  | David Golden                           | 4184       | 12   |
 | PETDANCE  | Andy Lester                            | 2967       | 13   |
 | ISHIGAKI  | Kenichi Ishigaki                       | 2868       | 14   |
 | DROLSKY   | Dave Rolsky                            | 2824       | 15   |
 | ATOOMIC   | icolas .                               | 2698       | 16   |
 | CAPOEIRAB | Chase Whitener                         | 2631       | 17   |
 | BARBIE    | Barbie                                 | 2603       | 18   |
 | NWCLARK   | Nicholas Clark                         | 2316       | 19   |
 | CORION    | Max Maischein                          | 1988       | 20   |
 | REHSACK   | Jens Rehsack                           | 1905       | 21   |
 | MIYAGAWA  | Tatsuhiko Miyagawa                     | 1819       | 22   |
 | TOKUHIROM | Tokuhiro Matsuno''<xmp>                | 1711       | 23   |
 | PLICEASE  | Graham Ollis                           | 1635       | 24   |
 | SMUELLER  | Steffen Mueller                        | 1488       | 25   |
 | DANKOGAI  | Dan Kogai                              | 1411       | 26   |
 | SKAJI     | Shoichi Kaji                           | 1337       | 27   |
 | JV        | Johan Vromans                          | 1251       | 28   |
 | TINITA    | Tina Muller                            | 1229       | 29   |
 | MLEHMANN  | Marc A. Lehmann                        | 1188       | 30   |
 | SHLOMIF   | Shlomi Fish                            | 1166       | 31   |
 | JKEENAN   | James E Keenan                         | 1154       | 32   |
 | TOBYINK   | Toby Inkster                           | 1142       | 33   |
 | APOCAL    | Apocalypse                             | 1122       | 34   |
 | RIBASUSHI | Peter Rabbitson                        | 1104       | 35   |
 | TIMB      | Tim Bunce                              | 1042       | 36   |
 | SRI       | Sebastian Riedel                       | 976        | 37   |
 | OVID      | Curtis 'Ovid' Poe                      | 919        | 38   |
 | KENTNL    | Kent Fredric (PAUSE Custodial Account) | 741        | 39   |
 | KASEI     | Marty Pauley                           | 713        | 40   |
 | KWILLIAMS | Ken Williams                           | 702        | 41   |
 | ZEFRAM    | Andrew Main (Zefram)                   | 694        | 42   |
 | ETJ       | Ed J                                   | 685        | 43   |
 | SYP       | Stanislaw Pusep                        | 647        | 44   |
 | ABRAXXA   | Alexander Hartmaier                    | 640        | 45   |
 | DOHERTY   | Mike Doherty                           | 574        | 46   |
 | RTHOMPSON | Ryan C. Thompson                       | 570        | 47   |
 | DOLMEN    | Olivier Mengue                         | 567        | 48   |
 | GARU      | Breno G. de Oliveira                   | 552        | 49   |
 | RURBAN    | Reini Urban                            | 549        | 50   |
 +-----------+----------------------------------------+------------+------+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Acme-CPANAuthors-CPAN-TopDepended-ByOthers>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Acme-CPANAuthors-CPAN-TopDepended-ByOthers>.

=head1 SEE ALSO

L<Acme::CPANAuthors>

L<Acme::CPANAuthors::CPAN::TopDepended>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-CPANAuthors-CPAN-TopDepended-ByOthers>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
