use strict;
use warnings;
use Test::Most;
use Business::OnlinePayment;
use Data::Dumper;
  
#########################################################################################################
# setup from ENV
#########################################################################################################

$ENV{OGONE_PSWD} ||= '7n1tt3st';
$ENV{OGONE_PSPID} ||= 'perlunit';
$ENV{OGONE_USERID} ||= 'perltest';

bail_on_fail; 
    ok($ENV{OGONE_USERID}, "test can only proceed with environment OGONE_USERID set");
bail_on_fail; 
    ok($ENV{OGONE_PSPID}, "test can only proceed with environment OGONE_PSPID set");
bail_on_fail; 
    ok($ENV{OGONE_PSWD}, "test can only proceed with environment OGONE_PSWD set");

restore_fail;

my %base_args = (
    PSPID => $ENV{OGONE_PSPID},
    login => $ENV{OGONE_USERID},
    password => $ENV{OGONE_PSWD},
    invoice_number => time,
    amount      => '49.99',
    card_number => '4111111111111111',
    # card_number => '4000 0000 0000 0002',
    cvc => '423',
    # flag3d => 'Y',
    # win3ds => 'POPUP',
    expiration  => '12/15',
    country => 'BE',
    address => 'Nieuwstraat 32',
    sha_key => 'xxxtestingx123xpassphrasexxx',
    sha_type => 512,
    zip => 1000
);

sub new_test_tx {
    my $tx = new Business::OnlinePayment('Ogone');
    $tx->test_transaction(1);
    return $tx;
}

sub override_base_args_with {
    my $in = shift;
    my %hash = $in ? ref $in eq 'HASH' ? %$in : ($in,@_) : ();
    my %res = map { $_ => ( $hash{$_} || $base_args{$_} ) } (keys %base_args, keys %hash);
    return %res;
}

my $tx = new_test_tx();

#########################################################################################################
# test setup
#########################################################################################################
isa_ok($tx,'Business::OnlinePayment');

my %test = %base_args; $test{'foobar'} = "123";
cmp_deeply(\%test, { override_base_args_with(foobar=> 123) }, "override_base_args_with method test HASH");
cmp_deeply(\%test, { override_base_args_with({foobar=> 123}) }, "override_base_args_with method test REF");

#########################################################################################################
# test obvious failures (wrong pass, wrong cardno, wrong cvc)
#########################################################################################################
$base_args{action} = 'authorization only';

SKIP: { 
    skip "this test will block your account if you run it too frequently", 3;
    # NOTE: if account is blocked, you can reenable it in the 'Users' section of the Ogone backend.
    $tx = new_test_tx();

    $tx->content(override_base_args_with(password=>123456)); eval { $tx->submit() }; 

        like($@, qr/^$/, "there should have been no warnings");
        like($tx->error_message, qr/Some of the data entered is incorrect. Please retry./, "error message must be set");
        like($tx->result_code, qr/50001119/, "should return wrong password code");
}



### test wrong card number ...............................................................................
$tx = new_test_tx();
$tx->content(override_base_args_with(card_number=>123456)); eval { $tx->submit() }; 
    is($@, '', "there should have been no warnings");
    is($tx->is_success, 0, "must NOT be successful")
        or diag explain { req => $tx->http_args, res => $tx->result_xml};
    like($tx->error_message, qr/no brand/, "error message must be set");
    like($tx->result_code, qr/50001111/, "result_code should return 50001111");

## test empty cvc code ..................................................................................
$tx = new_test_tx();
$tx->content(override_base_args_with(cvc => 'abc')); eval { $tx->submit() }; #diag(Dumper($tx->http_args));
    is($@, '', "there should have been no warnings");
    is($tx->is_success, 0, "must NOT be successful")
        or diag explain { req => $tx->http_args, res => $tx->result_xml};
    like($tx->error_message, qr/./, "error message must be set"); # testing wrong cvc seems impossible
    like($tx->error_message, qr/The CVC code is mandatory for this type of card/, "error message must be like: 'The CVC code is mandatory for this type of card'");
    like($tx->result_code, qr/50001090/, "result_code should return 50001090");




#########################################################################################################
# test normal flow: 'authorization only' (RES) request followed by 'post authorization' (SAS) request
#########################################################################################################
my $invoice_number = time;
$tx = new_test_tx();

    $tx->content(override_base_args_with({invoice_number => $invoice_number})); eval { $tx->submit() }; # diag(Dumper($tx->http_args));
    
    is($@, '', "there should have been no warnings");
    is($tx->is_success, 1, "must be successful")
        or diag explain { req => $tx->http_args, res => $tx->result_xml};
    is($tx->error_message, undef, "error message must be undef");
    ok($tx->result_code == 0, "result_code should return 0");

## test invalid invoice number ..........................................................................
$base_args{action} = 'post authorization';
$tx = new_test_tx();

    $tx->content(override_base_args_with({invoice_number => 99999})); eval { $tx->submit() }; 

    is($@, '', "there should have been no warnings");
    is($tx->is_success, 0, "must NOT be successful")
        or diag explain { req => $tx->http_args, res => $tx->result_xml};
    like($tx->error_message, qr/unknown orderid 99999 for merchant/, "error message must be set");
    like($tx->result_code, qr/50001130/, "result_code should return 50001130 error code");

## test with previously known correct invoice number ....................................................
$base_args{action} = 'post authorization';
$tx = new_test_tx();

    $tx->content(override_base_args_with({invoice_number => $invoice_number})); eval { $tx->submit() }; 

    is($@, '', "there should have been no warnings");
    is($tx->is_success, 1, "must be successful")
        or diag explain { req => $tx->http_args, res => $tx->result_xml};
    is($tx->error_message, undef, "error message must be undef");
    ok($tx->result_code == 0, "result_code should return 0");


