#!/usr/bin/env perl
use lib 'lib';
use CPAN::Source;
use Test::More;

my $source = CPAN::Source->new( 
    mirror => 'http://cpan.nctu.edu.tw',
    cache_path => '.cache' , 
    cache_expiry => '14 days' );

my $pkg_data;
ok( $source );
ok( $pkg_data = $source->prepare_package_data );

my $dist = $source->dist('Moose');

ok( $dist );

my $cnt = 0;
while( my ($k,$v) = each %{ $source->dists } ) { 
    last if ++$cnt > 1000;
    ok( $k );
    ok( $v );
    ok( $v->name );
    ok( $v->version );
    ok( $v->cpanid );
}

done_testing();
