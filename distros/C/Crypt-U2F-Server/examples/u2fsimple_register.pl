#!/usr/bin/env perl

use strict;
use warnings;

BEGIN {
    unshift @INC, "../lib";
}

my $u2fhost = '/usr/local/bin/u2f-host';
my $appId = 'Example';
my $origin = 'http://127.0.0.1';

use Crypt::U2F::Server::Simple;
use MIME::Base64;

my $auth = Crypt::U2F::Server::Simple->new(appId=>$appId, origin=>$origin);
if(!defined($auth)) {
    die(Crypt::U2F::Server::Simple::lastError());
}

my $challenge = $auth->registrationChallenge();
if(!defined($challenge) || !length($challenge)) {
    die($auth->lastError());
}
open(my $cofh, '>', 'regChallenge.dat') or die($!);
print $cofh $challenge;
close $cofh;

my $regcmd = $u2fhost . ' -aregister -o "' . $origin . '" < regChallenge.dat > regReply.dat';
print "Running $regcmd...\nPlease press the blinking button!\n";
`$regcmd`;

open(my $cifh, '<', 'regReply.dat') or die($!);
my $reply = <$cifh>;
close $cifh;

print "Got $reply\n";

my ($keyHandle, $publicKey) = $auth->registrationVerify($reply);

if(!defined($keyHandle)) {
    print "failed to get keyHandle!\n";
}

if(!defined($publicKey)) {
    print "failed to get publicKey!\n";
}

if(!defined($keyHandle) || !defined($publicKey)) {
    die($auth->lastError());
}

open(my $kofh, '>', 'keyHandle.dat') or die($!);
print $kofh $keyHandle;
close $kofh;

open(my $pofh, '>', 'publicKey.dat') or die($!);
print $pofh encode_base64($publicKey, '');
close $pofh;
