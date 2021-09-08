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
  traits    => ['DNS::NIOS::Traits::ApiMethods']
);

my $x = $n->create_a_record(
  payload => {
    name     => "rhds.ext.home",
    ipv4addr => "10.0.0.1",
    extattrs => {
      "Tenant ID"       => { value => "home" },
      "CMP Type"        => { value => "OpenStack" },
      "Cloud API Owned" => { value => "True" }
    }
  }
);
ok( $x->code == 201 );
my $ref = $x->content;

$x = $n->list_a_records(
  params => {
    _paging           => 1,
    _max_results      => 1,
    _return_as_object => 1
  }
);
ok( $ref eq $x->content->{result}[0]->{_ref} );

done_testing();
