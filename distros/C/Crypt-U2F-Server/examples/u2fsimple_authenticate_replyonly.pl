#!/usr/bin/env perl

use strict;
use warnings;

BEGIN {
    unshift @INC, "../lib";
}

my $u2fhost = '/usr/local/bin/u2f-host';
my $appId = 'Example';
my $origin = 'http://127.0.0.1';

my $challengeID = 'HelloWorldSECRETKEY';

use Crypt::U2F::Server::Simple;
use MIME::Base64;

open(my $kifh, '<', 'keyHandle.dat') or die($!);
my $keyHandle = <$kifh>;
close $kifh;

open(my $pifh, '<', 'publicKey.dat') or die($!);
my $publicKey = <$pifh>;
$publicKey = decode_base64($publicKey);
close $pifh;

my $auth = Crypt::U2F::Server::Simple->new(appId=>$appId, origin=>$origin,
                                    keyHandle=>$keyHandle, publicKey=>$publicKey);
if(!defined($auth)) {
    die(Crypt::U2F::Server::Simple::lastError());
}

my $rc = $auth->setChallenge($challengeID);
if(!$rc) {
    die($auth->lastError());
}

open(my $cifh, '<', 'authReply.dat') or die($!);
my $reply = <$cifh>;
close $cifh;

print "Got $reply\n";

my ($isValid) = $auth->authenticationVerify($reply);
if($isValid) {
    print "Hurray! User has been verified as valid!\n";
} else {
    print "Oh no, verification failed! The reason is: ", $auth->lastError(), "\n";
}
