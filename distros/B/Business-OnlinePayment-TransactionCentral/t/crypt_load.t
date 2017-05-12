BEGIN {
  $| = 1; print "1..1\n";
  eval "use Crypt::SSLeay;";
  if ( $@ ) {
    print "ok 1 # Skipped: Crypt::SSLeay is not installed\n"; exit;
  }
  $Business::OnlinePayment::HTTPS::skip_NetSSLeay=1;
  $Business::OnlinePayment::HTTPS::skip_NetSSLeay=1;
}
END {print "not ok 1\n" unless $loaded;}
use Business::OnlinePayment::TransactionCentral;
$loaded = 1;
print "ok 1\n";
