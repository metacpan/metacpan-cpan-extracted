#!perl

use strict;
use warnings;

use lib 'lib';
use Test::More;
use Test::BDD::Cucumber::StepFile;
use Business::OnlinePayment::BitPay::Client;
use Try::Tiny;
use Env;
require Business::OnlinePayment::BitPay::KeyUtils;
require 'features/step_definitions/helpers.pl';

my $client;
my $price;
my $currency;
my %invoice;

Given 'the user is authenticated with BitPay', sub{ 
    $client = setClient();
};

Given 'that a user knows an invoice id', sub{
    $client = setClient();
    %invoice = $client->create_invoice(price => "101", currency => "USD", params => {});
};

When qr/the user creates an invoice for "(.+)?" "(.+)?"/, sub{
    try {
        $price = "";
        $currency = "";
        $price = $1 if $1;
        $currency = $2 if $2;
        %invoice = $client->create_invoice(price => $price, currency => $currency, params => {});
    } catch {
       our $error = $_;
    }
};

Then qr/they should recieve an invoice in response for "(.+)" "(.+)"/, sub{
    is(%invoice->{'price'}, $1);
    is(%invoice->{'currency'}, $2);
};

Then 'they can retrieve that invoice', sub{
    my $id = %invoice->{'id'};
    my %retinvoice = $client->get_invoice(id => $id, public => 1);
    is(%retinvoice->{'price'}, 101);
}
