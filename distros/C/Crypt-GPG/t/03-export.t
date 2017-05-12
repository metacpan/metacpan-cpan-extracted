# -*-cperl-*-
#
# export.t - Crypt::GPG key export tests.
# Copyright (c) 2005-2006 Ashish Gulhati <crypt-gpg at neomailbox.com>
#
# All rights reserved. This code is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# $Id: 03-export.t,v 1.6 2006/12/21 12:36:35 ashish Exp $

use strict;
use Test;
use Crypt::GPG;

BEGIN { plan tests => 10 }

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

    # Export our public key
    #######################
    my $publickey; my $pub;

    skip($nogpg,
	 sub {
	   ($publickey) = grep { $_->{Type} =~ /^pub[^\@]?/ } $gpg->keyinfo("A $bits $type");
	   $pub = $gpg->export($publickey);
	 });

    # Pretend import public key
    ###########################
    skip($nogpg,
	 sub {
	   my ($imported) = $gpg->addkey($pub, 1);
	   $publickey->{ID} eq $imported->{ID};
	 });
    
    # Really import public key
    ##########################
    skip($nogpg,
	 sub {
	   my ($imported) = $gpg->addkey($pub);
	   $publickey->{ID} eq $imported->{ID};
	 });
    
    # Export secret key
    ###################
    my $secretkey; my $sec;
    
    skip($nogpg,
	 sub {
	   ($secretkey) = grep { $_->{Type} =~ /^sec[^\@]?/ } $gpg->keyinfo("A $bits $type");
	   $sec = $gpg->export($secretkey);
	 });
    
    # Import secret key
    ###################
    skip(1, sub {
	   $gpg->addkey($sec);
	 });
  }
}
