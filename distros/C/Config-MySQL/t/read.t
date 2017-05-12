#!perl

use strict;
use warnings;

use Test::More 'no_plan';    # last test to print

use_ok('Config::MySQL::Reader');

my $hashref = Config::MySQL::Reader->read_file('t/my.cnf');
isa_ok( $hashref, 'HASH', 'return of Config::MySQL::Reader->read_file' );

my $expected = {
    'mysqld' => {
        'datadir'         => '/var/lib/mysql',
        'skip-locking'    => undef,
        'key_buffer_size' => '32M',
    },
    'mysqldump' => {
        'quick'              => undef,
        'max_allowed_packet' => '16M',
    },
    '_' => {
        '!include'    => [ 't/my.cnf', 't/your.cnf' ],
        '!includedir' => ['t/'],
    },
};

is_deeply( $hashref, $expected, 'Config structure matches expected' );

