use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::FailWarnings;
use Test::Deep '!blessed';
use Test::Fatal;

use Cwd qw/getcwd/;
use File::Temp;
use File::Spec::Functions qw/catfile/;

use lib 't/lib';
use CommonTests;

my $cwd         = getcwd;
my $test_mirror = "file:///$cwd/t/CPAN";
my $mailrc      = "01mailrc.txt";
my $packages    = "02packages.details.txt";

sub new_mirror_index {
    my $cache = File::Temp->newdir;
    my $index = new_ok(
        'CPAN::Common::Index::Mirror' => [ { cache => $cache, mirror => $test_mirror } ],
        "new with cache and mirror"
    );
    is $index->cache, $cache, "the cache constructor attribute is respected";
    $index;
}

require_ok("CPAN::Common::Index::Mirror");

subtest "constructor tests" => sub {
    # no arguments, all defaults
    new_ok(
        'CPAN::Common::Index::Mirror' => [],
        "new with no args"
    );

    # cache specified
    new_ok(
        'CPAN::Common::Index::Mirror' => [ { cache => File::Temp->newdir } ],
        "new with cache"
    );

    # mirror specified
    new_ok(
        'CPAN::Common::Index::Mirror' => [ { mirror => $test_mirror } ],
        "new with mirror"
    );

    # both specified
    new_mirror_index;

};

subtest 'refresh and unpack index files' => sub {
    my $index = new_mirror_index;

    my @file = ( $mailrc, $packages );
    push @file, "$mailrc.gz", "$packages.gz"
      if $CPAN::Common::Index::Mirror::HAS_IO_UNCOMPRESS_GUNZIP;

    for my $file (@file) {
        ok( !-e catfile( $index->cache, $file ), "$file not there" );
    }
    ok( $index->refresh_index, "refreshed index" );
    for my $file (@file) {
        ok( -e catfile( $index->cache, $file ), "$file is there" );
    }
};

# XXX test that files in cache aren't overwritten?

sub common_tests {
    my $note =
      ( $CPAN::Common::Index::Mirror::HAS_IO_UNCOMPRESS_GUNZIP ? "with" : "without" )
      . " IO::Uncompress::Gunzip";

    subtest "check index age $note" => sub {
        my $index   = new_mirror_index;
        my $package = $index->cached_package;
        ok( -f $package, "got the package file" );
        my $expected_age = ( stat($package) )[9];
        is( $index->index_age, $expected_age, "index_age() is correct" );
    };

    subtest "find package $note" => sub {
        my $index = new_mirror_index;
        test_find_package($index);
    };

    subtest "search package $note" => sub {
        my $index = new_mirror_index;
        test_search_package($index);
    };

    subtest "find author $note" => sub {
        my $index = new_mirror_index;
        test_find_author($index);
    };

    subtest "search author $note" => sub {
        my $index = new_mirror_index;
        test_search_author($index);
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
