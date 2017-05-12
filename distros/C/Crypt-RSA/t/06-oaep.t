#!/usr/bin/perl -sw
##
## 06-oaep.t
##
## Copyright (c) 2000, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id: 06-oaep.t,v 1.3 2001/04/06 18:33:31 vipul Exp $

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Crypt::RSA::ES::OAEP;
use Crypt::RSA::Key;

print "1..2\n";
my $i = 0;
my $oaep = new Crypt::RSA::ES::OAEP;
my $message = "My plenteous joys, Wanton in fullness, seek to hide themselves.";
my $keychain = new Crypt::RSA::Key;
my ($pub, $priv) = $keychain->generate ( Size => 1024, Password => 'xx', Identity => 'xx', Verbosity => 1 ) or 
                    die $keychain->errstr();


print 86 == $oaep->encryptblock(Key => $pub) ? "ok" : "not ok"; print " ", ++$i, "\n";

my $ct = $oaep->encrypt (Key => $pub, Message => $message);
     die $oaep->errstr unless $ct;
my $pt = $oaep->decrypt (Key => $priv, Cyphertext => $ct);
    die die $oaep->errstr unless $pt;

print "$pt\n";
print $pt eq $message ? "ok" : "not ok"; print " ", ++$i, "\n";

