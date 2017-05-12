#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;

use Autocache::Request;
use Autocache::Record;
use Autocache::Strategy::Eviction::FIFO;
use Autocache::Strategy::Store::Memory;

use Devel::Size qw( total_size );

my %requests;
my %records;

foreach my $key ( 'a'..'e' )
{
    my $req = Autocache::Request->new(
        name => 'name',
        normaliser => sub { $_[0] },
        generator => sub { 'data' },
        args => [ $key ],
        context => 'S',
    );
    $requests{$key} = $req;
    $records{$key} = Autocache::Record->new( key => $req->key, value => 'data' );
}

my $record_size = total_size( $records{a} );

my $max_size = $record_size * 3;

my $store = Autocache::Strategy::Eviction::FIFO->new(
    max_size => $max_size,
    base_strategy => Autocache::Strategy::Store::Memory->new, );

my $key;

$key = 'a';

$store->set( $requests{$key}, $records{$key} );

isnt( $store->get( $requests{a} ), undef, 'record not evicted' );

$key = 'b';

$store->set( $requests{$key}, $records{$key} );

isnt( $store->get( $requests{a} ), undef, 'record not evicted' );
isnt( $store->get( $requests{b} ), undef, 'record not evicted' );

$key = 'c';

$store->set( $requests{$key}, $records{$key} );

isnt( $store->get( $requests{a} ), undef, 'record not evicted' );
isnt( $store->get( $requests{b} ), undef, 'record not evicted' );
isnt( $store->get( $requests{c} ), undef, 'record not evicted' );

$key = 'a';

$store->get( $requests{$key} );

$key = 'd';

$store->set( $requests{$key}, $records{$key} );

is( $store->get( $requests{a} ), undef, 'record has been evicted' );
isnt( $store->get( $requests{b} ), undef, 'record not evicted' );
isnt( $store->get( $requests{c} ), undef, 'record not evicted' );
isnt( $store->get( $requests{d} ), undef, 'record not evicted' );

exit;
