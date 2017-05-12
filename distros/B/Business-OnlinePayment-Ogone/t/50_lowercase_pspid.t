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
    action => 'authorization only',
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
# test normal flow: 'authorization only' (RES) request followed by 'post authorization' (SAS) request
#########################################################################################################
$tx = new_test_tx();

    my %args = %base_args;

    $args{pspid} = delete $args{PSPID};

    ok($args{pspid}, "pspid should be defined");
    ok(!$args{PSPID}, "PSPID should not be defined");

    $tx->content( %args); eval { $tx->submit() }; #diag(Dumper($tx->http_args));
    
    is($@, '', "there should have been no warnings");
    is($tx->is_success, 1, "must be successful")
        or diag explain { req => $tx->http_args, res => $tx->result_xml};
    is($tx->error_message, undef, "error message must be undef");
    ok($tx->result_code == 0, "result_code should return 0");


$tx = new_test_tx();

    my %args2 = override_base_args_with({invoice_number => time});

    ok(!$args2{pspid}, "pspid should not be defined");
    ok($args2{PSPID}, "PSPID should be definedt");

    $tx->content( %args2 ); eval { $tx->submit() }; #diag(Dumper($tx->http_args));

    is($@, '', "there should have been no warnings");
    is($tx->is_success, 1, "must be successful")
        or diag explain { req => $tx->http_args, res => $tx->result_xml};
    is($tx->error_message, undef, "error message must be undef");
    ok($tx->result_code == 0, "result_code should return 0");


done_testing();

