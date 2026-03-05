#!/usr/bin/env perl

use strict;
use warnings;
use Amazon::CreatorsAPI;
use Data::Dumper;

# Locale reference of US
# https://affiliate-program.amazon.com/creatorsapi/docs/en-us/locale-reference/united-states

my $api = Amazon::CreatorsAPI->new(
    "{credential_id}",
    "{credential_secret}",
    "{credential_version}",
    {
        partner_tag => "{partner_tag}",
    },
);

my $res = $api->get_browse_nodes({
    browseNodeIds => ['6134005011'],
});

print Dumper($res);
