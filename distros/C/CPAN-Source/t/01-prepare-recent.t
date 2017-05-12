#!/usr/bin/env perl
use lib 'lib';
use Test::More tests => 6;
use_ok( 'CPAN::Source' );

my $source = CPAN::Source->new( 
    mirror => 'http://cpan.nctu.edu.tw',
    cache_path => '.cache' , 
    cache_expiry => '14 days' );

ok( $source );
ok( $source->fetch_recent('1d') );
ok( $source->fetch_recent('1M') );
ok( $source->fetch_recent('1h') );
ok( $source->recent('1h') );
