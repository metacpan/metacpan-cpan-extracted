#!/usr/bin/perl

use strict;
use warnings;

use CPANfile::Parse::PPI;
use File::Basename;
use File::Spec::Functions;
use IO::File;
use Test::More;
use JSON::PP qw(decode_json);

my $base_dir  = dirname __FILE__;
my $json_file = catfile( $base_dir, 'tests.json' );
my $json      = join '', IO::File->new($json_file, 'r')->getlines;
my $test_data = decode_json( $json );

for my $test ( @{ $test_data || [] } ) {
    my $cpanfile = CPANfile::Parse::PPI->new(
        catfile( $base_dir, 'data', $test->{file} )
    );

    my $modules = $cpanfile->modules;
    is_deeply $modules, $test->{results};
}

done_testing();
