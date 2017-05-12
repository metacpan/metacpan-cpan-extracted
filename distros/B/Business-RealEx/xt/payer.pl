#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Business::RealEx;
use Data::Dumper;

my $realex = Business::RealEx->new(
    merchantid => $ENV{REALEX_merchantid},
    secret => $ENV{REALEX_secret},
);

# my $data = $realex->new_payer(
#     orderid => abs($$) . "-" . time() . "-robin",
#     payerref => 'fayland',
#     firstname => 'Fayland',
#     surname => 'Lam',
#     company => '247moneybox'
# );
# print Dumper(\$data);

# $VAR1 = \{
#     'message' => 'Successful',
#     'merchantid' => '247moneyboxtest',
#     'pasref' => 'e73356c36d4148298dd12a567a53bcb8',
#     'batchid' => '',
#     'result' => '00',
#     'orderid' => '9631-1387639228-robin',
#     'timetaken' => '0',
#     'processingtimetaken' => '',
#     'md5hash' => '0b1ff215c0221915928b459ffa085b7b',
#     'sha1hash' => '107ab2c2727379592db5bc444dbd547325b1a93c',
#     'timestamp' => '20131221152033',
#     'authcode' => '',
#     'account' => 'internet'
#   };

# my $data = $realex->new_card(
#     orderid => abs($$) . "-" . time() . "-robin",
#     ref => 'fayland-card',
#     payerref => 'fayland',
#     number => '4988433008499991',
#     expdate => '0115',
#     chname => 'Fayland Lam',
#     type => 'visa',
# );
# print Dumper(\$data);

# my $data = $realex->update_card(
#     orderid => abs($$) . "-" . time() . "-robin",
#     ref => 'fayland-card',
#     payerref => 'fayland',
#     expdate => '0115',
#     chname => 'Fayland Lam',
#     type => 'visa',
# );
# print Dumper(\$data);

# my $data = $realex->delete_card(
#     ref => 'fayland-card',
#     payerref => 'fayland',
# );
# print Dumper(\$data);

# my $data = $realex->receipt_in(
#     orderid => abs($$) . "-" . time() . "-robin",
#     account => 'internet',
#     amount => '19999',
#     currency => 'EUR',
#     payerref => 'fayland',
#     paymentmethod => 'visa01', # card-ref?
# );
# print Dumper(\$data);

1;