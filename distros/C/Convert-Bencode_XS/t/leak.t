#!/sw/bin/perl -w
#
# Blatantly based on the YAML::Syck leak testcases written by Clayton 
# O'Neill and Andrew Danforth

use strict;
use Convert::Bencode_XS qw(bencode bdecode);
use Test::More tests => 6;

SKIP: {
    eval { require Devel::Leak }
      or skip( "Devel::Leak not installed", 6 );

    my $struct = { foo => 'bar', nums => [ 1,2,3 ], this => 'that' };
    my $encoded = bencode($struct);

    my $handle;
    my $diff;

    bencode($struct);

    my $before = Devel::Leak::NoteSV($handle);
    bencode($struct) foreach( 1 .. 100);
    $diff = Devel::Leak::NoteSV($handle) - $before;
    is( $diff, 0, "No leaks - bencode" );

    # Run one decode to create all the expected SVs
    bdecode($encoded);

    $before = Devel::Leak::NoteSV($handle);
    bdecode($encoded) foreach ( 1 .. 100 );
    $diff = Devel::Leak::NoteSV($handle) - $before;
    is( $diff, 0, "No leaks - bdecode" );

    $encoded = 'd3:food4:this4:thate3:bar';
    eval { bdecode($encoded) };
    ok ( $@, "bdecode failed (expected)" );
    eval { bdecode($encoded) };
    $before = Devel::Leak::NoteSV($handle);
    eval { bdecode($encoded) };
    $diff = Devel::Leak::NoteSV($handle) - $before;
    is( $diff, 0, "No leaks - bdecode incomplete dictionary" );

    $encoded = 'l3:foo3:bar';
    eval { bdecode($encoded) };
    ok ( $@, "bdecode failed (expected)" );
    eval { bdecode($encoded) };
    $before = Devel::Leak::NoteSV($handle);
    eval { bdecode($encoded) };
    $diff = Devel::Leak::NoteSV($handle) - $before;
    is( $diff, 0, "No leaks - bdecode incomplete list" );
}
