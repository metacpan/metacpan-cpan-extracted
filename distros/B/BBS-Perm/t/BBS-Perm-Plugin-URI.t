#!/usr/bin/perl
use strict;
use warnings;
use Encode;

use Test::More tests => 7;

BEGIN { use_ok('BBS::Perm::Plugin::URI'); }
my $uri = BBS::Perm::Plugin::URI->new;

isa_ok( $uri, 'BBS::Perm::Plugin::URI', '$uri' );

$uri->pop;
is( $uri->size, 0, 'pop 0 size' );

my @uri = ( 'http://www.newsmth.net', 'http://cpan.org' );
$uri->push($_) for @uri;
is( $uri->size, 2, 'push' );
is_deeply( $uri->uri, [@uri], 'uri' );

$uri->pop;
is( $uri->size, 1, 'pop' );
$uri->pop;
is( $uri->size, 0, 'pop' );
