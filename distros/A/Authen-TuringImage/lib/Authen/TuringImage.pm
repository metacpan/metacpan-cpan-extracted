# -*-cperl-*-
#
# Authen::TuringImage - Image based Turing test
# Copyright (c) 2001-2017 Ashish Gulhati <authen-ti at hash.neo.tc>
#
# $Id: lib/Authen/TuringImage.pm v1.006 Fri Jun 16 03:00:07 PDT 2017 $

package Authen::TuringImage;

use GD;
use Bytes::Random::Secure;
use File::Share ':all';
#use PAR;

( $VERSION ) = '$Revision: 1.006 $' =~ /\s+([\d\.]+)/;

sub new {
  bless { FONTPATH       =>   $ENV{'PAR_TEMP'} ? $ENV{'PAR_TEMP'} . '/inc/misc/TTF/' : dist_dir('Authen-TuringImage') . '/',
	  FONTS          =>   [ qw (DejaVuSans-Bold.ttf DejaVuSans-BoldOblique.ttf
				    DejaVuSans-Oblique.ttf DejaVuSans.ttf DejaVuSansCondensed-Bold.ttf 
				    DejaVuSansCondensed-BoldOblique.ttf DejaVuSansCondensed-Oblique.ttf 
				    DejaVuSansCondensed.ttf DejaVuSansMono-Bold.ttf DejaVuSansMono-BoldOblique.ttf
				    DejaVuSansMono-Oblique.ttf DejaVuSansMono.ttf DejaVuSerif-Bold.ttf
				    DejaVuSerif-BoldItalic.ttf DejaVuSerif-Italic.ttf DejaVuSerif.ttf
				    DejaVuSerifCondensed-Bold.ttf DejaVuSerifCondensed-BoldItalic.ttf
				    DejaVuSerifCondensed-Italic.ttf DejaVuSerifCondensed.ttf
				    luximb.ttf luximbi.ttf luximr.ttf luximri.ttf luxirb.ttf luxirbi.ttf
				    luxirr.ttf luxirri.ttf luxisb.ttf luxisbi.ttf luxisr.ttf luxisri.ttf ) ],
	  MOREFONTS      =>   [ qw(eastside.ttf elann___.ttf element.ttf embossn.ttf epic.ttf 
                                   er.ttf eras-bla.ttf eras-med.ttf eras-nor.ttf erdust__.ttf 
                                   essay-no.ttf eurosti1.ttf eurosti3.ttf eurostil.ttf fe______.ttf 
                                   foo.ttf frand___.ttf futured.ttf glitch1.ttf gmt.ttf	gothikka.ttf 
                                   halcyoni.ttf hancock.ttf harngton.ttf heliosph.ttf helvblak.ttf
	                           helvcond.ttf highboot.ttf idiot___.ttf idsupern.ttf illustr.ttf 
                                   inductio.ttf	inflamma.ttf instantt.ttf interdim.ttf intimacy.ttf 
				   invisibl.ttf isadora.ttf j.d.ttf jasmine.ttf jinky.ttf joycircu.ttf 
				   jphst.ttf justov.ttf kashmir.ttf kaste___.ttf kaufmann.ttf kej-type.ttf 
				   kiloton1.ttf korina-l.ttf leftycas.ttf lettergo.ttf liquidn.ttf 
				   lithogra.ttf longcool.ttf lovesexy.ttf lunasequ.ttf lunasol.ttf 
				   lunauror.ttf lynx.ttf mcparlnd.ttf mechag.ttf metalord.ttf microbd.ttf
				   mordred.ttf neon2.ttf neurochr.ttf neuropol.ttf niteclub.ttf notepad_.ttf 
				   ogilvie.ttf old_engl.ttf oscillos.ttf park_ave.ttf pastorof.ttf peace___.ttf
				   plasticb.ttf poinif__.ttf prefix.ttf premi___.ttf presdntn.ttf quadrang.ttf
				   quantity.ttf quinolin.ttf radiosta.ttf ravefli2.ttf retsyn2.ttf rhyol___.ttf
				   roar.ttf scythe.ttf slant.ttf sliver__.ttf soopafre.ttf speeb___.ttf 
				   stonehen.ttf strongma.ttf superglu.ttf sydney.ttf tangerin.ttf 
				   twylzw__.ttf univox.ttf vaground.ttf venta___.ttf virginlo.ttf 
				   vis_____.ttf wolves.ttf xenotron.ttf yadou.ttf yonderre.ttf zag.ttf) ]
	}, shift;
}

sub challenge {
  my $self = shift; my $key = shift;
  my $turing = new GD::Image(220,30);
  $white = $turing->colorAllocate(255,255,255);
  $black = $turing->colorAllocate(0,0,0);

  $turing->filledRectangle(0,0,220,30,$white);

  my $random = Bytes::Random::Secure->new( Bits => 64 );
  my $r = $random->string_from('0123456789',8);

  my $x = 2+int(rand(3));
  for (0...7) {
    my $char = substr($key?$key:$r, $_, 1);
    $self->{CHALLENGE} .= $char;
    my @font = @{$self->{FONTS}};
    my $font = $self->{FONTPATH} . $font[int(rand($#font+1))];
    my @bounds = $turing->stringTTF($black,$font,12,rand(1)-0.5,$x,19+int(rand(4)),$char);
    $x = $x + 2 + $bounds[3] +int(rand(5));
  }

  # Add dots

  for ( 1..500 ) {
    my $x = int rand 220;
    my $y = int rand 30;
    $turing->setPixel($x, $y, $black);
  }

  return ($turing, $self->{CHALLENGE});
}

sub response {
  my $self = shift;
  print STDERR "$self->{CHALLENGE}\n";
  return 1 if $self->{CHALLENGE} eq $_[0];
  return undef;
}

1; # End of Authen::TuringImage

__END__

=head1 NAME

Authen::TuringImage - Image based Turing test (CAPTCHA)

=head1 VERSION

 $Revision: 1.006 $
 $Date: Fri Jun 16 03:00:07 PDT 2017 $

=head1 SYNOPSIS

  use Authen::TuringImage;

  my $auth = new Authen::TuringImage;

  # Write challenge image to a file.

  my ($challenge) = $auth->challenge;
  open (CHALLENGE, "> challenge.jpg");
  print CHALLENGE, $challenge->jpeg;
  close CHALLENGE;

  # Read and verify challenge response.

  my $response = <STDIN>;
  print $response eq $auth->response ? "OK" : "Failed";

=head1 DESCRIPTION

This module implements an image based Turing test (aka "CAPTCHA") to
help protect resources from automated access.

=head1 CONSTRUCTOR

=head2 new

Creates and returns a new Authen::TuringImage object.

=head1 METHODS

=head2 challenge

Returns an image for use as a Turing test challenge, as well as the
text of the challenge, in that order, as a two element list. The user
must read and enter the characters in the image.

=head2 response

Returns the correct response to the Turing image challenge.

=head1 AUTHOR

Ashish Gulhati, C<< <authen-ti at hash.neo.tc> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-authen-turingimage at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Authen-TuringImage>. I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Authen::TuringImage

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Authen-TuringImage>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Authen-TuringImage>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Authen-TuringImage>

=item * Search CPAN

L<http://search.cpan.org/dist/Authen-TuringImage/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2001-2017 Ashish Gulhati.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

See http://www.perlfoundation.org/artistic_license_2_0 for the full
license terms.
