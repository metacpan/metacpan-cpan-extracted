#!perl -wT
# $Id: /local/DBIx-Class-InflateColumn-Currency/t/manifest.t 1294 2008-03-08T00:13:34.920932Z claco  $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use DBIC::Test;

    plan skip_all => 'set TEST_AUTHOR to enable this test' unless $ENV{TEST_AUTHOR};

    eval 'use Test::CheckManifest 0.09';
    if($@) {
        plan skip_all => 'Test::CheckManifest 0.09 not installed';
    };
};

ok_manifest({
    exclude => ['/t/var', '/cover_db'],
    filter  => [qr/\.svn/, qr/cover/, qr/Build(.(PL|bat))?/, qr/_build/, qr/\.tmproj/],
    bool    => 'or'
});
