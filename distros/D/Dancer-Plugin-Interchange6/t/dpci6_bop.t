use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;

use Dancer qw/set/;
use Dancer::Plugin::Interchange6::Business::OnlinePayment;
use lib 't/lib';

set log    => 'debug';
set logger => 'capture';

my ( $bop, $log );
my $trap = Dancer::Logger::Capture->trap;

lives_ok {
    $bop =
      Dancer::Plugin::Interchange6::Business::OnlinePayment->new( 'MockDie' );
}
"create mock bop object with provider MockDie";

throws_ok {
    $bop->charge( amount => 1, type => 'CC', action => 'Authorization Only' )
}
qr/Payment with provider MockDie failed/, "Payment with provider MockDie dies";

lives_ok {
    $bop = Dancer::Plugin::Interchange6::Business::OnlinePayment->new(
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

$log = $trap->read;
cmp_deeply(
    $log,
    superbagof(
        {
            level   => "debug",
            message => "Card was rejected by MockFail: invalid cvc",
        }
    ),
    "got expected debug messages"
) or diag explain $log;

lives_ok {
    $bop =
      Dancer::Plugin::Interchange6::Business::OnlinePayment->new( 'MockSuccess')
}
"create mock bop object with provider MockSuccess";

lives_ok { $bop->charge( amount => 1 ) } "charge lives";

ok $bop->is_success,        "is_success is true";
cmp_ok $bop->authorization, '==', 1, "we have authorization == 1";
cmp_ok $bop->order_number,  '==', 1001, "we have order_number = 1001";

$log = $trap->read;
cmp_deeply(
    $log,
    superbagof(
        {
            level   => "debug",
            message => "Successful payment, authorization: 1",
        },
        {
            level   => "debug",
            message => "Order number: 1001",
        },
    ),
    "got expected debug messages"
) or diag explain $log;

lives_ok {
    $bop =
      Dancer::Plugin::Interchange6::Business::OnlinePayment->new( 'MockPopup',
        test_type => "success", server => "www.example.com" )
}
"create MockPopup bop object";

lives_ok { $bop->charge( amount => 1 ) } "charge lives";

ok $bop->is_success, "is_success is true";

$log = $trap->read;
cmp_deeply(
    $log,
    superbagof(
        {
            level => "debug",
            message =>
              "Success!  Redirect browser to http://localhost/payment_popup",
        },
    ),
    "got expected debug messages"
) or diag explain $log;

done_testing();
