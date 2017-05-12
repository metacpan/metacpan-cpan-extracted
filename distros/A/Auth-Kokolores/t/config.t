#!perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

use Auth::Kokolores::Config;

my $c;
lives_ok {
  $c = Auth::Kokolores::Config->new;
} 'create Auth::Kokolores::Request object with defaults';
isa_ok( $c, 'Auth::Kokolores::Config');

ok( ! defined $c->user, 'user must be undef');

lives_ok {
  $c = Auth::Kokolores::Config->new_from_file('etc/kokolores.conf');
} 'create Auth::Kokolores::Request object with etc/kokolores.conf';
isa_ok( $c, 'Auth::Kokolores::Config');

cmp_ok( $c->user, 'eq', 'kokolores', 'user must be set to kokolores');

