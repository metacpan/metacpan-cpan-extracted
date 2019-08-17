package Acme::CPANAuthors::British::Companies;
use strict;
use warnings;

{
    no strict "vars";
    $VERSION = "1.04";
}

use Acme::CPANAuthors::Register (
    BBC         => 'BBC (British Broadcasting Corporation)',
    BBCIFL      => 'BBC, Interactive Factual & Learning',
    BBCPKENT    => 'P Kent (BBC)',
    BBCSIMONF   => 'Simon Flack (BBC)',
    BLACKSTAR   => 'BlackStar',
    CASTLE      => 'Peter Goode/Castle Links Ltd',
    DOTTK       => 'Dot TK Limited',
    FOTANGO     => 'Fotango Ltd',
    GMGRD       => 'Guardian Media Group Regional Digital',
    INTERINFO   => 'Interactive Information, Ltd',
    PROFERO     => 'Profero Ltd.',
    RECKON      => 'Reckon LLP',
);

q<
    recommended listening when using this module: Paramore - Misery Business
>

__END__

=encoding UTF-8

=head1 NAME

Acme::CPANAuthors::British::Companies - We are British Companies with PAUSE IDs

=head1 SYNOPSIS

   use Acme::CPANAuthors;

   my $authors  = Acme::CPANAuthors->new("British::Companies");

   my $number   = $authors->count;
   my @ids      = $authors->id;
   my @distros  = $authors->distributions("FOTANGO");
   my $url      = $authors->avatar_url("PROFERO");
   my $kwalitee = $authors->kwalitee("GMGRD");
   my $name     = $authors->name("BBCIFL");

=head1 DESCRIPTION

This class provides a hash of British Companies who have PAUSE IDs, to be used 
with the C<Acme::CPANAuthors> module.

This module was created as an addition to the British CPANAuthors module, due
to the number of British Companies that have decided to register their own
PAUSE account.

=head1 MAINTENANCE

If you are a British Company with a PAUSE account not listed here, please send 
me your ID/name via email or RT, so I can always keep this module up to date. 
If there are any mistakes and you're listed here but are not a British Company
(or just don't want to be listed), sorry for the inconvenience: please contact 
me as above and I'll remove the entry right away.

Please note that British Company implies that the head office reside in 
England, Wales, Scotland or Northern Ireland.

=head1 SEE ALSO

L<Acme::CPANAuthors> - Main class to manipulate this one

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::CPANAuthors::British::Companies

You can also look for information at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-CPANAuthors-British>

=item * MetaCPAN

L<https://metacpan.org/module/Acme::CPANAuthors::British>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-CPANAuthors-British>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-CPANAuthors-British>

=back

Bugs, patches and feature requests can be reported at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-CPANAuthors-British>

=item * GitHub

L<http://github.com/barbie/acme-cpanauthors-british>

=back

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to 
the RT queue. However, it would help greatly if you are able to pinpoint 
problems or even supply a patch. 

Fixes are dependent upon their severity and my availability. Should a fix 
not be forthcoming, please feel free to (politely) remind me.

=head1 ACKNOWLEDGEMENTS

Thanks to Kenichi Ishigaki for writing C<Acme::CPANAuthors>, and Sébastien 
Aperghis-Tramoni for writing C<Acme::CPANAuthors::French> on which I based
this release.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT & LICENSE

  Copyright 2009-2019 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
