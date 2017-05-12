#!/usr/bin/env perl
use lib 'lib';
use CPAN::Source;
use Test::More tests => 8;

my $source = CPAN::Source->new( 
    mirror => 'http://cpan.nctu.edu.tw',
    cache_path => '.cache' , 
    cache_expiry => '14 days' );

{
    my $path = 'J/JW/JWACH/Apache-FastForward-1.1.tar.gz';
    my $dist = CPAN::DistnameInfo->new($path);
    my $d = $source->new_dist($dist);
    ok $d;
    ok $d->name;
    ok $d->version_name;
}

ok( $source->prepare_package_data );

my $dist = $source->dist('Moose');
ok( $dist );

my $pkg = $source->package( 'Moose' );
ok( $pkg );

my $pm_content = $pkg->fetch_pm;
ok( $pm_content );
like( $pm_content , qr/=head1/s );
