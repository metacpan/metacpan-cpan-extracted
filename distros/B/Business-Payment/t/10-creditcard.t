use Test::More;

use Business::Payment::CreditCard;

my $cc = Business::Payment::CreditCard->new(
    number      => 4111111111111111,
    expiration  => '03/20',
    amount      => 10,
);

isa_ok($cc, 'Business::Payment::CreditCard');
cmp_ok($cc->expiration_formatted('%m%y'), '==', '0320', 'expiration formatting');

done_testing;