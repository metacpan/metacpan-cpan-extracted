#!/usr/bin/env perl
use lib 'lib';
use Test::More;
use_ok( 'CPAN::Source' );

my $source = CPAN::Source->new( 
    mirror => 'http://cpan.nctu.edu.tw',
    cache_path => '.cache' , 
    cache_expiry => '14 days' );

ok( $source );
ok( $source->prepare_authors );

my $authors;
ok( $authors = $source->authors );

my ( $pause_id , $meta ) = each %$authors;

ok( $pause_id );
ok( $meta );

ok( $meta->{$_} ) for qw(email homepage has_cpandir fullname type);

my $gugod = $source->author( 'GUGOD' );
ok( $gugod );


done_testing;
