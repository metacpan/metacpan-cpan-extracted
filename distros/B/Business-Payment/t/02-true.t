use Test::More tests => 2;

use Business::Payment;
use Business::Payment::Charge;
use Business::Payment::Processor::Test::True;

my $bp = Business::Payment->new(
    processor => Business::Payment::Processor::Test::True->new
);

my $charge = Business::Payment::Charge->new(
    amount => 10.00
);

my $result = $bp->handle($charge);
isa_ok($result, 'Business::Payment::Result', 'result class');
ok($result->success, 'successful charge');