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

use Test::More;
use Test::Fatal;

like(
  exception { my $n = DNS::NIOS->new() },
  qr/\w+ is required!/,
  'Missing required connection parameters',
);

like(
  exception {
    my $n = DNS::NIOS->new(
      username  => qw[x],
      password  => qw[x],
      wapi_addr => qw[x],
      scheme    => qw[x]
    )
  },
  qr/^scheme not supported: x/,
  'Not supported scheme',
);

my $defaults = DNS::NIOS->new(
  username  => qw[x],
  password  => qw[x],
  wapi_addr => qw[x]
);

ok( $defaults->scheme eq 'https' );
ok( $defaults->wapi_version eq 'v2.7' );
ok( !$defaults->insecure );
ok( $defaults->timeout == 10 );

$defaults->scheme('http');
$defaults->wapi_version('v2.8');
$defaults->insecure(1);
$defaults->timeout(20);

ok( $defaults->scheme eq 'http' );
ok( $defaults->wapi_version eq 'v2.8' );
ok( $defaults->insecure );
ok( $defaults->timeout == 20 );

## All done
done_testing();
