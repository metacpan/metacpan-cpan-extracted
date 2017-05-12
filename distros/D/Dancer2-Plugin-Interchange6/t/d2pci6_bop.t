use strict;
use warnings;

BEGIN {
    $ENV{DANCER_CONFDIR} = 't';
}

use Test::More;
use Test::Deep;
use Test::Exception;

use Dancer2;
use Dancer2::Plugin::Interchange6::Business::OnlinePayment;
use lib 't/lib';

my ( $bop, $log );

lives_ok {
    $bop =
      Dancer2::Plugin::Interchange6::Business::OnlinePayment->new( 'MockDie' );
}
"create mock bop object with provider MockDie";

throws_ok {
    $bop->charge( amount => 1, type => 'CC', action => 'Authorization Only' )
}
qr/Payment with provider MockDie failed/, "Payment with provider MockDie dies";

lives_ok {
    $bop = Dancer2::Plugin::Interchange6::Business::OnlinePayment->new(
        'MockFail',
        type      => 'CC',
        action    => 'Authorization Only'
      )
}
"create mock bop object with provider MockFail";

lives_ok { $bop->charge( amount => 1 ) } "charge lives";

ok !$bop->is_success, "is_success is false";
cmp_ok $bop->error_code,    'eq', 'declined',    "error code declined";
cmp_ok $bop->error_message, 'eq', 'invalid cvc', "error_message invalid cvc";

lives_ok {
    $bop =
      Dancer2::Plugin::Interchange6::Business::OnlinePayment->new( 'MockSuccess')
}
"create mock bop object with provider MockSuccess";

lives_ok { $bop->charge( amount => 1 ) } "charge lives";

ok $bop->is_success,        "is_success is true";
cmp_ok $bop->authorization, '==', 1, "we have authorization == 1";
cmp_ok $bop->order_number,  '==', 1001, "we have order_number = 1001";

lives_ok {
    $bop =
      Dancer2::Plugin::Interchange6::Business::OnlinePayment->new( 'MockPopup',
        test_type => "success", server => "www.example.com" )
}
"create MockPopup bop object";

lives_ok { $bop->charge( amount => 1 ) } "charge lives";

ok $bop->is_success, "is_success is true";

done_testing();
