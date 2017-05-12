
package ASP4x::Captcha::Imager;

use strict;
use warnings 'all';
use base 'ASP4::FormHandler';
use vars __PACKAGE__->VARS;
use Imager;
use Digest::MD5 'md5_hex';

our $VERSION = '0.003';


sub run
{
  my ($s, $context) = @_;
  
  my ($word, $key) = $s->generate_pair( $context );
  
  $Session->{asp4captcha} = { lc($word) => $key };
  $word = join ' ', split //, $word;
  
  my $img = Imager->new(
    xsize => eval { $Config->system->settings->captcha_width }  || 140,
    ysize => eval { $Config->system->settings->captcha_height } || 70
  );

  $img->box(
    filled => 1,
    color  => eval { $Config->system->settings->captcha_bg_color } || 'white'
  );

  my $font = Imager::Font->new( $s->font );

  my @colors = qw(
    A9A9A9  878787  656565  808080
    CACACA  EFEFEF  DEDEDE  CDCDCD
    BABABA  A9A9A9  878787  656565
    434343  212121  EFEFEF  DEDEDE
    CDCDCD  BABABA  CCCCCC  AAAAAA
  );
  
  # Add the word to the image, but make it hard to read:
  my @chars = split //, $word;
  my $charWidth = ( $img->getwidth * 0.8 ) / scalar(@chars);
  my $charHeight = sprintf("%d", $img->getheight * 0.7);
  
  for( 1..10 )
  {
    for my $idx ( 0..@chars - 1 )
    {
      for( 1..int(rand() * @colors) )
      {
      push @colors, shift(@colors);
      }
      my $color = $colors[0];
      $font->align(
        halign  => 'center',
        valign  => 'center',
        string  => $chars[$idx],
        size    => $charHeight,
        image   => $img,
        color   => $color,
        'x'     => ( $idx * $charWidth ) + int(rand() * 8) + $charWidth,
        'y'     => ($img->getheight / 2) + int(rand() * 8) - 4,
      );
    }# end for()
    $img->filter( type => 'gaussian', stddev => 1 );
  }# end for()
  
  # Render the image as PNG:
  my $str = "";
  $img->write(type=>'png', data => \$str)
    or die $img->errstr;
  $Response->Expires( -30 );
  $Response->AddHeader( pragma => 'no-cache' );
  $Response->SetHeader('content-type' => 'image/png');
  $Response->ContentType( 'image/png' );
  $Response->Write( $str );
}# end run()


sub generate_pair
{
  my ($s, $context) = @_;

  my $len = eval { $Config->system->settings->captcha_length } || 4;
  my $chars = join '', ( 'A'..'H', 'J'..'N', 'P'..'Z', 1..9 );

  my $word = '';
  while( length($word) < $len )
  {
    $word .= substr($chars, int(rand()*length($chars)), 1);
  }# end while()
  
  my $key = md5_hex( lc($word) . ( eval { $Config->system->settings->captcha_key } || '' ) );
  
  return ( $word, $key );
}# end generate_pair()


sub font
{
  my $s = shift;
  
  return ( file => $Config->system->settings->captcha_font );
}# end font()

1;# return true:

=pod

=head1 NAME

ASP4x::Captcha::Imager - Imager-based CAPTCHA for your ASP4 web application.

=head1 SYNOPSIS

=head2 In Your asp4-config.conf

  {
    ...
    "system": {
      ...
      "settings": {
        ...
        "captcha_key":      "Some random string of any length",
        "captcha_font":     "@ServerRoot@/etc/LiberationSans-Regular.ttf",
        "captcha_width":    140,
        "captcha_height":   40,
        "captcha_bg_color": "FFFFFF",
        "captcha_length":   4
        ...
      }
    }
  }

=head2 In a handler

Simply subclass C<ASP4x::Captcha::Imager> as shown below:

  package dev::captcha;

  use strict;
  use warnings 'all';
  use base 'ASP4x::Captcha::Imager';
  use vars __PACKAGE__->VARS;

  1;# return true:

=head2 In your ASP Script:

Render the Captcha image:

  <html>
  <head>
  <style type="text/css">
  LABEL {
    display:        block;
    width:          265px;
    text-align:     right;
    float:          left;
    padding-right:  5px;
  }
  
  IMG {
    border: dotted 1px #AAA;
  }
  </style>
  </head>
  <body>
    <form action="/handlers/dev.validate" method="post">
      <p>
        <label>Enter the code you see below:</label>
        <input type="text" name="security_code" />
      </p>
      <p>
        <label>&nbsp;</label>
        <img id="captcha" src="/handlers/dev.captcha?r=<%= rand() %>" alt="Security Code" />
        <a href="" onclick="document.getElementById('captcha').src = '/handlers/dev.captcha?r=' + Math.random(); return false">
          (Click for a new Image)
        </a>
      </p>
      <p>
        <label>&nbsp;</label>
        <input type="submit" value="Submit" />
      </p>
    </form>
  </body>
  </html>

=head2 Validate the Captcha

  package dev::validate;

  use strict;
  use warnings 'all';
  use base 'ASP4::FormHandler';
  use vars __PACKAGE__->VARS;

  sub run
  {
    my ($s, $context) = @_;
    
    my $secret = $Config->system->settings->captcha_key;
    my $code = lc($Form->{security_code});
    
    # It should exist in the session and have the correct value:
    if( exists($Session->{asp4captcha}->{$code}) )
    {
      # Ding ding ding ding ding!
      $Response->Write("CORRECT");
    }
    else
    {
      # Bzzzzzzzzzzt: WRONG!
      $Response->Write("WRONG");
    }# end if()
  }# end run()

  1;# return true:

=head1 DESCRIPTION

"CAPTCHA" is the little security image containing a hard-to-read code that you may
have seen on some websites.  They are common on sign-up forms and email forms.  The
idea is that a bot or script can't read the image and can't guess the code.

C<ASP4x::Captcha::Imager> uses L<Imager> to generate an image of a random string
of numbers and letters.

=head2 What Does the Captcha Image Look Like?

You can see an example in the example/example.png file included with this distribution.

=head2 Recommendations and Considerations

=over 4

=item * Shorter Captchas are probably good enough.

Unless you've got yourself the next Facebook, you could probably get away with
4 characters in your Captcha.  Long captchas will just annoy humans.

=item * Where to use Captcha

Any form that might be attacked by a script including registration forms, email forms, etc.
is a good candidate for a Captcha.  Since it's so easy to use Captchas there really
isn't any reason not to use them anywhere you think B<might> benefit.  If you keep
the Captcha length short (see the first point in this list) then the humans won't
be too bothered by them and may actually be pleased with your consideration of their privacy.

=back

=head2 What About Fonts?

Because Linux systems tend to put fonts in several different places, I recommend
copying the font file (*.ttf) into the C<etc/> folder of your website and referencing it
(just like you see in the C<t/> folder of this distribution and in the SYNOPSIS example above.

Mono-space fonts are recommended over variable-width fonts.  So, "Courier New" is
recommended over Verdana.

=head1 SEE ALSO

L<ASP4>, L<Imager>

=head1 PREREQUISITES

L<Imager>, L<ASP4>, L<Digest::MD5>

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 LICENSE

This software is B<Free> software and may be used and redistributed under the
same terms as any version of Perl itself.

=cut

