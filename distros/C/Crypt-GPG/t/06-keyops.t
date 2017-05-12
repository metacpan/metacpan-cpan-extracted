# -*-cperl-*-
#
# keyops.t - Crypt::GPG key manipulation tests.
# Copyright (c) 2005-2006 Ashish Gulhati <crypt-gpg at neomailbox.com>
#
# All rights reserved. This code is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# $Id: 06-keyops.t,v 1.5 2006/12/21 12:36:35 ashish Exp $

use strict;
use Test;
use Crypt::GPG;

BEGIN { plan tests => 30 }

my $debug = 0;
my $dir = $0 =~ /^\// ? $0 : $ENV{PWD} . '/' . $0; $dir =~ s/\/[^\/]*$//;
$ENV{HOME} = $dir;

my @samplekeys; samplekeys();

# Create new Crypt::GPG object

my @x;
my $gpg = new Crypt::GPG;
$ENV{GPGBIN} and $gpg->gpgbin($ENV{GPGBIN});

my $nogpg = 1 unless (-e $gpg->gpgbin);

$gpg->gpgopts('--compress-algo 1 --cipher-algo cast5 --force-v3-sigs --no-comment');
$gpg->debug($debug);

unless ($nogpg) {
  for my $x (@samplekeys) {
    my ($imported) = $gpg->addkey($x->{Key});
    return 0 unless $imported->{ID} eq $x->{ID};
  }
}

# Start test loop with different key sizes/types
################################################
for my $bits (qw(1024 2048)) {
  for my $type ('ELG-E') {

    my @mykeys; @mykeys = $gpg->keyinfo("A $bits $type") unless $nogpg;
    my ($publickey) = grep { $_->{Type} =~ /^pub[^\@]?/ } @mykeys;
    my ($secretkey) = grep { $_->{Type} =~ /^sec[^\@]?/ } @mykeys;
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

      # Local-sign all sample public keys
      ###################################
      #! Test check for already signed.
      #! Test check for UID out of range. It's broken.
      skip($nogpg,
	   sub {
	     for my $x (@samplekeys) {
	       return unless $gpg->certify($x->{ID}, 1, 0, 0);
	     }
	     1;
	   });
      
      # Sign all sample public keys
      #############################
      skip($nogpg,
	   sub {
	     for my $x (@samplekeys) {
	       return unless $gpg->certify($x->{ID}, 0, 0, 0);
	     }
	     1;
	   });
      
      #! Verify key signatures
      ########################
      skip(sub {1});

      # Change key trust
      ##################
      skip($nogpg,
	   sub {
	     $gpg->keytrust($publickey, 3);
	   });
      
      # Disable key
      #############
      skip($nogpg,
	   sub {
	     $gpg->disablekey($publickey);
	   });
      
      # Enable key
      ############
      skip($nogpg,
	   sub {
	     $gpg->enablekey($publickey);
	   });
      
    }

    # Set passphrase back to original
    #################################
    skip($nogpg,
	 sub {
	   $gpg->keypass($secretkey, '', "$bits Bit $type Test Key");
	 });
    
    # Delete GPG key pair
    #####################
    skip($nogpg,
	 sub {
	   $gpg->delkey($secretkey);
	 });
  }
}

sub samplekeys {
  push (@samplekeys, 
	{'ID' => '143C9F41D8F056DD',
	 'Key' => <<__ENDKEY
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.2.4

mQENAzgus1wAAAEIAOZ707105iVS2aTDVIVzDg0gAm8//PzKiZFAuJLpI1IWG4AW
LdGdQYvSR0z1Xn6BcZXvrDabN/TNlmqXuJXPgI9gTsEmfjgz2Zoyui556iaWt9Gq
c+q9qz1PR7IawKbiuMP48j6ef+YUH5ju68w7YAnS9MjK+GidtXa7IHryuApRRWHC
q8SWb+ipv/SizVt44R1RSshS6Oxsfddrz4jc+XTMFW73I8O5OGsopNUDWLTK+ncj
/J0SaMbPJ1PkPEGwrGf0yl/XhZ/9VxcjgyNClmdH1SxkgEGBFQXU4ODqVuFu5Z1P
X0qwe4JpGhuFhNxHM6zNnCQiS1x6FDyfQdjwVt0ABRG0IEFkYW0gQmFjayA8YWRh
bUBjeXBoZXJzcGFjZS5vcmc+iQEVAwUQOC6zoD57yqgoskVRAQGL7gf7Bad9KKoc
gWM6U3uwxoKql1sSwIGRzzzLl9LTTfVTDRXeCsCxHm37nF19kDMeRQp/LgVfIu02
pByNbdGf35ypvHZECqi9NdZJjP89HG0XhXSuzL9RgpUX9tw3ePUNyRZlRKOjkr/8
V4w2IHg0TcJiOQWFISmGXpNzVkQ+KnRoD6JpO9yAaV/SGtUQMgVCi82I0sLlxp/Q
urEEX1dc1ZwoBEDqITR38sLLyQg3BvQbpdIf9Msgm5yo89/h9L4OjjKJ/z++vsJN
5LyDpEfck0XDoNDZmE8XrzC55hZ7p1nBj9cAxFXL6+auh2nCqGUS9f+i+ph1kBiI
NiFbzPhq9EImrYkBFQMFEDgus1wUPJ9B2PBW3QEBK4UH/ApFtrRzOoUpBiZ6CKjT
8aMff7+qLXsIT1zlr1ZK4YCnY+ETS/WIMYhQE+sYjA4A+LyEDuhVOpuSk9nRPtK8
H7OhgPkp0X4u4hd3A3hsKtzAGgmHxMJVohPnfTH86OYjT7TAHVDGziQKwp76LW9t
rvkAzeYESRXy1JubtY0rOwd0+Ql3MCHrZFLB7Si3TAVyhmimrxTUY8sYl6DvzaER
uCwPNsBS319jcNEuDA5fyCEHbTNoMd+HMwTQ300qWXzMe4ZNOIrdelLW5QiYK/Rr
BHprmDyhkHYCmBvdGnWiNvG5q+FhioIWd4DJbnx9E8dH6B51NcDL3zsb0xTVJ9ZL
0Ik=
=LGiQ
-----END PGP PUBLIC KEY BLOCK-----
__ENDKEY
		     });
}
