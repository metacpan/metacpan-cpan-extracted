#!/usr/bin/perl -w
# $Id: ship.pl,v 1.6 2004/08/09 16:07:14 jay.powers Exp $
use strict;
use Business::FedEx::DirectConnect;

my $t = Business::FedEx::DirectConnect->new(uri=>''
                                ,acc => '' #FedEx Account Number
                                ,meter => '' #FedEx Meter Number (This is given after you subscribe to FedEx)
                                ,referer => 'Vermonster' # Name or Company
                                ,Debug => 1
                                );

# 2016 is the UTI for FedEx.  If you don't know what this is
# you need to read the FedEx Documentation.
# http://www.fedex.com/globaldeveloper/shipapi/
# The hash values are case insensitive.
$t->set_data(3000,
    'sender_company' => 'Vermonster LLC',
    'sender_address_line_1' => '312 stuart st',
    'sender_city' => 'Boston',
    'sender_state' => 'MA',
    'sender_postal_code' => '02134',
    'recipient_contact_name' => 'Jay Powers',
    'recipient_address_line_1' => '44 Main street',
    'recipient_city' => 'Boston',
    'recipient_state' => 'MA',
    'recipient_postal_code' => '02116',
    'recipient_phone_number' => '6173335555',
    'weight_units' => 'LBS',
    'sender_country_code' => 'US',
    'recipient_country' => 'US',
    'sender_phone_Number' => '6175556985',
    'packaging_type' => '01',
    'pay_type' => '1',
    'customs_declared_value_currency_type' => 'USD',
    'service_type' => '92',
    'ship_date' => '20040809',
    'total_package_weight' => '1.0',
    'label_type' => '2',
    'label_printer_type' => '1',
    'label_media_type' => '5',
    'drop_off_type' => '1',
    'future_day_shipment'=>'N'
) or die $t->errstr;

$t->transaction() or die $t->errstr;

print $t->lookup('tracking_number');

$t->label("myLabel.png");
