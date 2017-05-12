use Test::More;
use Test::Exception;

use Business::Payment;
use Business::Payment::CreditCard;
use Business::Payment::Processor::Test::True;

throws_ok {
    my $cc = Business::Payment::CreditCard->new_with_traits(
        traits => [ 'Refund' ],
    );
} qr/^Attribute \(number\) is required/, 'number required';

my $cc = Business::Payment::CreditCard->new_with_traits(
    traits => [ 'Refund' ],
    expiration  => '04/20',
    number      => '4111111111111111',
    amount      => 10
);
isa_ok($cc, 'Business::Payment::CreditCard');

my $bp = Business::Payment->new(
    processor => Business::Payment::Processor::Test::True->new
);

my $result = $bp->handle($charge);
isa_ok($result, 'Business::Payment::Result', 'result class');
ok($result->success, 'successful charge');

done_testing;