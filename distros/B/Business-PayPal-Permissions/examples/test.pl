#!/usr/bin/perl

use strict;
use warnings;
use Business::PayPal::Permissions;
use Data::Dumper;

my $API_username  = 'faysel_1358672184_biz_api1.gmail.com';
my $API_password  = '1358672205';
my $API_signature = 'AQU0e5vuZCvSg-XJploSa.sGUDlpAmM0hon28S2lUqJNkYEJhxkRFwjm';

my $ppp = Business::PayPal::Permissions->new(
    username  => $API_username,
    password  => $API_password,
    signature => $API_signature,
    app_id    => 'APP-80W284485P519543T',
    sandbox   => 1,
);

my $data = $ppp->RequestPermissions(
    [
        'TRANSACTION_SEARCH', 'TRANSACTION_DETAILS',
        'ACCESS_BASIC_PERSONAL_DATA'
    ],
    'http://localhost:5000/cgi-bin/test.pl'
);
print Dumper( \$data );

1;
