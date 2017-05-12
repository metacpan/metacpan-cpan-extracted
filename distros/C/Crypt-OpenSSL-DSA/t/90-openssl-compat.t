# -*- Mode: Perl; -*-

# test file added by Brad Fitzpatrick in response to bugs found by Karl Koscher
# related to null bytes in SHA1 signatures, and strlen truncating the message
# being signed/verified

use strict;

use Test;
use Crypt::OpenSSL::DSA;

BEGIN { plan tests => 84 }

my $HAS_SHA1 = eval "use Digest::SHA; 1;";
my ($OPEN_SSL, $testable);
if($^O !~ /mswin32/i) {
  $OPEN_SSL = `which openssl` || "/usr/bin/openssl";
  chomp $OPEN_SSL;
  $testable = -x $OPEN_SSL && $HAS_SHA1;
  }
else {
  $OPEN_SSL = "openssl";
  eval{`openssl version`};
  if(!$@) {$testable = 1 && $HAS_SHA1}
  }
my $why_skip = $HAS_SHA1 ? "Need openssl binary in path" : "Need Digest::SHA to test";

my $dsa = Crypt::OpenSSL::DSA->generate_parameters( 512, "fooooooooooooooooooo" );
$dsa->generate_key;

ok($dsa->write_pub_key("dsa.pub.pem"), 1);
ok($dsa->write_priv_key("dsa.priv.pem"), 1);

my $dsa_pub = Crypt::OpenSSL::DSA->read_pub_key("dsa.pub.pem");
ok($dsa_pub);
my $dsa_priv = Crypt::OpenSSL::DSA->read_priv_key("dsa.priv.pem");
ok($dsa_priv);

my $to_do = 500;
my $of_each = 20;

if ($testable) {
    my %done;  # { zero => $ct, nonzero => $ct }
    for (1..$to_do) {
        my $plain = "This is test number $_";
        my $msg = Digest::SHA::sha1($plain);
        my $type = ($msg =~ /\x00/) ? "zero" : "nonzero";
        next if $done{$type}++ >= $of_each;

        my $sig = $dsa_priv->sign($msg);

        my $we_think       = $dsa_pub->verify($msg, $sig);
        my $openssl_think  = openssl_verify("dsa.pub.pem", $sig, $plain);

        ok($we_think, 1);
        ok($openssl_think, 1);
    }
} else {
    for (1..($of_each*4)) {
        print "ok # Skip $why_skip\n";
    }
}

unlink("dsa.priv.pem");
unlink("dsa.pub.pem");

sub openssl_verify {
    my ($public_pem_file, $sig, $msg_plain) = @_;
    require File::Temp;
    my $sig_temp = new File::Temp(TEMPLATE => "tmp.signatureXXXX") or die;
    my $msg_temp = new File::Temp(TEMPLATE => "tmp.msgXXXX") or die;
    syswrite($sig_temp,$sig);
    syswrite($msg_temp,$msg_plain);
    # FIXME: shutup openssl from spewing to STDOUT the "Verification
    # OK".  can we depend on reading "Verification OK" from the
    # open("-|", "openssl") open mode due to portability?
    my $rv = system("openssl", "dgst", "-sha1", "-verify", $public_pem_file, "-signature", "$sig_temp", "$msg_temp");
    return 0 if $rv;
    return 1;
}

