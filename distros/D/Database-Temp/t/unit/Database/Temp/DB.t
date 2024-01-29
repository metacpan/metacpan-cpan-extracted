#!perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
## no critic (ControlStructures::ProhibitPostfixControls)

use strict;
use warnings;

use English qw( -no_match_vars );    # Avoids regex performance
local $OUTPUT_AUTOFLUSH = 1;

use utf8;

use Test2::V0 -target => 'Database::Temp::DB';
use Test2::Tools::Spec;
set_encoding('utf8');

use Database::Temp;

skip_all('Skip testing with SQLite; Not available')
  if ( !Database::Temp->is_available( driver => 'SQLite' ) );

describe 'method `connection_info`' => sub {
    my ( $driver, $name, $dsn, $username, $password, $attr, @expected_connection_info );
    case 'SQLite driver' => sub {
        use File::Temp qw( tmpnam );
        my $tmp_filepath = tmpnam();
        $driver                   = 'SQLite';
        $name                     = $tmp_filepath;
        $dsn                      = "dbi:$driver:uri=file:$name";
        $username                 = 'dum';
        $password                 = 'my';
        $attr                     = {};
        @expected_connection_info = ( $dsn, 'dum', 'my', {}, );
    };
    case 'SQLite driver with undef username and password' => sub {
        use File::Temp qw( tmpnam );
        my $tmp_filepath = tmpnam();
        $driver                   = 'SQLite';
        $name                     = $tmp_filepath;
        $dsn                      = "dbi:$driver:uri=file:$name";
        $username                 = undef;
        $password                 = undef;
        $attr                     = {};
        @expected_connection_info = ( $dsn, $username, $password, {}, );
    };
    tests 'it works' => sub {
        my @got_connection_info = $CLASS->new(
            driver   => $driver,
            name     => $name,
            cleanup  => 1,
            _cleanup => sub { },
            _start   => sub { },
            init     => sub { },
            deinit   => sub { },
            dsn      => $dsn,
            username => $username,
            password => $password,
            attr     => $attr,
            info     => {},
        )->connection_info;
        is( $got_connection_info[0], $expected_connection_info[0], 'Expected connection info (dsn) returned' );
        is( $got_connection_info[1], $expected_connection_info[1], 'Expected connection info (username) returned' );
        is( $got_connection_info[2], $expected_connection_info[2], 'Expected connection info (password) returned' );
        is( $got_connection_info[3], $expected_connection_info[3], 'Expected connection info (args) returned' );
    };
};

describe "class `$CLASS`" => sub {

    tests 'it can be instantiated' => sub {
        can_ok( $CLASS, 'new' );
    };
};

done_testing;
