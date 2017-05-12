# -*-cperl-*-
#
# import.t - Crypt::GPG key import tests.
# Copyright (c) 2005-2006 Ashish Gulhati <crypt-gpg at neomailbox.com>
#
# All rights reserved. This code is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.
#
# $Id: 02-import.t,v 1.4 2006/12/21 12:36:35 ashish Exp $

use strict;
use Test;
use Crypt::GPG;

BEGIN { plan tests => 1 }

my $debug = 0;
my $dir = $0 =~ /^\// ? $0 : $ENV{PWD} . '/' . $0; $dir =~ s/\/[^\/]*$//;
$ENV{HOME} = $dir;

# Create new Crypt::GPG object

my $gpg = new Crypt::GPG;
$ENV{GPGBIN} and $gpg->gpgbin($ENV{GPGBIN});

my $nogpg = 1 unless (-e $gpg->gpgbin);

$gpg->gpgopts('--compress-algo 1 --cipher-algo cast5 --force-v3-sigs --no-comment');
$gpg->debug($debug);

my @samplekeys; samplekeys();

# Import sample keys
####################
skip($nogpg,
     sub {
       for my $x (@samplekeys) {
	 my ($imported) = $gpg->addkey($x->{Key});
	 return 0 unless $imported->{ID} eq $x->{ID};
       }
       1;
     }
    );

sub samplekeys {
  push (@samplekeys, {'ID' => 'D354E162BCA6DBD1',
		      'Key' => <<__ENDKEY
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.0.6 (GNU/Linux)
Comment: For info see http://www.gnupg.org

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
=wE/r
-----END PGP PUBLIC KEY BLOCK-----
__ENDKEY
		     });
}
