# -*- Mode: Perl; -*-

use strict;

use Test;
use Crypt::OpenSSL::DSA;

BEGIN { plan tests => 36 }

my $message = "foo bar";

my $dsa = Crypt::OpenSSL::DSA->generate_parameters( 512, "fooooooooooooooooooo" );

$dsa->generate_key;

my $dsa_sig1 = $dsa->sign($message);
my $dsa_sig_obj1 = $dsa->do_sign($message);

my $bogus_sig = $dsa_sig1;
$bogus_sig =~ s!.a$!ba!;
$bogus_sig =~ s!.$!a!;

my $p = $dsa->get_p;
my $q = $dsa->get_q;
my $g = $dsa->get_g;
my $pub_key = $dsa->get_pub_key;
my $priv_key = $dsa->get_priv_key;

my $r = $dsa_sig_obj1->get_r;
my $s = $dsa_sig_obj1->get_s;

my $dsa_sig_obj2 = Crypt::OpenSSL::DSA::Signature->new();
$dsa_sig_obj2->set_r($r);
$dsa_sig_obj2->set_s($s);

my $dsa_sig_obj_bogus = Crypt::OpenSSL::DSA::Signature->new();
$dsa_sig_obj_bogus->set_r($s);
$dsa_sig_obj_bogus->set_s($r);

ok($dsa->verify($message, $dsa_sig1), 1);
ok($dsa->verify($message, $bogus_sig), 0);

ok($dsa->do_verify($message, $dsa_sig_obj1), 1);
ok($dsa->do_verify($message, $dsa_sig_obj2), 1);
ok($dsa->do_verify($message, $dsa_sig_obj_bogus), 0);

ok($dsa->write_params("dsa.param.pem"), 1);
ok($dsa->write_pub_key("dsa.pub.pem"), 1);
ok($dsa->write_priv_key("dsa.priv.pem"), 1);

my ($priv_key_str, $pub_key_str);
{
  local($/) = undef;
  open PRIV, "dsa.priv.pem";
  $priv_key_str = <PRIV>;
  close PRIV;
  open PUB, "dsa.pub.pem";
  $pub_key_str = <PUB>;
  close PUB;
}

my $dsa2 = Crypt::OpenSSL::DSA->read_priv_key("dsa.priv.pem");
my $dsa_sig2 = $dsa2->sign($message);

my $dsa3 = Crypt::OpenSSL::DSA->read_pub_key("dsa.pub.pem");

my $dsa4 = Crypt::OpenSSL::DSA->read_priv_key_str($priv_key_str);
my $dsa5 = Crypt::OpenSSL::DSA->read_pub_key_str($pub_key_str);

my $dsa6 = Crypt::OpenSSL::DSA->new();
$dsa6->set_p($p);
$dsa6->set_q($q);
$dsa6->set_g($g);
$dsa6->set_pub_key($pub_key);

ok($dsa6->get_p,$p);
ok($dsa6->get_q,$q);
ok($dsa6->get_g,$g);
ok($dsa6->get_pub_key,$pub_key);

ok($dsa->verify($message, $dsa_sig2), 1);
ok($dsa2->verify($message, $dsa_sig2), 1);
ok($dsa2->verify($message, $dsa_sig1), 1);
ok($dsa3->verify($message, $dsa_sig1), 1);
ok($dsa3->verify($message, $dsa_sig2), 1);
ok($dsa4->verify($message, $dsa_sig2), 1);
ok($dsa4->verify($message, $dsa_sig1), 1);
ok($dsa5->verify($message, $dsa_sig1), 1);
ok($dsa5->verify($message, $dsa_sig2), 1);
ok($dsa6->verify($message, $dsa_sig1), 1);
ok($dsa6->verify($message, $dsa_sig2), 1);

$dsa6->set_priv_key($priv_key);
ok($dsa6->get_priv_key,$priv_key);
my $dsa_sig3 = $dsa6->sign($message);

ok($dsa->verify($message, $dsa_sig3), 1);
ok($dsa2->verify($message, $dsa_sig3), 1);
ok($dsa3->verify($message, $dsa_sig3), 1);
ok($dsa4->verify($message, $dsa_sig3), 1);
ok($dsa5->verify($message, $dsa_sig3), 1);
ok($dsa6->verify($message, $dsa_sig3), 1);

# Check setting private key before public key.
# This is not suppored by OpenSSL-1.1.0.
my $dsa7 = Crypt::OpenSSL::DSA->new();
$dsa7->set_p($p);
$dsa7->set_q($q);
$dsa7->set_g($g);
ok($dsa7->get_p,$p);
ok($dsa7->get_q,$q);
ok($dsa7->get_g,$g);
$dsa7->set_priv_key($priv_key);
ok($dsa7->get_priv_key,$priv_key);
my $dsa_sig4 = $dsa7->sign($message);
$dsa7->set_pub_key($pub_key);
ok($dsa7->get_pub_key,$pub_key);
ok($dsa7->verify($message, $dsa_sig4), 1);

unlink("dsa.param.pem");
unlink("dsa.priv.pem");
unlink("dsa.pub.pem");

