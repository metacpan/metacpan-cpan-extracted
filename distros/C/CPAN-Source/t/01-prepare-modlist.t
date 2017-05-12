#!/usr/bin/env perl
use lib 'lib';
use Test::More tests => 3;
use_ok( 'CPAN::Source' );

my $source = CPAN::Source->new( 
    mirror => 'http://cpan.nctu.edu.tw',
    cache_path => '.cache' , 
    cache_expiry => '14 days' );

my $pkg_data;
ok( $source );
ok( $source->prepare_modlist );
