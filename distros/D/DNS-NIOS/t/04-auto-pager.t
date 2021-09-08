#!perl
#
# This file is part of DNS-NIOS
#
# This software is Copyright (c) 2021 by Christian Segundo.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#

use strictures 2;

use DNS::NIOS;

use Test::Fatal;
use Test::More;

use lib 't/tlib';
use Test::SpawnNIOS;

if ( $] < 5.020 ) {
  plan skip_all => 'wrong version';
}

my $nios = Test::SpawnNIOS->nios();
END { $nios->shitdown() if $nios }

my $n = DNS::NIOS->new(
  username  => "username",
  password  => "password",
  wapi_addr => $nios->addr,
  scheme    => "http",
  traits    => [ 'DNS::NIOS::Traits::ApiMethods', 'DNS::NIOS::Traits::AutoPager' ]
);

my $x = $n->list_a_records();
ok( ref($x) eq 'ARRAY' );
ok( ref( @{$x}[0] ) eq 'DNS::NIOS::Response' );
my $response_length = scalar( @{$x} );

$x = $n->list_a_records( params => { _max_results => 200 } );
ok( ref($x) eq 'ARRAY' );
ok( scalar( @{$x} ) != $response_length );
ok( scalar( @{$x} ) == 200 );

done_testing();
