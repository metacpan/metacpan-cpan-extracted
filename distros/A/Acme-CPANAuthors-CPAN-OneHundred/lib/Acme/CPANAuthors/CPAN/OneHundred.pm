package Acme::CPANAuthors::CPAN::OneHundred;
use strict;
use warnings;

{
    no strict "vars";
    $VERSION = "1.14";
}

use Acme::CPANAuthors::Register (

    'ADAMK'         => 'Adam Kennedy',
    'AUTRIJUS'      => 'Audrey Tang',
    'BARBIE'        => 'Barbie',
    'BDFOY'         => 'brian d foy',
    'BINGOS'        => 'Chris Williams',
    'BOBTFISH'      => 'Tomas Doran',
    'DAGOLDEN'      => 'David Golden',
    'DMAKI'         => 'Daisuke Maki',
    'DROLSKY'       => 'Dave Rolsky',
    'ETHER'         => 'Karen Etheridge',
    'FAYLAND'       => 'Fayland Lin',
    'FLORA'         => 'Florian Ragwitz',
    'GUGOD'         => 'Liu Kang Min',
    'INGY'          => 'Ingy dot Net',
    'JGNI'          => 'John Imrie',
    'KENTNL'        => 'Kent Fredric',
    'LBROCARD'      => 'Leon Brocard',
    'MANWAR'        => 'Mohammad S Anwar',
    'MARCEL'        => 'Marcel Gruenauer',
    'MIYAGAWA'      => 'Tatsuhiko Miyagawa',
    'MLEHMANN'      => '???',
    'MRAMBERG'      => 'Marcus Ramberg',
    'NEILB'         => 'Neil Bowers',
    'NUFFIN'        => 'Yuval Kogman',
    'PERLANCAR'     => 'perlancar',
    'PEVANS'        => 'Paul Evans',
    'PLICEASE'      => 'Graham Ollis',
    'PSIXDISTS'     => 'Perl 6 Modules',
    'RENEEB'        => 'Renee Baecker',
    'RJBS'          => 'Ricardo SIGNES',
    'RSAVAGE'       => 'Ron Savage',
    'SALVA'         => 'Salvador Fandino Garcia',
    'SHLOMIF'       => 'Shlomi Fish',
    'SIMON'         => 'Simon Cozens',
    'SKIM'          => 'Michal Josef Spacek',
    'SMUELLER'      => 'Steffen Mueller',
    'TEAM'          => 'Tom Molesworth',
    'TOBYINK'       => 'Toby Inkster',
    'TOKUHIROM'     => '???',
    'VVELOX'        => '???',
    'YANICK'        => 'Yanick Champoux',

);

q<
We are programmed just to do
Anything you want us to

We are the robots, we are the robots
We are the robots, we are the robots

Lyrics copyright Ralf Hütter
>

__END__

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::CPAN::OneHundred - The CPAN Authors who have 100+ distributions on CPAN

=head1 DESCRIPTION

This class provides a hash of CPAN authors' PAUSE ID and name to be 
used with the C<Acme::CPANAuthors> module.

This module was created to capture all those CPAN Authors who have valiantly
submitted their modules and distributions to CPAN, and now have the honour of
currently maintaining 100 or more distributions on CPAN.

=head1 THE AUTHORS

   1.  1765  PERLANCAR     perlancar
   2.  550  PSIXDISTS     Perl 6 Modules
   3.  296  RJBS          Ricardo SIGNES
   4.  282  TOBYINK       Toby Inkster
   5.  266  ETHER         Karen Etheridge
   6.  247  ADAMK         Adam Kennedy
   7.  245  JGNI          John Imrie
   8.  240  MIYAGAWA      Tatsuhiko Miyagawa
   9.  219  INGY          Ingy dot Net
  10.  215  BINGOS        Chris Williams
  11.  209  FLORA         Florian Ragwitz
  12.  185  KENTNL        Kent Fredric
  13.  185  SMUELLER      Steffen Mueller
  14.  182  TOKUHIROM     ???
  15.  180  DAGOLDEN      David Golden
  16.  169  PLICEASE      Graham Ollis
  17.  168  PEVANS        Paul Evans
  18.  158  NUFFIN        Yuval Kogman
  19.  156  DROLSKY       Dave Rolsky
  20.  152  BOBTFISH      Tomas Doran
  21.  152  SHLOMIF       Shlomi Fish
  22.  147  MARCEL        Marcel Gruenauer
  23.  140  SKIM          Michal Josef Spacek
  24.  135  NEILB         Neil Bowers
  25.  133  GUGOD         Liu Kang Min
  26.  122  DMAKI         Daisuke Maki
  27.  118  MANWAR        Mohammad S Anwar
  28.  118  SIMON         Simon Cozens
  29.  117  BARBIE        Barbie
  30.  117  RSAVAGE       Ron Savage
  31.  112  AUTRIJUS      Audrey Tang
  32.  112  MRAMBERG      Marcus Ramberg
  33.  112  SALVA         Salvador Fandino Garcia
  34.  109  YANICK        Yanick Champoux
  35.  108  FAYLAND       Fayland Lin
  36.  108  MLEHMANN      ???
  37.  103  BDFOY         brian d foy
  38.  103  RENEEB        Renee Baecker
  39.  103  VVELOX        ???
  40.  102  TEAM          Tom Molesworth
  41.  101  LBROCARD      Leon Brocard

List last updated: 2019-08-11T07:18:35

=head1 MAINTENANCE

If you are aware of any CPAN author that has attained the heady heights of 100
distributions on CPAN, and who is not listed here, please send me their ID/name
via email or RT, and I will update the module. If there are any mistakes, 
please contact me as soon as possible, and I'll amend the entry right away.

=head1 SEE ALSO

L<Acme::CPANAuthors> - Main class to manipulate this one.

L<Acme::CPANAuthors::BackPAN::OneHundred> - 100+ distributions on BackPAN.

=head1 SUPPORT

Bugs, patches and feature requests can be reported at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-CPANAuthors-CPAN-OneHundred>

=item * GitHub

L<http://github.com/barbie/acme-cpanauthors-cpan-onehundred>

=back

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to 
the RT queue. However, it would help greatly if you are able to pinpoint 
problems or even supply a patch. 

Fixes are dependent upon their severity and my availability. Should a fix 
not be forthcoming, please feel free to (politely) remind me.

=head1 ACKNOWLEDGEMENTS

Thanks to Kenichi Ishigaki for writing C<Acme::CPANAuthors>.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT & LICENSE

  Copyright 2014-2019 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
