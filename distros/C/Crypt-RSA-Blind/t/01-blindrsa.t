#!perl
# -*-cperl-*-
#
# 01-signverify.t - Test blind signing and verification
# Copyright (c) 2016-2017 Ashish Gulhati <crypt-rsab at hash.neo.tc>

use Test::More tests => 7;

BEGIN {
    use_ok( 'Crypt::RSA::Blind' ) || print "Bail out!
";
}

diag( "Testing Crypt::RSA::Blind $Crypt::RSA::Blind::VERSION, Perl $], $^X" );

my $rsab = new Crypt::RSA::Blind;

ok (my ($pubkey, $seckey) = $rsab->keygen(Size => 1024), "Key generation");
ok (my $init = $rsab->init, "Initialize blind signing");
ok (my $req = $rsab->request(Key => $pubkey, Message => "Hello world", Init => $init), "Request signature");
ok (my $bsigned = $rsab->sign(Key => $seckey, Plaintext => $req, Init => $init), "Create blind signature");
ok (my $signed = $rsab->unblind(Signature => $bsigned, Key => $pubkey, Init => $init), "Unblind signature");
ok ($rsab->verify(Key => $pubkey, Signature => $signed, Message => "Hello world"), "Verify signature");

exit;

