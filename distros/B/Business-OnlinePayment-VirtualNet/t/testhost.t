BEGIN { $| = 1; print "1..1\n"; }

use Business::OnlinePayment;

my $tx = new Business::OnlinePayment("VirtualNet");

$tx->testhost;

if($tx->is_success()) {
    print "ok 1\n";
} else {
    warn "*******". $tx->error_message. "*******";
    print "not ok 1\n";
}
