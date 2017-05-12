use strict;
use warnings;
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::CheckManifest; };

if ( $@ ) {
   my $msg = 'Test::CheckManifest required to check manifest';
   plan( skip_all => $msg );
}

Test::CheckManifest::ok_manifest({filter=>[qr/\/cover_db/,qr/\/\.git/,qr/\/\.dotest/,qr/\.bak$/,qr/\.old$/,qr/t\/dbfile$/,qr/\.tar\.gz$/,qr/Makefile(?:\.PL)$/]});

