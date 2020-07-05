# Authen::TOTP version 0.0.7
#
# Copyright (c) 2020 Thanos Chatziathanassiou <tchatzi@arx.net>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Authen::TOTP;
local $^W;
require 'Exporter.pm';
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA = (Exporter);

@EXPORT_OK = qw();

$Authen::TOTP::VERSION='0.0.7';
$Authen::TOTP::ver=$Authen::TOTP::VERSION;

use strict;
use warnings;
use utf8;
use Carp;
use Data::Dumper;

sub debug_print {
	my $self = shift;
	
	#fancy stuff that can be done later
	warn @_;
	
	return 1;
}

sub process_sub_arguments {
	my $self = shift;

	my $args = shift;
	my $wants = shift;
	my @rets;

	if (@$args != 0) {
		if (ref $args->[0] eq 'HASH') {
			foreach my $want (@$wants) {
				push @rets,$args->[0]->{$want};
			}
		}
		elsif (!(scalar(@$args)%2)) {
			my %hash = @$args;
			foreach my $want (@$wants) {
				push @rets,$hash{$want};
			}
		}
	}
	return @rets;
}

sub valid_digits {
	my $self = shift;
	my $digits = shift;

	if ($digits && $digits =~ m|^[68]$|) {
		$self->{digits} = $digits;
	}
	elsif (!defined($self->{digits}) || $self->{digits} !~ m|^[68]$|) {
		$self->{digits} = 6;
	}
	1;
}
sub valid_period {
	my $self = shift;
	my $period = shift;

	if ($period && $period =~ m|^[36]0$|) {
		$self->{period} = $period;
	}
	elsif (!defined($self->{period}) || $self->{period} !~ m|^[36]0$|) {
		$self->{period} = 30;
	}
	1;
}
sub valid_algorithm {
	my $self = shift;
	my $algorithm = shift;

	if ($algorithm && $algorithm =~ m|^SHA\d+$|) {
		$self->{algorithm} = $algorithm;
	}
	elsif (!defined($self->{algorithm}) || $self->{algorithm} !~ m|^SHA\d+$|) {
		$self->{algorithm} = "SHA1";
	}
	1;
}
sub valid_when {
	my $self = shift;
	my $when = shift;

	if ($when && $when =~ m|^\-?\d+$|) { #negative epoch is valid, though not sure how useful :)
		$self->{when} = $when;
	}
	elsif (!defined($self->{when}) || $self->{when} !~ m|^\-?\d+$|) {
		$self->{when} = time;
	}
	1;
}
sub valid_tolerance {
	my $self = shift;
	my $tolerance = shift;

	if ($tolerance && $tolerance =~ m|^\d+$| && $tolerance > 0) {
		$self->{tolerance} = ($tolerance-1);
	}
	elsif (!defined($self->{tolerance}) || $self->{tolerance} !~ m|^\d+$|) {
		$self->{tolerance} = 0;
	}
	1;
}
sub valid_secret {
	my $self = shift;
	my ($secret, $base32secret) = @_;

	if ($secret) {
		$self->{secret} = $secret;
	}
	elsif ($base32secret) {
		$self->{secret} = $self->base32dec($base32secret);
	}
	else {
		if (defined($self->{base32secret})) {
			$self->{secret} = $self->base32dec($self->{base32secret});
		}
		else {
			if (defined($self->{algorithm})) {
				if ($self->{algorithm} eq "SHA512") {
					$self->{secret} = $self->gen_secret(64);
				}
				elsif ($self->{algorithm} eq "SHA256") {
					$self->{secret} = $self->gen_secret(32);
				}
				else {
					$self->{secret} = $self->gen_secret(20);
				}
			}
			else {
				$self->{secret} = $self->gen_secret(20);
			}
		}
	}
	
	$self->{base32secret} = $self->base32enc($self->{secret});
	1;
}
sub secret {
	my $self = shift;
	return $self->{secret};
}
sub base32secret {
	my $self = shift;
	return $self->{base32secret};
}
sub algorithm {
	my $self = shift;
	my $algorithm = shift;
	$self->valid_algorithm($algorithm);

	return $self->{algorithm};
}

