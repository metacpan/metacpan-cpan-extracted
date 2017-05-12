use Test::More;
use strict; use warnings FATAL => 'all';

use Crypt::ZCert;

my $soname;
eval {; $soname = Crypt::ZCert->new->zmq_soname };
if (my $err = $@) {
  if ($err =~ /search.path|requires.ZeroMQ/) {
    BAIL_OUT "OS unsupported - $err"
  } else {
    die $@
  }
}

eval {; Crypt::ZCert->new->generate_keypair };
if (my $err = $@) {
  if ($err =~ /\(45\)|\(86\)/) {
    BAIL_OUT "OS unsupported - libzmq missing CURVE support: $err"
  } else {
    die $@
  }
}

ok $soname, 'have libzmq soname';
diag "Testing against libzmq: '$soname'";

done_testing
