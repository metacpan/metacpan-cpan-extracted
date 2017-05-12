#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use lib 't/lib';

use Catalyst::Test qw(Catalyst::Model::KiokuDB::Test);

my $log = Catalyst::Model::KiokuDB::Test->log;

$log->clear;

{
    local $Catalyst::Model::KiokuDB::Test::Controller::Root::ran = 0;

    request('/insert');

    like $log->str, qr/Loaded 2 objects/, "loaded count";
    unlike $log->str, qr/leaked/, "no leaks";

    $log->clear;

    is( $Catalyst::Model::KiokuDB::Test::Controller::Root::ran, 1, "tests ran successfully" );
}

{
    local $Catalyst::Model::KiokuDB::Test::Controller::Root::ran = 0;
    request('/fetch');

    like $log->str, qr/Loaded 1 object/, "loaded count";
    unlike $log->str, qr/leaked/, "no leaks";

    $log->clear;

    is( $Catalyst::Model::KiokuDB::Test::Controller::Root::ran, 1, "tests ran successfully" );
}

{
    local $Catalyst::Model::KiokuDB::Test::Controller::Root::ran = 0;
    request('/leak');

    like $log->str, qr/Loaded 1 object/, "loaded count";
    like $log->str, qr/leaked/, "no leaks";

    $log->clear;

    is( $Catalyst::Model::KiokuDB::Test::Controller::Root::ran, 1, "tests ran successfully" );
}

{
    local $Catalyst::Model::KiokuDB::Test::Controller::Root::ran = 0;

    request('/fresh');

    like $log->str, qr/Loaded 1 object/, "loaded count";
    unlike $log->str, qr/leaked/, "no leaks";

    $log->clear;

    is( $Catalyst::Model::KiokuDB::Test::Controller::Root::ran, 1, "tests ran successfully" );
}

{
    local $Catalyst::Model::KiokuDB::Test::Controller::Root::ran = 0;

    request('/login');

    like $log->str, qr/Loaded 1 object/, "loaded count";
    unlike $log->str, qr/leaked/, "no leaks";

    $log->clear;

    is( $Catalyst::Model::KiokuDB::Test::Controller::Root::ran, 1, "tests ran successfully" );
}


{
    local $Catalyst::Model::KiokuDB::Test::Controller::Root::ran = 0;

    request('/login_username');

    like $log->str, qr/Loaded 1 object/, "loaded count";
    unlike $log->str, qr/leaked/, "no leaks";

    $log->clear;

    is( $Catalyst::Model::KiokuDB::Test::Controller::Root::ran, 1, "tests ran successfully" );
}