sub hmac {
	my $self = shift;
	my $Td = shift;

	if  ((eval {require Digest::SHA;1;} || 0) ne 1) {
		# if module can't load
		require Digest::SHA::PurePerl;
		$self->{DEBUG} and $self->debug_print("Digest::SHA unavailable, using Digest::SHA::PurePerl()");
		if ($self->{algorithm} eq 'SHA512') {
			return Digest::SHA::PurePerl::hmac_sha512_hex($Td, $self->{secret});
		}
		elsif ($self->{algorithm} eq 'SHA256') {
			return Digest::SHA::PurePerl::hmac_sha256_hex($Td, $self->{secret} );
		}
		else {
			return Digest::SHA::PurePerl::hmac_sha1_hex($Td, $self->{secret} );
		}
	}
	else {
		#we have XS!
		$self->{DEBUG} and $self->debug_print("using Digest::SHA()");
		if ($self->{algorithm} eq 'SHA512') {
			return Digest::SHA::hmac_sha512_hex($Td, $self->{secret});
		}
		elsif ($self->{algorithm} eq 'SHA256') {
			return Digest::SHA::hmac_sha256_hex($Td, $self->{secret} );
		}
		else {
			return Digest::SHA::hmac_sha1_hex($Td, $self->{secret} );
		}
	}
}

sub base32enc {
	my $self = shift;
	
	if  ((eval {require MIME::Base32::XS;1;} || 0) ne 1) {
		# if module can't load
		require MIME::Base32;
		$self->{DEBUG} and $self->debug_print("MIME::Base32::XS unavailable, using MIME::Base32()");
		return MIME::Base32::encode_base32(shift);
	}
	else {
		#we have XS!
		$self->{DEBUG} and $self->debug_print("using MIME::Base32::XS()");
		return MIME::Base32::XS::encode_base32(shift);
	}
}

sub base32dec {
	my $self = shift;
	
	if  ((eval {require MIME::Base32::XS;1;} || 0) ne 1) {
		# if module can't load
		require MIME::Base32;
		$self->{DEBUG} and $self->debug_print("MIME::Base32::XS unavailable, using MIME::Base32()");
		return MIME::Base32::decode_base32(shift);
	}
	else {
		#we have XS!
		$self->{DEBUG} and $self->debug_print("using MIME::Base32::XS()");
		return MIME::Base32::XS::decode_base32(shift);
	}
}

sub gen_secret {
	my $self = shift;
	my $length = shift || 20;

	my $secret;
	for my $i(0..int(rand($length))+$length) {
		$secret .= join '',('/', 1..9,'!','@','#','$','%','^','&','*','(',')','-','_','+','=', 'A'..'H','J'..'N','P'..'Z', 'a'..'h','m'..'z')[rand 58];
	}
	if (length($secret) > ($length+1)) {
		$self->{DEBUG} and $self->debug_print("have len ".length($secret)." ($secret) so cutting down");
		return substr($secret,0,$length);
	}
	return $secret;
}

