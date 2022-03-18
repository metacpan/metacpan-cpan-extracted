#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::RequiresInternet;

use API::MailboxOrg;

my $api = API::MailboxOrg->new(
    user     => 'dummy',
    password => 'dummy',
);

my $result = $api->hello->world;
is $result, "Hello World!";

done_testing;
