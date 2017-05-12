BEGIN {
  $| = 1; print "1..1\n";
  eval "use Net::SSLeay;";
  if ( $@ ) {
    print "ok 1 # Skipped: Net::SSLeay is not installed\n"; exit;
  }

}
END {print "not ok 1\n" unless $loaded;}
use Business::OnlinePayment::TransactionCentral;
$loaded = 1;
print "ok 1\n";
