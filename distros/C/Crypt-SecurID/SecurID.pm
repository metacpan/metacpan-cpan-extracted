#
# SecurID.pm - SecurID emulator module
#
# $Id: SecurID.pm,v 1.8 2003/03/02 19:17:47 pliam Exp $
#

# Note: This is pathetic glue code.  It is not a class, but rather 
# only a package with a "sub new".  It literally has no sense of $self,
# because its new returns an object blessed into another class.  All
# this is to put SWIGged C++ hooks into a more natural part of the
# namespace; so that you can do the following:
#
# 		$t = Crypt::SecurID->new;  
# 		print $t->code(time);

package Crypt::SecurID;
use 5.006;
use strict;
use warnings;
use Crypt::securid;

use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", (q$Name: SecurID_Release_0_04 $ =~ /\d+/g));

## new wrapper
sub new {
	my $pkg = shift;
	my @args = @_;
	my $token = Crypt::securid::SecurID->new();
	$pkg->process_args($token, @args);
	return $token
}

## apply arguements to a token object
sub process_args {
	my $pkg = shift;
	my $token = shift;
	my %args = @_;

	my($file, $serial, $hexkey) = @args{qw(file serial hexkey)};

	## from file
	if (defined($file)) {
		unless (defined($serial)) {
			die "Must supply serial number along with 'file =>' arg.";
		}
		unless ($token->importToken($file, $serial)) {
			die $token->error();
		}
		return;
	}

	## from hex key	
	if (defined($hexkey)) {
		unless ($token->setKey($hexkey)) {
			die $token->error();
		}
		return;
	}
}

1;

__END__

=head1 NAME

Crypt::SecurID - Generate and verify SecurID time hash codes

=head1 SYNOPSIS

  use Crypt::SecurID;

  # create a token object tied to a 64-bit hex string key
  $token = Crypt::SecurID->new(hexkey => "0123456789abcdef"); 
  # equivalently
  $token = Crypt::SecurID->new; 
  $token->setKey("0123456789abcdef") || die $token->error;

  # create a token object tied to key in import file w/ serial number
  $token = Crypt::SecurID->new(file => $file, serial => $serial); 
  # equivalently
  $token = Crypt::SecurID->new; $token->importToken($file, $serial);

  # print a hash code value
  print $token->code(time);
  # equivalently
  print $token->codeNow;

  # verify a hash code value, print drift
  die "Code invalid" unless $token->validate($code, $days_tolerance);
  printf("Code ok, drift = %d minutes\n", $token->drift);

  # export a token to a file
  unless ($token->exportToken($file, $serial)) { die $token->error; }


=head1 DESCRIPTION

Crypt::SecurID is an emulator module for generating and verifying 
SecurID time-hash codes.  Such codes are often useful during identity 
authentication, especially when the code is generated out-of-band
so that the 64-bit secret key is never on any client machine.

Considerable speculation about the weakness of the hash algorithm
has been put forth.  AFAIK, it is still an open problem to determine 
how many distinct codes are necessary to recover the secret key.

OTOH, for one-sided authentication models (like SSL), even a weak 
time hash based on a shared secret may provide a desirable extra
layer of security.

This module is provided for purposes of discussion and/or prototyping.
If you need a real ACE server, buy one.

=head1 AUTHORS

John Pliam E<lt>pliam@cpan.orgE<gt> -- C++ wrappers, Perl module.

I. C. Wiener E<lt>icwiener@mailru.comE<gt>? -- C code.

=head1 SEE ALSO

Mudge, Kingpin, "Initial Cryptanalysis of the RSA SecurID Algorithm", 
Jan 2001.

http://www.ima.umn.edu/~pliam/lepgen/ The home page for the 
Low-Entropy Password Generator (LEP-Gen), an open source hardware token 
for Linux palmtops, which includes a SecurID mode.

=head1 BUGS

This has never been tested against a working card or ACE server, to 
which I have no access.  Furthermore, I tried, but not too hard, to 
reverse engineer the file format for importToken and exportToken methods 
from Wiener's code.  At this stage, I have no idea how close I got to the 
real thing.

=cut
