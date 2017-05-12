use strict;
use warnings;

package Foo;
use Moose;
use namespace::autoclean;

has 'name' => (
  isa => 'Str',
  is => 'ro',
  default => "that's my name",
);

package main;
use FindBin qw/$Bin/;
use lib qw|$Bin/lib t/lib|;

use Test::More;
use Fixture;

# f as in fixture
my ($f);

BEGIN {
  $f = Fixture->new();

  my $reason = $f->setup();
  plan skip_all => $reason if $reason;
}

use_ok('Catalyst::Plugin::Session::Store::MongoDB');

# serialize
{
  my $id = $f->new_id();
  my $session = 'session:'.$id;
  my $data = {
    'string' => $f->new_data(),
    'hashref' => {
      'key' => 'value',
    },
    'object' => Foo->new(),
    'object2' => Foo->new(name => 'object2'),
    'rnd' => Foo->new(name => $f->new_data()),
  };

  $f->store->store_session_data($session, $data);
  is_deeply ($f->store->get_session_data($session), $data, "serialize");
}

done_testing();

END {
  $f->teardown();
}

