# -*-cperl-*-
#
# keygen.t - Crypt::GPG key generation tests.
# Copyright (c) 2005-2006 Ashish Gulhati <crypt-gpg at neomailbox.com>
#
# All rights reserved. This code is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# $Id: 01-keygen.t,v 1.9 2006/12/21 12:36:35 ashish Exp $

use strict;
use Test;
use Crypt::GPG;

BEGIN { plan tests => 2 }

print STDERR <<__ENDMSG;


NOTE: If the tests are skipped, you may need to install gpg,
      and/or set the environment variable GPGBIN to the 
      location of the gpg binary.

      If the keygen test takes a long time you may need to 
      generate more randomness on your computer (by running a 
      recursive directory listing in the background, for 
      example).

__ENDMSG

my $debug = 0;
my $dir = $0 =~ /^\// ? $0 : $ENV{PWD} . '/' . $0; $dir =~ s/\/[^\/]*$//;
$ENV{HOME} = $dir;

# Create new Crypt::GPG object

my $gpg = new Crypt::GPG;
$ENV{GPGBIN} and $gpg->gpgbin($ENV{GPGBIN});

my $nogpg = 1 unless (-e $gpg->gpgbin);

$gpg->gpgopts('--compress-algo 1 --cipher-algo cast5 --force-v3-sigs --no-comment');
$gpg->debug($debug);

# Start test loop with different key sizes/types
################################################
for my $bits (qw(1024 2048)) {
  for my $type ('ELG-E') {

    # Generate key pair
    #####################
    skip($nogpg,
	 sub {
	   my $status = $gpg->keygen("A $bits $type", "$bits$type\@test.com", 
				     $type, $bits, 0, "$bits Bit $type Test Key");
	   return 0 unless $status;
	   $|=1;
	   while (<$status>) {
	     chomp; print;
	   }
	   close $status; print "\n"; $|=0;
	 }, 0);
  }
}
