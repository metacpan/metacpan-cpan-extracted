#!perl
use Test::More tests => 6;
use strict;

search_ok( 'strict', qr/^strict/m, 'Found strict' );
search_ok( 'av_clear', qr/^perlapi/m, 'Found av_clear' );

# echo -n 'Try searching for something that probably doesn'\''t exist' | md5
# dc098fbcf3f9bf8ba7898addba4591cb
search_ok( 'dc098fbcf3f9bf8ba7898addba4591cb', qr/^$/, "Couldn't find dc098fbcf3f9bf8ba7898addba4591cb" );


sub search_ok {
    my ( $phrase, $expected, $test_name ) = @_;

    my $stdout = `"$^X" "-Mblib" "bin/perldoc-search" "$phrase"`;

    is( $?, 0, "Didn't die" );
    like( $stdout, $expected, $test_name );

    return;
}