#########################################################################################################
# test 'post authorization' request with partial data capture
#########################################################################################################

my $invoice_number2 = time;
## create authorization request ........................................................................
$base_args{action} = 'authorization only';
$tx = new_test_tx();

    $tx->content(override_base_args_with({invoice_number => $invoice_number2, amount => 43.34 })); eval { $tx->submit() }; 

    is($@, '', "there should have been no warnings");
    is($tx->is_success, 1, "must be successful")
        or diag explain { req => $tx->http_args, res => $tx->result_xml};
    is($tx->error_message, undef, "error message must be undef");
    is($tx->result_code, 0, "result_code should return 0");

# create partial capture request .......................................................................
$base_args{action} = 'post authorization';
$tx = new_test_tx();

    $tx->content(override_base_args_with({invoice_number => $invoice_number2, operation => 'SAL', amount => 10.00 })); eval { $tx->submit() }; 

    is($@, '', "there should have been no warnings");
    is($tx->is_success, 1, "must be successful")
        or diag explain { req => $tx->http_args, res => $tx->result_xml};
    is($tx->error_message, undef, "error message must be undef");
    ok($tx->result_code == 0, "result_code should return 0");
    is($tx->result_xml->{STATUS}, 91, "status must be 91 SAL");
    like($tx->result_xml->{PAYIDSUB}, qr/^\d+$/, "sub payid must be number");

my $payid = $tx->result_xml->{PAYID};
my $payidsub = $tx->result_xml->{PAYIDSUB};

## query the transaction remotely .......................................................................
$tx = new_test_tx();

    $tx->content(invoice_number => $invoice_number2, payid => $payid, action => 'query', payidsub => $payidsub, 
                 map { $_ => $base_args{$_} } (qw/login PSPID password/)); eval { $tx->submit() }; 

    is($@, '', "there should have been no warnings");
    is($tx->is_success, 1, "must be successful")
        or diag explain { req => $tx->http_args, res => $tx->result_xml};
    is($tx->error_message, undef, "error message must be undef");
    ok($tx->result_code == 0, "result_code should return 0");
    is($tx->result_xml->{STATUS}, 91, "status must be 91 SAL");
    is($tx->result_xml->{amount}, 10, "amount must be 10");

# create a full capture request .......................................................................
$tx = new_test_tx();

    $tx->content(invoice_number => $invoice_number2, amount => 33.34, operation => 'SAS', action => 'post authorization', 
                 map { $_ => $base_args{$_} } (qw/login password PSPID sha_type sha_key/) ); eval { $tx->submit() }; 

    is($@, '', "there should have been no warnings");
    is($tx->is_success, 1, "must be successful")
        or diag explain { req => $tx->http_args, res => $tx->result_xml};
    is($tx->error_message, undef, "error message must be undef");
    ok($tx->result_code == 0, "result_code should return 0");
    is($tx->result_xml->{STATUS}, 91, "status must be 91 SAS");
    like($tx->result_xml->{PAYIDSUB}, qr/^\d+$/, "sub payid must be number");

## refund partially ......................................................................................
# FIXME: can only be tested with sleep 86400 :-)
#
# test failing refunds:
#$tx = new_test_tx();
#$tx->content(invoice_number => $invoice_number2, payid => $payid, payidsub => $payidsub, operation => 'RFD', action => 'post authorization', amount => 12.24, map { $_ => $base_args{$_} } (qw/login password PSPID/) ); eval { $tx->submit() }; 
#is($@, '', "there should have been no warnings");
#is($tx->is_success, 0, "must be not successful, it was just transacted and is still in 91 state");
#like($tx->error_message, qr/Operation is not allowed/, "error message must be contain operation not allowed");
#like($tx->error_message, qr/status \(91\)/, "error message must be contain status\(91\)");

##########################################################################################################
# full refund
##########################################################################################################
#my $invoice_number3 = time;
#$tx = new_test_tx(); $tx->content(override_base_args_with(action => 'authorization only',invoice_number => $invoice_number3)); eval { $tx->submit() };
#is($@, '', "there should have been no warnings");
#diag(Dumper($tx->http_args));
#diag(Dumper($tx->result_xml));
#is($tx->is_success, 1, "must be successful");
#is($tx->error_message, undef, "error message must be undef");
#ok($tx->result_code == 0, "result_code should return 0");
#is($tx->result_xml->{STATUS}, 5, "status must be 5 RES");
#
#$tx = new_test_tx(); $tx->content(override_base_args_with(action => 'post authorization',invoice_number => $invoice_number3)); eval { $tx->submit() };
#is($@, '', "there should have been no warnings");
#diag(Dumper($tx->http_args));
#diag(Dumper($tx->result_xml));
#is($tx->is_success, 1, "must be successful");
#is($tx->error_message, undef, "error message must be undef");
#ok($tx->result_code == 0, "result_code should return 0");
#is($tx->result_xml->{STATUS}, 91, "status must be 91 SAL");
#
#$tx = new_test_tx(); $tx->content(override_base_args_with(action => 'post authorization',invoice_number => $invoice_number3, operation => 'RFD')); eval { $tx->submit() };
#is($@, '', "there should have been no warnings");
#diag(Dumper($tx->http_args));
#diag(Dumper($tx->result_xml));
#is($tx->is_success, 1, "must be successful");
#is($tx->error_message, undef, "error message must be undef");
#ok($tx->result_code == 0, "result_code should return 0");
#is($tx->result_xml->{STATUS}, 91, "status must be 91 SAL");




done_testing();

