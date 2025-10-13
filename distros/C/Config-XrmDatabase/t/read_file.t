#! /usr/bin/env perl

use v5.26;
use Test2::V0;

skip_all( 'Not running under AUTOMATED_TESTING to save the planet.' ) if $ENV{AUTOMATED_TESTING};

use JSON::PP;
use File::Slurper;
use Config::XrmDatabase;
use Data::Dump 'pp';
use Test::TempDir::Tiny;

use Archive::Tar;
my $tar = Archive::Tar->new( 't/configs.tgz' );

for my $file ( $tar->list_files ) {

    next if $file !~ /config/ || $file =~ /[.]json$/;

    my $meta = "${file}.json";

    in_tempdir '$file' => sub {

        $tar->extract( $file );
        $tar->extract( $meta );

        my $db       = Config::XrmDatabase->read_file( $file );
        my $expected = decode_json( File::Slurper::read_text( $meta ) );
        my $got      = $db->query( $expected->{class}, $expected->{name} );

        is( $got, $expected->{res}{value}, "$file: @{[$expected->{match}]}" )
          or do {
            note 'expected: ', pp( $expected );
            note 'got: ',      pp( $got );
          };
    };
}

done_testing;
