use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::FailWarnings;
use Test::Deep '!blessed';
use Test::Fatal;

use Cwd qw/getcwd/;
use File::Spec;
use File::Temp ();

use lib 't/lib';
use CommonTests;

my $cwd          = getcwd;
my $localgz      = File::Spec->catfile(qw/t CUSTOM mypackages.gz/);
my $local        = File::Spec->catfile(qw/t CUSTOM uncompressed/);
my $packages     = "mypackages";
my $uncompressed = "uncompressed";

sub new_local_index {
    my $cache = File::Temp->newdir;
    my $index = new_ok(
        'CPAN::Common::Index::LocalPackage' => [ { cache => $cache, source => $localgz } ],
        "new with cache and local gz"
    );
    is $index->cache, $cache, "the cache constructor attribute is respected";
    $index;
}

sub new_uncompressed_local_index {
    my $cache = File::Temp->newdir;
    my $index = new_ok(
        'CPAN::Common::Index::LocalPackage' => [ { cache => $cache, source => $local } ],
        "new with cache and local uncompressed"
    );
    is $index->cache, $cache, "the cache constructor attribute is respected";
    $index;
}

require_ok("CPAN::Common::Index::LocalPackage");

subtest "constructor tests" => sub {
    # no arguments, all defaults
    like(
        exception { CPAN::Common::Index::LocalPackage->new() },
        qr/'source' parameter must be provided/,
        "new with no args dies because source is required"
    );

    # missing file
    like(
        exception {
            CPAN::Common::Index::LocalPackage->new( { source => 'LDJFLKDJLJDLKD' } );
        },
        qr/index file .* does not exist/,
        "new with invalid source dies"
    );

    # source specified
    new_ok(
        'CPAN::Common::Index::LocalPackage' => [ { source => $localgz } ],
        "new with source"
    );

    # both specified
    new_local_index;

    # uncompressed variant
    new_uncompressed_local_index;
};

subtest 'refresh and unpack index files' => sub {
    plan skip_all => "IO::Uncompress::Gunzip is not available"
      unless $CPAN::Common::Index::Mirror::HAS_IO_UNCOMPRESS_GUNZIP;
    my $index = new_local_index;

    ok( !-e File::Spec->catfile( $index->cache, $packages ), "$packages not in cache" );

    ok( $index->refresh_index, "refreshed index" );

    ok( -e File::Spec->catfile( $index->cache, $packages ), "$packages in cache" );
};

subtest 'refresh and unpack uncompressed index files' => sub {
    my $index = new_uncompressed_local_index;

    ok( !-e File::Spec->catfile( $index->cache, $uncompressed ),
        "$uncompressed not in cache" );

    ok( $index->refresh_index, "refreshed index" );

    ok( -e File::Spec->catfile( $index->cache, $uncompressed ),
        "$uncompressed in cache" );
};

# XXX test that files in cache aren't overwritten?

sub common_tests {
    my ( $index_generater, $note );
    if ($CPAN::Common::Index::Mirror::HAS_IO_UNCOMPRESS_GUNZIP) {
        $index_generater = \&new_local_index;
        $note            = "with IO::Uncompress::Gunzip";
    }
    else {
        $index_generater = \&new_uncompressed_local_index;
        $note            = "without IO::Uncompress::Gunzip";
    }

    subtest "check index age $note" => sub {
        my $index   = $index_generater->();
        my $package = $index->cached_package;
        ok( -f $package, "got the package file" );
        my $expected_age = ( stat($package) )[9];
        is( $index->index_age, $expected_age, "index_age() is correct" );
    };

    subtest "find package $note" => sub {
        my $index = $index_generater->();
        test_find_package($index);
    };

    subtest "search package $note" => sub {
        my $index = $index_generater->();
        test_search_package($index);
    };
}

common_tests();
if ($CPAN::Common::Index::Mirror::HAS_IO_UNCOMPRESS_GUNZIP) {
    local $CPAN::Common::Index::Mirror::HAS_IO_UNCOMPRESS_GUNZIP = 0;
    common_tests();
}

done_testing;
#
# This file is part of CPAN-Common-Index
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
# vim: ts=4 sts=4 sw=4 et:
