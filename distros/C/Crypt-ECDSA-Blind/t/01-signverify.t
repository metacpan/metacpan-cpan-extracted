#!perl
# -*-cperl-*-
#
# 01-signverify.t - Test ECDSA blind signing and verification
# Copyright (c) 2017 Ashish Gulhati <crypt-ecdsab at hash.neo.tc>

use Test::More tests => 16;

use Crypt::ECDSA::Blind;

ok (my $ecdsab = new Crypt::ECDSA::Blind (Create => 1, DB => ':memory:'), "Create Crypt::ECDSA::Blind object");
ok (my ($pubkey, $seckey) = $ecdsab->keygen,                              "Key generation");
ok (my $pub_hex = $pubkey->as_hex,                                        "Export public key as hex");
ok ($pubkey = Crypt::ECDSA::Blind::PubKey::from_hex($pub_hex),            "Import public key from hex");
ok (my $sec_hex = $seckey->as_hex,                                        "Export secret key as hex");
ok ($seckey = Crypt::ECDSA::Blind::SecKey::from_hex($sec_hex),            "Import secret key from hex");

# ok ($pubkey->write( Filename => '/tmp/pubkey' ),                          "Save public key");
# ok ($seckey->write( Filename => '/tmp/seckey' ),                          "Save secret key");
ok (my $init = $ecdsab->init,                                             "Initialize blind signing protocol");
ok (my $init2 = $ecdsab->init,                                            "Initialize a second blind signing protocol");
ok (my $req = $ecdsab->request( Key => $pubkey,
	                        Message => 'Hello world!',
			        Init => $init ),                          "Request signature 1");
ok (my $req2 = $ecdsab->request( Key => $pubkey,
	                         Message => 'Hello, world!',
			         Init => $init2 ),                        "Request signature 2");
ok (my $bsig = $ecdsab->sign( Message => $req,
                              Key => $seckey,
                              Init => $init),                             "Create blind signature 1");
ok (my $bsig2 = $ecdsab->sign( Message => $req2,
                              Key => $seckey,
                              Init => $init2),                            "Create blind signature 2");
ok (my $sig = $ecdsab->unblind( Signature => $bsig,
                                Key => $pubkey,
				Init => $init),                           "Unblind signature 1");
ok (my $sig2 = $ecdsab->unblind( Signature => $bsig2,
                                Key => $pubkey,
				Init => $init2),                          "Unblind signature 2");
ok ($ecdsab->verify( Signature => $sig,
		     Message => 'Hello world!',
		     Key => $pubkey ),                                    "Verify signature 1");
ok ($ecdsab->verify( Signature => $sig2,
		     Message => 'Hello, world!',
		     Key => $pubkey ),                                    "Verify signature 2");

exit;
