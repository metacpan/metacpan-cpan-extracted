package Captcha::Stateless;

use strict;
use warnings;

use GD::SecurityImage;
use Crypt::CBC;

require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw();
our $VERSION   = '0.04';

sub new{
	my $class = shift;
	my %parameters = (
		expire => 600,
		@_,
	);

	my $self = {};
	$self->{'expire'} = $parameters{'expire'};
	$self->{'error'}  = '';

	unless ($parameters{'keyfile'}){
		$self->{'error'} = "No key file specified";
		return 0;
	}
	unless (-e $parameters{'keyfile'}){
		$self->{'error'} = "File not found: $parameters{'keyfile'}";
		return 0;
	}
	unless (-r $parameters{'keyfile'}){
		$self->{'error'} = "File not readable: $parameters{'keyfile'}";
		return 0;
	}
	$self->{'keyfile'} = $parameters{'keyfile'};

	bless $self;
}

sub error {
	my $self = shift;
	return $self->{'error'};
}

sub encrypt {
	my $self = shift;
	my $captchavalue = shift;
	my $expire = time + $self->{'expire'};
	my $key = _slurp_keyfile($self->{'keyfile'});
	my $cipher = Crypt::CBC->new(
		-key    => $key,
		-cipher => 'Blowfish'
		);
	return $cipher->encrypt_hex("$captchavalue:$expire");
}

sub validate {
	my $self = shift;
	my %parameters = (
		@_,
	);
	my $cookie  = $parameters{'cookie'};
	my $entered = $parameters{'entered'};
	my $key = _slurp_keyfile($self->{'keyfile'});
	my $cipher = Crypt::CBC->new(
		-key    => $key,
		-cipher => 'Blowfish'
		);
	my $decrypted = $cipher->decrypt_hex($cookie);
	my ($captchavalue, $expire) = split /:/,$decrypted;
	if ($expire < time){
		$self->{'error'} = 'Captcha expired.';
		return 0;
	}
	if ($captchavalue eq $entered){
		$self->{'error'} = '';
		return 1;
	}else{
		$self->{'error'} = 'Captcha Value mismatch.';
		return 0;
	}
}

sub _slurp_keyfile {
	open my $fh_in, "<", shift;
	my $keydata = <$fh_in>;
	close $fh_in;
	chomp $keydata;
	return $keydata;
}

1;
__END__

=head1 Name

Captcha::Stateless - A stateless captcha implementation that stores state in an HTTP cookie in the browser.

=head1 Synopsis

  use Captcha::Stateless;
  use CGI;

  my $slcaptcha = Captcha::Stateless->new(
    keyfile => '/path/to/keyfile',
    expire => 600
  );

  my $cookievalue = $slcaptcha->encrypt($random_number);

  my $captchavalid = $slcaptcha->validate(
    cookie  => $q->cookie('slcaptcha'),
    entered => $q->param('captcha-entered')
  );

=head1 Description

B<Captcha::Stateless> implements a Captcha that stores the expected response 
value in an encrypted HTTP cookie on the authenticating browser:

  /cgi-bin/slcaptcha 
    -> Captcha image, encrypted HTTP cookie 
      -> Browser

  Browser
    -> Manually entered response, stored encrypted cookie 
      -> /cgi-bin/application

The target audience are "self-hosted" applications. Load balancing should 
work provided the client is appropriately stickied to one server or all
servers share the same encryption key.

=head1 Usage

=head2 Captcha Image Generation

Captcha image generation can be handled by any external Captcha generator
such as B<GD::SecurityImage>:

  use GD::SecurityImage;

  my $image = GD::SecurityImage->new(
    width   => 100,
    height  => 50,
    lines   => 8,
    ptsize  => 25,
    font    => '/usr/share/fonts/truetype/ttf-staypuft/StayPuft.ttf'
  );

  $image->random();
  $image->create(ttf => 'ec');

  my ($image_data, $mime_type, $random_number) = $image->out;

