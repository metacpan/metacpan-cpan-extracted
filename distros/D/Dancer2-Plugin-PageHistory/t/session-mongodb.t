use strict;
use warnings;

use Test::Fatal;
use Test::More;
use lib 't/lib';

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'mongodb';

    eval 'use MongoDB';
    plan skip_all => "MongoDB required to run these tests" if $@;

    eval 'use Dancer2::Session::MongoDB';
    plan skip_all => "Dancer2::Session::MongoDB required to run these tests" if $@;
}

my $db;
eval {
    my $db_name = 'test_dancer2_plugin_page_history';
    my $client = MongoDB::MongoClient->new;
    $db = $client->get_database($db_name);
    $db->drop;
};
plan skip_all => "No MongoDB on localhost" if $@;

# make sure we clean up from prior runs

diag "MongoDB $MongoDB::VERSION Dancer2::Session::MongoDB $Dancer2::Session::MongoDB::VERSION";

use Tests;

Tests::run_tests();

$db->drop;

done_testing;
