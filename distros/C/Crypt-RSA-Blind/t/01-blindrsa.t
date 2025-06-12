#!perl
# -*-cperl-*-
#
# 01-signverify.t - Test blind signing and verification
# Copyright (c) Ashish Gulhati <crypt-rsab at hash.neo.email>

use Test::More tests => 12;
use Try::Tiny;

BEGIN {
    use_ok( 'Crypt::RSA::Blind' ) || print "Bail out!\n";
}

diag( "Testing Crypt::RSA::Blind $Crypt::RSA::Blind::VERSION, Perl $], $^X" );

my $rsab = new Crypt::RSA::Blind;

ok (my ($pubkey, $seckey) = $rsab->keygen(Size => 1024), "Key generation");
for (1,0) {
  $rsab->set_oldapi($_);
  diag ($_ ? "Old API compatible wrapper methods" : "Deprecated methods");
  ok (my $init = $rsab->init, "Initialize blind signing");
  my ($req, $bsigned, $signed, $verified) = ();
  try { $req = $rsab->request(Key => $pubkey, Message => "Hello world", Init => $init) }
  catch { warn $_ };
  ok ($req, "Create signing request");
  try { $bsigned = $rsab->sign(Key => $seckey, PublicKey => $pubkey, Message => $req, Init => $init) }
  catch { warn $_ };
  ok ($bsigned, "Create blind signature");
  try { $signed = $rsab->unblind(Signature => $bsigned, Key => $pubkey, Init => $init) }
  catch { warn $_ };
  ok ($signed, "Unblind signature");
  try { $verified = $rsab->verify(Key => $pubkey, Signature => $signed, Message => "Hello world") }
  catch { warn $_ };
  ok ($verified, "Verify signature");
}

exit;