=head2 Captcha Generation

From B<GD::SecurityImage>'s output, B<Captcha::Stateless> will use the 
I<$random_number> value for generating the cookie.

  use Captcha::Stateless;
  use CGI;

  my $slcaptcha = Captcha::Stateless->new(
    keyfile => '/path/to/keyfile',
    expire => 600
  );
    
Deliver image to client and set the encrypted cookie:

  my $q=CGI->new;

  print $q->header(
    -type    => "image/$mime_type",
    -charset => '',
    -cookie  => $q->cookie(
      -name  => 'slcaptcha',
      -value => $slcaptcha->encrypt($random_number),
      -path  => '/cgi-bin'
    )
  );
   
  print $image_data;
  exit;

See the sample I<cgi-bin/slcapapp> CGI script in the distribution.

=head2 Captcha Key File

For the key, save 16 random bytes in any file readable by the web server:

  openssl rand -hex -out /path/to/keyfile.dat 16

=head2 Captcha Integration

See the sample I<cgi-bin/slcapapp> CGI script in the distribution.

=head2 Captcha Validation

The receiving application will receive an entered value from the browser
along with the cookie that contains the desired value in encrypted form.

  use Captcha::Stateless;
  use CGI;

  my $q=CGI->new;

  my $slcaptcha = Captcha::Stateless->new(
    keyfile => '/path/to/keyfile',
  );

  my $captchavalid = $slcaptcha->validate(
    cookie  => $q->cookie('slcaptcha'),
    entered => $q->param('captcha-entered')
  );

  if ($captchavalid){
  	# Let good things happen
  }else{
  	# Display the error string from $slcaptcha->error();
  }

See the sample I<cgi-bin/slcapapp> CGI script in the distribution.

=head1 Class Methods

=head2 I<new()>

Instantiate the module with basic settings such as the keyfile and
the expiration time for the generated Captchas.

  my $slcaptcha = Captcha::Stateless->new(
    keyfile => '/path/to/keyfile',
    expire  => 600                    # Default 600 seconds
  );

=head2 I<error()>

Show the current error message.

  my $whatwentwrong = $slcaptcha->error();

=head1 Object Methods

=head2 I<encrypt()>

Takes the random number provided by your Captcha image generator, appends
the expiration time, encrypts them using Blowfish and Hex encodes them for
being passed to the client as an HTTP cookie.

  my $cookievalue = $slcaptcha->encrypt($random_number);

=head2 I<validate()>

Takes the HTTP cookie returned from the client (after completion of the 
Captcha quiz), decrypts it, checks for the correct content and whether it 
is still valid, and compares it to the value entered on the client.

  my $captchavalid = $slcaptcha->validate(
    cookie  => $q->cookie('slcaptcha'),
    entered => $q->param('captcha-entered')
  );

Returns 1 on success, 0 on validation failure.

=head1 Status

Testing.

=head1 Live Demo

https://team-frickel.de/cgi-bin/Captcha-Stateless/slcapapp

=head1 Bugs & Suggestions

No known showstopper bugs. 

Please use https://github.com/mschmitt/Captcha-Stateless for all feedback.

=head1 Limitations

Captchas, once solved, can be used repeatedly until they expire. Can be
potentially worked around on an application basis e.g. by storing the 
used encrypted cookie values.

No scalability tests have been conducted. 

No security review has been conducted. The author may be completely deluded
or a genius, your guess is as good as mine.

=head1 Author & License

Martin Schmitt E<lt>mas at scsy dot deE<gt>, 2018

Permission is hereby granted, free of charge, to any person obtaining a 
copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the 
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in 
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
DEALINGS IN THE SOFTWARE.

=head1 Dependencies

=head2 Core 

L<perl>, L<Crypt::CBC>, L<Crypt::Blowfish>

=head2 Recommended

L<GD::SecurityImage>, L<CGI>

=cut
