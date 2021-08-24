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

use JSON qw(from_json);
use DNS::NIOS;
use Test::Fatal;
use Test::More;
use Data::Dumper;

use lib 't/tlib';
use Test::SpawnNIOS;

my $nios = Test::SpawnNIOS->nios();
END { $nios->shitdown() if $nios }

like(
    exception { my $n = DNS::NIOS->new() },
    qr/\w+ is required!/,
    'Missing required connection parameters',
);

like(
    exception {
        my $n = DNS::NIOS->new(
            username  => "x",
            password  => "x",
            wapi_addr => "x",
            scheme    => "x"
        )
    },
    qr/^scheme not supported: x/,
    'Not supported scheme',
);

like(
    exception {
        die(
            DNS::NIOS->new(
                username  => "bad_username",
                password  => "bad_password",
                wapi_addr => $nios->addr,
                scheme    => "http"
            )->get( path => "record:a" )->{_rc}
        )
    },
    qr/^401/,
    'Basic Auth',
);

my $defaults = DNS::NIOS->new(
    username  => "username",
    password  => "password",
    wapi_addr => $nios->addr
);
ok( $defaults->scheme eq 'https' );
ok( $defaults->wapi_version eq 'v2.7' );
ok( !$defaults->insecure );
ok( $defaults->timeout == 10 );

my $n = DNS::NIOS->new(
    username  => "username",
    password  => "password",
    wapi_addr => $nios->addr,
    scheme    => "http"
);
ok( $n->scheme eq 'http' );
$n->scheme('https');
ok( $n->scheme eq 'https' );

my $x = $n->get( path => 'record:a' );
ok( $x->{_rc} == 400 );
ok( !$x->is_success );
ok( from_json( $x->decoded_content )->{code} eq "Client.Ibap.Proto" );

$x = $n->get( path => 'record:a', params => { _paging => 1 } );
ok( $x->{_rc} == 400 );
ok( !$x->is_success );
ok( from_json( $x->decoded_content )->{code} eq "Client.Ibap.Proto" );
ok( from_json( $x->decoded_content )->{text} eq
      "_return_as_object needs to be enabled for paging requests." );

$x = $n->get(
    path   => 'record:a',
    params => {
        _paging           => 1,
        _max_results      => 1,
        _return_as_object => 1
    }
);
ok( $x->{_rc} == 200 );
ok( $x->is_success );

foreach ( @{ from_json( $x->decoded_content )->{result} } ) {
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
ok( $x->{_rc} == 201 );

my $ref = substr( $x->{_content}, 1, -1 );

$x = $n->get(
    path   => "record:a",
    params => {
        _paging           => 1,
        _max_results      => 1,
        _return_as_object => 1
    }
);
ok( $ref eq from_json( $x->decoded_content )->{result}[0]->{_ref} );

$x = $n->update(
    path    => $ref,
    payload => {
        name => "rhds-1.ext.home"
    }
);

ok( $x->{_rc} == 200 );
$x = $n->get(
    path   => "record:a",
    params => {
        _paging           => 1,
        _max_results      => 1,
        _return_as_object => 1
    }
);
ok(
    "rhds-1.ext.home" eq from_json( $x->decoded_content )->{result}[0]->{name} );

## All done
done_testing();
