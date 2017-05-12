# -*-cperl-*-
#
# sigver.t - Crypt::GPG signing / verification tests.
# Copyright (c) 2005-2006 Ashish Gulhati <crypt-gpg at neomailbox.com>
#
# All rights reserved. This code is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# $Id: 05-sigver.t,v 1.7 2006/12/21 12:36:35 ashish Exp $

use strict;
use Test;
use Crypt::GPG;

BEGIN { plan tests => 32 }

my $debug = 0;
my $dir = $0 =~ /^\// ? $0 : $ENV{PWD} . '/' . $0; $dir =~ s/\/[^\/]*$//;
$ENV{HOME} = $dir;

# Create new Crypt::GPG object

my @x;
my $gpg = new Crypt::GPG;
$ENV{GPGBIN} and $gpg->gpgbin($ENV{GPGBIN});

my $nogpg = 1 unless (-e $gpg->gpgbin);

$gpg->gpgopts('--compress-algo 1 --cipher-algo cast5 --force-v3-sigs --no-comment');
$gpg->debug($debug);

# Start test loop with different key sizes/types
################################################
for my $bits (qw(1024 2048)) {
  for my $type ('ELG-E') {

    my $secretkey;
    ($secretkey) = grep { $_->{Type} =~ /^sec[^\@]?/ } $gpg->keyinfo("A $bits $type")
      unless $nogpg;
    $gpg->secretkey($secretkey->{ID});
    
    for my $nopass (0,1) {
      if ($nopass) {
	# Blank out the Key password and do another round of tests
        ##########################################################
	skip($nogpg,
	     sub {
	       $gpg->passphrase('');
	       $gpg->keypass($secretkey, "$bits Bit $type Test Key", '');
	     });
      }
      
      $gpg->passphrase("$bits Bit $type Test Key") unless $nopass;
      $gpg->encryptsafe(0); #! Must test with both trusted and untrusted keys.

      # Encrypt and sign with GPG
      ###########################
      my @xs;
      skip($nogpg,
	   sub {
	     @xs = $gpg->encrypt("Test\n", "A $bits $type", '-sign');
	   });
      
      # Sign with GPG
      ###############
      #! Need to check for hang when secret key not set.
      skip($nogpg,
	   sub {
	     my $signed = $gpg->sign("Signing a test\nmessage, combining\nand\r\nline endings.\n");
	     $signed =~ /^-----BEGIN PGP SIGNATURE-----.*-----END PGP SIGNATURE-----$/s;
	   });
      
      #! Clearsign with GPG
      #####################
      skip(sub {1});
    
      #! Detached sign with GPG
      #########################
      skip(sub {1});
      
      # Decrypt & Verify GPG with GPG
      ###############################
      skip($nogpg,
	   sub {
	     $gpg->secretkey($secretkey);
	     my ($clear, $sign) = $gpg->decrypt(@xs);
	     defined $clear and $clear eq "Test\n" 
	       and ref($sign) eq 'Crypt::GPG::Signature';
	   });
      
      #! Verify Signature (GPG with GPG)
      ##################################
      skip(sub {1});
    
      #! Verify detached signature (GPG with GPG)
      #################################################
      skip(sub {1});
    }
    # Set passphrase back to original
    #################################
    skip($nogpg,
	 sub {
	   $gpg->keypass($secretkey, '', "$bits Bit $type Test Key");
	 });
  }
}
