#! /usr/bin/env perl

use Test2::V0;

use JSON::PP;
use File::Slurper;
use Test::TempDir::Tiny;
use Config::XrmDatabase;

my $config = 't/configs/config001';

my $db  = Config::XrmDatabase->read_file( $config );
my $exp = $db->TO_HASH;

my $got;

in_tempdir "compare" => sub {
    $db->write_file( 'config' );
    $got = Config::XrmDatabase->read_file( 'config' )->TO_HASH;
};

is( $got, $exp );

done_testing;
