#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

my $module = 'App::VTide::Config';
use_ok( $module );

new();
get();
changed();

done_testing();

sub new {
    my $conf = $module->new(
        global_config => 't/fake-global.yml',
        local_config  => 't/fake-local.yml',
    );
    ok $conf, 'Load with two non-existant files';
    is_deeply $conf->get, {}, 'Get data from non-existant files';

    $conf = $module->new(
        global_config => 't/global.yml',
        local_config  => 't/fake-local.yml',
    );
    ok $conf, 'Load with local non-existant file';
    is_deeply $conf->get, {count => 6}, 'Get data from global';

    $conf = $module->new(
        global_config => 't/fake-global.yml',
        local_config  => 't/local.yml',
    );
    ok $conf, 'Load with global non-existant file';
    is_deeply $conf->get, {name => 'local', count => 4}, 'Get data from local';
}

sub get {
    my $conf = $module->new(
        global_config => 't/global.yml',
        local_config  => 't/local.yml',
    );
    ok $conf, 'Create config successfully';
    my $data = $conf->get();
    ok $data, 'Get some data';
    is_deeply $conf->get, $data, 'Second call gives same data';
}

sub changed {
    my $conf = $module->new(
        global_config => 't/global.yml',
        local_config  => 't/local.yml',
    );
    ok $conf->changed, 'First call shows data has "changed"';
    $conf->get;
    ok ! $conf->changed, 'Second call shows data has not "changed"';
    $conf->local_time( $conf->local_time - 60 );
    ok $conf->changed, 'Data has "changed" when dates don\'t match';
}
