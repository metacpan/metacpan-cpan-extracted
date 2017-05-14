#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use File::Temp;

BEGIN { unshift( @INC, './lib' ) }

BEGIN {
    use Test::Most;
    use_ok('Bio::VertRes::Config::Pipelines::Store');
}

my $destination_directory_obj = File::Temp->newdir( CLEANUP => 1 );
my $destination_directory = $destination_directory_obj->dirname();

ok(
    (
        my $obj = Bio::VertRes::Config::Pipelines::Store->new(
            database    => 'my_database',
            database_connect_file => 't/data/database_connection_details',
            root_base   => '/path/to/root',
            log_base    => '/path/to/log',
            config_base => $destination_directory
        )
    ),
    'initialise store config'
);
is($obj->toplevel_action, '__VRTrack_Storing__');
is_deeply(
    $obj->to_hash,
    {
        'db' => {
            'database' => 'my_database',
            'password' => 'some_password',
            'user'     => 'some_user',
            'port'     => 1234,
            'host'     => 'some_hostname'
        },
        'data' => {
            'db' => {
                'database' => 'my_database',
                'password' => 'some_password',
                'user'     => 'some_user',
                'port'     => 1234,
                'host'     => 'some_hostname'
            },
            'dont_wait' => 0
        },
        'vrtrack_processed_flags' => {
            'qc'     => 1,
            'stored' => 0
        },
        'root'   => '/path/to/root/my_database/seq-pipelines',
        'log'    => '/path/to/log/my_database/stored_logfile.log',
        'limit'  => 100,
        'module' => 'VertRes::Pipelines::StoreLane',
        'prefix' => '_'
    },
    'output hash constructed correctly'
);

is(
    $obj->config,
    $destination_directory . '/my_database/stored/stored_global.conf',
    'config file in expected format'
);
ok( $obj->create_config_file, 'Can run the create config file method' );
ok( ( -e $obj->config ), 'Config file exists' );

done_testing();