sub generate_otp {
	my $self = shift;
	my ($digits,$period,$algorithm,$secret,$base32secret, $issuer, $user) = 
		$self->process_sub_arguments(\@_,[ 'digits', 'period', 'algorithm', 'secret', 'base32secret', 'issuer', 'user']);
	
	unless ($user) {
		Carp::confess("need user to use as prefix in generate_otp()");
	}

	$self->valid_digits($digits);
	$self->valid_period($period);
	$self->valid_algorithm($algorithm);
	$self->valid_secret($secret, $base32secret);

	if ($issuer) {
		$issuer = qq[&issuer=].$issuer;
	}
	else {
		$issuer = '';
	}

	return qq[otpauth://totp/$user?secret=]
								.$self->{base32secret}
								.qq[&algorithm=].$self->{algorithm}
								.qq[&digits=].$self->{digits}
								.qq[&period=].$self->{period}
								.$issuer;
}

sub validate_otp {
	my $self = shift;
	my ($digits,$period,$algorithm,$secret,$when,$tolerance,$base32secret, $otp) = 
		$self->process_sub_arguments(\@_,[ 'digits', 'period', 'algorithm', 'secret', 'when', 'tolerance', 'base32secret', 'otp']);
	
	unless ($otp && $otp =~ m|^\d{6,8}$|) {
		$otp ||= "";
		Carp::confess("invalid otp $otp passed to validate_otp()");
	}

	$self->valid_digits($digits);
	$self->valid_period($period);
	$self->valid_algorithm($algorithm);
	$self->valid_when($when);
	$self->valid_tolerance($tolerance);
	$self->valid_secret($secret, $base32secret);

	my @tests = ( $self->{when} );
	for my $i (1..$self->{tolerance}) {
		push @tests, ($self->{when} - ($self->{period} * $i) );
		push @tests, ($self->{when} + ($self->{period} * $i) );
	}

	foreach $when (@tests) {
		$self->{DEBUG} and $self->debug_print("using when $when (". ($when - $self->{when}). ")");

		my $T = sprintf("%016x", int($when / $self->{period}) );
		my $Td = pack('H*', $T);
		
		my $hmac = $self->hmac($Td);
		
		# take the 4 least significant bits (1 hex char) from the encrypted string as an offset
		my $offset = hex(substr($hmac, -1));
		# take the 4 bytes (8 hex chars) at the offset (* 2 for hex), and drop the high bit
		my $encrypted = hex(substr($hmac, $offset * 2, 8)) & 0x7fffffff;

		my $code = sprintf("%0".$self->{digits}."d", ($encrypted % (10**$self->{digits}) ) );
		
		$self->{DEBUG} and $self->debug_print("comparing $code to $otp");

		if ($code eq sprintf("%0".$self->{digits}."d", $otp) ) {
			return 1;
		}

	}

	return undef;
}

sub initialize {
	my $self = shift;

	$self->{DEBUG} = 0;

	if (@_ != 0) {
		if (ref $_[0] eq 'HASH') {
			my $hash=$_[0];
			foreach (keys %$hash) {
				$self->{lc $_}=$hash->{$_};
			}
		}
		elsif (!(scalar(@_)%2)) {
			my %hash = @_;
			foreach (keys %hash) {
				$self->{lc $_}=$hash{$_};
			}
		}
	}
	
	$self->valid_digits();
	$self->valid_period();
	$self->valid_algorithm();
	$self->valid_when();
	$self->valid_tolerance();
	$self->valid_secret();
			
	return $self;
}

sub new {
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = {};
	bless $self, $class;

	return $self->initialize(@_);
}

1;
__END__

=head1 NAME

Authen::TOTP - Interface to RFC6238 two factor authentication (2FA)

Version 0.0.7

=head1 SYNOPSIS

 use Authen::TOTP;

=head1 DESCRIPTION

C<Authen::TOTP> is a simple interface for creating and verifying RFC6238 OTPs
as used by Google Authenticator, Authy, Duo Mobile etc

It currently passes RFC6238 Test Vectors for SHA1, SHA256, SHA512

=head1 USAGE

 my $gen = new Authen::TOTP(
	 secret		=>	"some_random_stuff",
 );

 #will generate a TOTP URI, suitable to use in a QR Code
 my $uri = $gen->generate_otp(user => 'user\@example.com', issuer => "example.com");
 
 print qq{$uri\n};
 #store $gen->secret() or $gen->base32secret() someplace safe!

 #use Imager::QRCode to plot the secret for the user
 use Imager::QRCode;
 my $qrcode = Imager::QRCode->new(
           size          => 4,
           margin        => 3,
           level         => 'L',
           casesensitive => 1,
           lightcolor    => Imager::Color->new(255, 255, 255),
           darkcolor     => Imager::Color->new(0, 0, 0),
       );

 my $img = $qrcode->plot($uri);
 $img->write(file => "totp.png", type => "png");
 #...or you can pass it to google charts and be done with it

 #compare user's OTP with computed one
 if ($gen->validate_otp(otp => <user_input>, secret => <stored_secret>, tolerance => 1)) {
	#2FA success
 }
 else {
	#no match
 }

=head1 new Authen::TOTP

 my $gen = new Authen::TOTP(
	 digits 	=>	[6|8],
	 period		=>	[30|60],
	 algorithm	=>	"SHA1", #SHA256 and SHA512 are equally valid
	 secret		=>	"some_random_stuff",
	 when		=>	<some_epoch>,
	 tolerance	=>	0,
 );

=head2 Parameters/Properties (defaults listed)

=over 4

=item digits

C<6>=> How many digits to produce/compare

=item period

C<30>=> OTP is valid for this many seconds

=item algorithm

C<SHA1>=> supported values are SHA1, SHA256 and SHA512, although most clients only support SHA1 AFAIK

=item secret

C<random_20byte_string>=> Secret used as seed for the OTP

=item base32secret

C<base32_encoded_random_12byte_string>=> Alternative way to set secret (base32 encoded)

=item when

C<epoch>=> Time used for comparison of OTPs

=item tolerance

C<1>=> Due to time sync issues, you may want to tune this and compare
this many OTPs before and after

=back

=head2 Utility Functions

=over 4

=item C<generate_otp>=>

Create a TOTP URI using the parameters specified or the defaults from
the new() method above

Usage:

 $gen->generate_otp(
	 digits 	=>	[6|8],
	 period		=>	[30|60],
	 algorithm	=>	"SHA1", #SHA256 and SHA512 are equally valid
	 secret		=>	"some_random_stuff",
	 issuer		=>	"example.com",
	 user		=>	"some_identifier",
 );
 
 Google Authenticator displays <issuer> (<user>) for a TOTP generated like this

=item C<validate_otp>=>

Compare a user-supplied TOTP using the parameters specified. Obviously the secret
MUST be the same secret you used in generate_otp() above/
Returns 1 on success, undef if OTP doesn't match

Usage:

 $gen->validate_otp(
	 digits 	=>	[6|8],
	 period		=>	[30|60],
	 algorithm	=>	"SHA1", #SHA256 and SHA512 are equally valid
	 secret		=>	"the_same_random_stuff_you_used_to_generate_the_TOTP",
	 when		=>	<epoch_to_use_as_reference>,
	 tolerance	=>	<try this many iterations before/after when>
	 otp		=>	<OTP to compare to>
 );
 
=back

=cut

=head1 Revision History

 0.0.7
	Moved git repo to github
	Added CONTRIBUTING.md file
	Changed gen_secret() to accept secret length as argument and made 20 the default
 0.0.6
	Another pointless adjustment in cpanfile
 0.0.5
	Corrected cpanfile to require either MIME::Base32::XS or MIME::Base32
	and Digest::SHA or Digest::SHA::PurePerl
 0.0.4
	Added missing test vectors
 0.0.3
	Switched to Digest::SHA in order to support SHA256 and SHA512 as well
 0.0.2
	Added Digest::HMAC_SHA1 and MIME::Base32 to cpanfiles requires (still
	getting acquainted with Minilla)
 0.0.1
	Initial Release

=head1 DEPENDENCIES

one of 
L<Digest::SHA> or L<Digest::SHA::PurePerl>

and
L<MIME::Base32::XS> or L<MIME::Base32>

L<Imager::QRCode> if you want to generate QRCodes as well

=head1 SEE ALSO

L<Auth::GoogleAuth> for a module that does mostly the same thing

L<https://tools.ietf.org/html/rfc6238> for more info on TOTPs

=head1 CAVEATS

Some stuff definitely isn't as efficient as it can be

=head1 BUGS

Well, it passes RFC test vectors and has so far proven compatible with
Gitlab's 2FA.
Let me know if you find anything that's not working

=head1 ACKNOWLEDGEMENTS

Github user j256 for his example implementation

Gryphon Shafer <gryphon@cpan.org> for his L<Auth::GoogleAuth> module
that does mostly the same job, but I discovered after I had written 
most of this

=head1 AUTHOR

Thanos Chatziathanassiou <tchatzi@arx.net>
L<http://www.arx.net>

=head1 COPYRIGHT

Copyright (c) 2020 arx.net - Thanos Chatziathanassiou . All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
