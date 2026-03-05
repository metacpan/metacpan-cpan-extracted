#!/usr/bin/env perl

use strict;
use warnings;
use Amazon::CreatorsAPI;
use Data::Dumper;

# Locale Reference of Japan
# https://affiliate-program.amazon.com/creatorsapi/docs/en-us/locale-reference/japan

my $api = Amazon::CreatorsAPI->new(
    "{credential_id}",
    "{credential_secret}",
    "{credential_version}",
    {
        partner_tag => "{partner_tag}",
        marketplace => 'www.amazon.co.jp',
    },
);

my $res = $api->search_items({
    keywords => "{search_keyword}",
    resources => [
        'itemInfo.title',
    ],
});

print Dumper($res);
