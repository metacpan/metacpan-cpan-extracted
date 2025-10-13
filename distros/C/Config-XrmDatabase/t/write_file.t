#! /usr/bin/env perl

use v5.26;
use Test2::V0;

use Test::TempDir::Tiny;
use Config::XrmDatabase;

my $config = 't/configs/config001';

open my $fh, '<', $config
  or die( "unable to open test configuration '$config'" );

my $db = Config::XrmDatabase->new;

## no critic (AmbiguousName)
while ( my $record = $fh->getline ) {
    chomp $record;
    my ( $key, $value ) = split( /\s*:\s*/, $record, 2 );
    $db->insert( $key, $value );
}

my $exp = $db->TO_HASH;

my $got;

in_tempdir 'compare' => sub {
    $db->write_file( 'config' );
    $got = Config::XrmDatabase->read_file( 'config' )->TO_HASH;
};

is( $got, $exp );

done_testing;
