#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Calendar::Japanese::Acme::Syukujitsu' ) || print "Bail out!\n";

    my $syukujitsu = Calendar::Japanese::Acme::Syukujitsu->new(cachefile => 't/files/syukujitsu.csv');
    is( $syukujitsu->is_syukujitsu(year => '2016', month => '4', day => '1'), undef);
}

diag( "Testing Calendar::Japanese::Acme::Syukujitsu $Calendar::Japanese::Acme::Syukujitsu::VERSION, Perl $], $^X" );
