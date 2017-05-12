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
use HTTP::Tiny;

my $test_url = "http://cpanmetadb.plackperl.org/v1.0/package/File::Marker";

plan skip_all => "Can't reach CPAN MetaDB"
  unless HTTP::Tiny->new->get($test_url)->{success};

require_ok("CPAN::Common::Index::MetaDB");

subtest "constructor tests" => sub {
    # no arguments, all defaults
    new_ok(
        'CPAN::Common::Index::MetaDB' => [],
        "new with no args"
    );

    # uri specified
    new_ok(
        'CPAN::Common::Index::MetaDB' => [ { uri => "http://example.com" } ],
        "new with cache"
    );

};

subtest 'find package' => sub {
    my $index = new_ok("CPAN::Common::Index::MetaDB");

    my $got = $index->search_packages( { package => 'Moose' } );
    ok( $got,                "found package" );
    ok( $got->{version} > 2, "has a version" );
    like(
        $got->{uri},
        qr{^cpan:///distfile/\w+/Moose-\d+\.\d+\.tar.gz$},
        "uri format looks OK"
    );

};

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
