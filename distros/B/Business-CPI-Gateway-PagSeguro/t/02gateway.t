#!/usr/bin/env perl
use utf8;
use warnings;
use strict;
use Test::More;
use FindBin '$Bin';
use Business::CPI::Gateway::PagSeguro;
use Encode;

sub cleanup {
    unlink "$Bin/data/pagseguro_notification_completed.xml"
        if -f "$Bin/data/pagseguro_notification_completed.xml";
    unlink "$Bin/data/pagseguro_notification_failed.xml"
        if -f "$Bin/data/pagseguro_notification_failed.xml";
}

sub get_value_for {
    my ($form, $name) = @_;
    return $form->look_down(_tag => 'input', name => $name )->attr('value');
}

ok(my $cpi = Business::CPI::Gateway::PagSeguro->new(
    receiver_id => 'andre@andrewalker.net',
    token       => '123456',
), 'build $cpi');

isa_ok($cpi, 'Business::CPI::Gateway::PagSeguro');

ok(my $cart = $cpi->new_cart({
    buyer => {
        name  => 'Mr. Buyer',
        email => 'sender@andrewalker.net',
    }
}), 'build $cart');

ok($cart->does('Business::CPI::Role::Cart'), 'cart implements the correct role');

ok(my $item = $cart->add_item({
    id          => 1,
    quantity    => 1,
    price       => 200,
    description => 'my desc',
}), 'build $item');

ok(my $form = $cart->get_form_to_pay(123), 'get form to pay');
isa_ok($form, 'HTML::Element');

is(get_value_for($form, 'itemId1'),       '1', 'itemId1');
is(get_value_for($form, 'itemQuantity1'), '1', 'itemQuantity1');
is(get_value_for($form, 'itemAmount1'),   '200.00', 'itemAmount1');
is(get_value_for($form, 'reference'),     '123', 'reference');
is(get_value_for($form, 'senderEmail'),   'sender@andrewalker.net', 'sender email');
is(get_value_for($form, 'senderName'),    'Mr. Buyer', 'sender name');

{
    no warnings 'redefine';
    *Business::CPI::Gateway::PagSeguro::get_notifications_url = sub {
        "file://$Bin/data/pagseguro_notification_completed.xml"
    };
}

{
    local $/ = undef;
    open my $fh, '<', "$Bin/data/pagseguro_notification.xml" or die $!;
        my $contents = <$fh>;
    close $fh;

    $contents = decode( 'utf-8', $contents );
    $contents =~ s[__PAYMENT_ID__][1];
    $contents =~ s[__STATUS__][3];

    open my $write_fh, '>', "$Bin/data/pagseguro_notification_completed.xml" or die $!;
        print $write_fh $contents;
    close $write_fh;
}

{
    my $not = $cpi->get_and_parse_notification('766B9C-AD4B044B04DA-77742F5FA653-E1AB24');
    is_deeply($not, {
        net_amount => '200.00',
        gateway_transaction_id => '9E884542-81B3-4419-9A75-BCC6FB495EF1',
        payment_id => 1,
        status     => 'completed',
        amount     => '200.00',
        date       => '2011-02-10T16:13:41.000-03:00',
        payer      => {
            name => encode_utf8("João da Silva"),
        },
        exchange_rate => 0,
        fee => '0.00'
    }, 'notification for completed transaction');
}

{
    no warnings 'redefine';
    *Business::CPI::Gateway::PagSeguro::get_notifications_url = sub {
        "file://$Bin/data/pagseguro_notification_failed.xml"
    };
}

{
    local $/ = undef;
    open my $fh, '<', "$Bin/data/pagseguro_notification.xml" or die $!;
        my $contents = <$fh>;
    close $fh;

    $contents = decode( 'utf-8', $contents );
    $contents =~ s[__PAYMENT_ID__][abc];
    $contents =~ s[__STATUS__][7];

    open my $write_fh, '>', "$Bin/data/pagseguro_notification_failed.xml" or die $!;
        print $write_fh $contents;
    close $write_fh;
}

{
    my $not = $cpi->get_and_parse_notification('766B9C-AD4B044B04DA-77742F5FA653-E1AB24');
    is_deeply($not, {
        net_amount => '200.00',
        gateway_transaction_id => '9E884542-81B3-4419-9A75-BCC6FB495EF1',
        payment_id => 'abc',
        status     => 'failed',
        amount     => '200.00',
        date       => '2011-02-10T16:13:41.000-03:00',
        payer      => {
            name => encode_utf8("João da Silva"),
        },
        exchange_rate => 0,
        fee => '0.00'
    }, 'notification for failed transaction');
}

{
    no warnings qw/redefine once/;
    *Business::CPI::Gateway::PagSeguro::get_transaction_query_url = sub {
        "file://$Bin/data/pagseguro_transactions.xml"
    };
    *Business::CPI::Gateway::PagSeguro::get_transaction_details_url = sub {
        "file://$Bin/data/pagseguro_transaction_details.xml"
    };
}

{
    my $expected = {
        current_page         => 1,
        results_in_this_page => 10,
        total_pages          => 1,
        transactions         => [
            {
                net_amount => '49900.50',
                gateway_transaction_id => '9E884542-81B3-4419-9A75-BCC6FB495EF1',
                amount      => '49900.00',
                date        => "2011-02-05T15:46:12.000-02:00",
                payment_id  => "REF1234",
                status      => "completed",
                buyer_email => 'comprador@uol.com.br',
                payer      => {
                    name => encode_utf8("JosÃ© Comprador"),
                },
                exchange_rate => 0,
                fee => '0.00'
            }
        ]
    };

    is_deeply($cpi->get_and_parse_transactions(), $expected, 'it parses the file correctly');
}

cleanup();

done_testing;
