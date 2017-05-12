#!/usr/bin/perl

use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name => 'DBGp::Client::AnyEvent',
    license     => 'perl',
    requires    => {
        'perl'                  => '5.10.0',
        'AnyEvent'              => '1.0031',
        'DBGp::Client'          => '0.09',
    },
    configure_requires => {
        'Module::Build' => 0.42,
    },
    test_requires => {
        'Test::DBGp'                => '0.05',
    },
    meta_merge  => {
        resources   => {
            license     => [ 'http://dev.perl.org/licenses/' ],
            bugtracker  => 'https://github.com/mbarbon/dbgp-client-anyevent/issues',
            repository  => 'https://github.com/mbarbon/dbgp-client-anyevent.git',
        },
    },
);
$build->create_build_script;
