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

like(
  exception {
    die(
      DNS::NIOS->new(
        username  => "bad_username",
        password  => "bad_password",
        wapi_addr => $nios->addr,
        scheme    => "http"
      )->get( path => "record:a" )->code
    )
  },
  qr/^401/,
  'Basic Auth',
);

my $n = DNS::NIOS->new(
  username  => "username",
  password  => "password",
  wapi_addr => $nios->addr,
  scheme    => "http"
);

my $x = $n->get( path => 'record:a' );
ok( $x->code == 400 );
ok( !$x->is_success );
ok( $x->content->{code} eq "Client.Ibap.Proto" );

$x = $n->get( path => 'record:a', params => { _paging => 1 } );
ok( $x->code == 400 );
ok( !$x->is_success );
ok( $x->content->{code} eq "Client.Ibap.Proto" );
ok( $x->content->{text} eq
    "_return_as_object needs to be enabled for paging requests." );

$x = $n->get(
  path   => 'record:a',
  params => {
    _paging           => 1,
    _max_results      => 1,
    _return_as_object => 1
  }
);
ok( $x->code == 200 );
ok( $x->is_success );

foreach ( @{ $x->content->{result} } ) {
  my $x = $n->delete( path => $_->{_ref} );
}

$x = $n->create(
  path    => "record:a",
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
$x = $n->get(
  path   => "record:a",
  params => {
    _paging           => 1,
    _max_results      => 1,
    _return_as_object => 1
  }
);
ok( $ref eq $x->content->{result}[0]->{_ref} );

$x = $n->update(
  path    => $ref,
  payload => {
    name => "rhds-1.ext.home"
  }
);
ok( $x->code == 200 );

$x = $n->get(
  path   => "record:a",
  params => {
    _paging           => 1,
    _max_results      => 1,
    _return_as_object => 1
  }
);
ok( "rhds-1.ext.home" eq $x->content->{result}[0]->{name} );

## All done
done_testing();
