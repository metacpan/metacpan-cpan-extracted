#!/usr/bin/perl

package Acme::LOLCAT;

use strict;
use warnings;

use 5.006001; # 'our' requires a "more recent" perl.

use Exporter;

our @ISA = qw/Exporter/;
our @EXPORT = qw/translate/;

our $VERSION = '0.0.5';

my %repl = (
   what     => [qw/wut whut/],   'you\b'   => [qw/yu yous yoo u/],
   cture    => 'kshur',          unless    => 'unles',
   'the\b'  => 'teh',            more      => 'moar',
   my       => [qw/muh mah/],    are       => [qw/r is ar/],
   eese     => 'eez',            ph        => 'f',
   'as\b'   => 'az',             seriously => 'srsly',
   'er\b'   => 'r',              sion      => 'shun',
   just     => 'jus',            'ose\b'   => 'oze',
   eady     => 'eddy',           'ome?\b'  => 'um',
   'of\b'   => [qw/of ov of/],   'uestion' => 'wesjun',
   want     => 'wants',          'ead\b'   => 'edd',
   ucke     => [qw/ukki ukke/],  sion      => 'shun',
   eak      => 'ekk',            age       => 'uj',
   like     => [qw/likes liek/], love      => [qw/loves lub lubs luv/],
   '\bis\b' => ['ar teh','ar'],  'nd\b'   => 'n',
   who      => 'hoo',            q(')      => q(),
   'ese\b'  => 'eez',            outh      => 'owf',
   scio     => 'shu',            esque     => 'esk',
   ture     => 'chur',           '\btoo?\b'=> [qw/to t 2 to t/],
   tious    => 'shus',           'sure\b'  => 'shur',
   'tty\b'  => 'tteh',           were      => 'was',
   'ok\b'   => [ qw/'k kay/ ],   '\ba\b'   => q(),
   ym       => 'im',             'thy\b'   => 'fee',
   '\wly\w' => 'li',             'que\w'   => 'kwe',
   oth      => 'udd',            ease      => 'eez',
   'ing\b'  => [qw/in ins ng ing/],
   'have'   => ['has', 'hav', 'haz a'],
   your     => [ qw/yur ur yore yoar/ ],
   'ove\b'  => [ qw/oov ove uuv uv oove/ ],
   for      => [ qw/for 4 fr fur for foar/ ],
   thank    => [ qw/fank tank thx thnx/ ],
   good     => [ qw/gud goed guud gude gewd/ ],
   really   => [ qw/rly rily rilly rilley/ ],
   world    => [ qw/wurrld whirld wurld wrld/ ],
   q(i'?m\b)     => 'im',
   '(?!e)ight'   => 'ite',
   '(?!ues)tion' => 'shun',
   q(you'?re)    => [ qw/yore yr/ ],
   '\boh\b(?!.*hai)'  => [qw/o ohs/],
   'can\si\s(?:ple(?:a|e)(?:s|z)e?)?\s?have\sa' => 'i can has',
   '(?:hello|\bhi\b|\bhey\b|howdy|\byo\b),?'    => 'oh hai,',
   '(?:god|allah|buddah?|diety)'                => 'ceiling cat',
);

sub translate {
  my $phrase = lc shift;

  $phrase =~ s{
                $_
              }
              {
                ref $repl{ $_ } eq 'ARRAY'
                  ? $repl{ $_ }->[ rand( $#{ $repl{ $_ } } + 1 ) ]
                  : $repl{ $_ }
              }gex
              for keys %repl;

  $phrase =~ s/\s{2,}/ /g;
  $phrase =~ s/teh teh/teh/g; # meh, it happens sometimes.
  if( int rand 10 == 2 ){ $phrase .= '.  kthxbye!' }
  if( int rand 10 == 1 ){ $phrase .= '.  kthx.' }
  $phrase =~ s/(\?|!|,|\.)\./$1/;
  return uc $phrase;
}

# LOLCAT->can('has') # Thanks BOBTFISH :)
sub has {}

# LOLCAT->can('haz') # why not?
sub haz {}

1;

=pod

=head1 NAME

Acme::LOLCAT - SPEEK LIEK A LOLCATZ

=head1 VERSHON

Version 0.0.5

=head1 HOEW 2 YOOS IT

This module translates english sentences into "LOLCAT".  For more
information on LOLCAT, please consult wikipedia:
(L<http://en.wikipedia.org/wiki/Lolcat>)

  use strict;
  use warnings;

  use Acme::LOLCAT;

  my $phrase = translate( "You too can speak like a lolcat!" );

  print $phrase;

  Output:

  YU 2 CAN SPEEK LIEK LOLCAT! KTHX.

=head1 ECKSPORTS

=over

=item translate

Exports the function "translate" into your namespace.

Pass translate some text, translate returns some LOLCATed text.

If you prefer to call translate() with the fully qualified name,
and don't want translate() to be exported into your namespace:

  use Acme::LOLCAT ();

  # ...

  my $translated_text
    = Acme::LOLCAT::Translate( $orginal_text );

=back

=head1 IM IN UR NAMESPAEC AND I CAN HAZ

=over

=item has

Every LOLCAT->can('has')

=item haz

I CAN HAZ TOO

=back

=head1 DEMONSTRASHUN TO SEEZ IT WERK IN REEL TIEM

I've created a quick and dirty ajax powered web page to show how easy
Acme:LOLCAT is to use.  Point your web browser here:

L<http://www.kentcowgill.org/lolcat.html>

The backend CGI that accepts and responds to the ajax requests is very
simple:

  #!/usr/bin/perl

  use strict;
  use warnings;

  use CGI qw/:standard/;
  use Acme::LOLCAT;

  print header( -type => 'text/html'),
        translate( param( 'english' );

... where 'english' is the name of the textarea where input is accepted.

=head1 DEPENDNSEEZ

Requires C<Exporter>.

=head1 GUY DAT ROTE IT

Kent Cowgill C<kent@c2group.net>, L<http://www.kentcowgill.org>

=head1 REKWESTZ AN BUGZ

Please report any requests, suggestions, or bugs via the RT bug tracking
system at L<http://rt.cpan.org>.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme::LOLCAT> is the RT queue
to Acme::LOLCAT. Please check to see if your bug has already been reported.

=head1 AKNAHLUJMENTZ

Thanks to Dyana Wu for the patch adding several variations and additions
to the LOLCAT vocabulary.

=head1 COPEERITE AN LISUNZ

Copyright (c) 2007 by Kent Cowgill

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
