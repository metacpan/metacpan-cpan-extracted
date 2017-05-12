#!perl -T
use strict; use warnings; no indirect 'fatal'; use namespace::autoclean;

use Readonly;

use Test::More;
use Test::TypeTiny;
use CloudFlare::Client::Types qw( CFCode ErrorCode);

plan tests => 9;
Readonly my $INVLD_CODE => 'E_NTSPCD';
Readonly my @CF_CODES   => qw( E_UNAUTH E_INVLDINPUT E_MAXAPI);
Readonly my @ERR_CODES  => (undef, @CF_CODES);

# Test CFCode
should_pass( $_, CFCode, "$_ is a CFCode") foreach @CF_CODES;
should_fail( $INVLD_CODE, CFCode, 'E_NTSPCD is not a CFCode');

# Test ErrorCode
{ no warnings 'uninitialized';
  should_pass($_, ErrorCode, "$_ is a ErrorCode") foreach @ERR_CODES}
should_fail( $INVLD_CODE, ErrorCode, 'E_NTSPCD is not an ErrorCode');
