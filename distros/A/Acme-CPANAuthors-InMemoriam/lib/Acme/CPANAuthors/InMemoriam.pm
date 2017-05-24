package Acme::CPANAuthors::InMemoriam;
use strict;
use warnings;

{
    no strict "vars";
    $VERSION = "1.07";
}

use Acme::CPANAuthors::Register (

    # Our fallen heroes, may they never be forgotten

    'AMORETTE'  => 'Hojung Yoon',
    'ANDREWF'   => 'Andrew Ford',
    'AVENJ'     => 'Jon Portnoy',
    'CKARG'     => 'Christian Karg',
    'ENCRYPTIO' => 'Chris Kastorff',
    'GARYAJ'    => 'Gary Ashton-Jones',
    'GMCCAR'    => 'Greg McCarroll',
    'IVORW'     => 'Ivor Williams',
    'JAITKEN'   => 'James Aitken',
    'NI-S'      => 'Nick Ing-Simmons',
    'NOBULL'    => 'Brian McCauley',
    'RKOBES'    => 'Randy Kobes',
    'SCHOP'     => 'Ariel Brosh',
    'SPOON'     => 'Iain Truskett',
    'SUGMAK'    => 'Makoto Sugiyama',
    'TADMC'     => 'Tad McClellan',
    'VSARKISS'  => 'Vahe Sarkissian'

);

q<
summer has come and passed
the innocent can never last
wake me up when September ends

ring out the bells again
like we did when spring began
wake me up when September ends

Lyrics copyright Green Daze Music, Billie Joe Armstrong, Frank Edwin Wright III, Michael Pritchard.
>

__END__

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::InMemoriam - Remembering our fallen heroes

=head1 DESCRIPTION

This class provides a hash of CPAN authors' PAUSE ID and name to be 
used with the C<Acme::CPANAuthors> module.

This module was created to remember those CPAN Authors who are no longer with
us, who have given us their inspiration in the form of code, to continue and
celebrate their time with us.

=head1 OUR HEROES

  AMORETTE      Hojung Yoon         d.2013
  ANDREWF       Andrew Ford         d.2014
  AVENJ         Jon Portnoy         d.2016
  CKARG         Christian Karg      d.2013
  ENCRYPTIO     Chris Kastorff      d.2017
  GARYAJ        Gary Ashton-Jones   d.2016
  GMCCAR        Greg McCarroll      d.2013
  IVORW         Ivor Williams       d.2009
  JAITKEN       James Aitken        d.2014
  NI-S          Nick Ing-Simmons    d.2006
  NOBULL        Brian McCauley      d.2015
  RKOBES        Randy Kobes         d.2010
  SCHOP         Ariel Brosh         d.2003
  SPOON         Iain Truskett       d.2003
  SUGMAK        Makoto Sugiyama     d.2010
  TADMC         Tad McClellan       d.2012
  VSARKISS      Vahe Sarkissian     d.2008

=head1 MAINTENANCE

If you are aware of any CPAN author that we have sadly lost, and who is not 
listed here, please send me their ID/name via email or RT, and I will update 
the module. If there are any mistakes, please contact me as soon as possible,
and I'll amend the entry right away.

=head1 SEE ALSO

L<Acme::CPANAuthors> - Main class to manipulate this one

=head1 SUPPORT

Bugs, patches and feature requests can be reported at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-CPANAuthors-InMemoriam>

=item * GitHub

L<http://github.com/barbie/acme-cpanauthors-inmemoriam>

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

  Copyright 2013-2017 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
