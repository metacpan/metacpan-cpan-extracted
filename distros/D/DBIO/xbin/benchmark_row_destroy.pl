#!/usr/bin/env perl

# Benchmark: DESTROY overhead on DBIO row objects
#
# In DBIx::Class, every single object inherited a DESTROY method from the
# root class that maintained a destruction registry:
#
#   sub DESTROY { &DBIx::Class::Util::detected_reinvoked_destructor }
#
# The registry protected against broken Perl/toolchain versions that could
# invoke destructors multiple times. On each DESTROY it:
#   1. Iterated ALL known live objects to GC dead weakrefs  <- O(n) per call
#   2. Checked the registry for this specific object        <- O(1)
#
# Total cost: O(n) per object destruction = O(n^2) for n objects.
#
# DBIO never carried this overhead — it was dropped from the start.
#
# This benchmark inflates real DBIO row objects from mock storage and
# compares their create+destroy cycle with/without the registry DESTROY
# injected, showing the real-world gain.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../lib";

use Benchmark qw(cmpthese);
use Scalar::Util;
use DBIO::Test;

my $schema = DBIO::Test->init_schema(no_populate => 1);
my $storage = $schema->storage;

my $old_destroy_sub = do {
  my $registry = {};
  sub {
    my $self = $_[0];
    defined $registry->{$_} or delete $registry->{$_}
      for keys %$registry;
    my $addr = Scalar::Util::refaddr($self);
    Scalar::Util::weaken($registry->{$addr} = $self)
      if !defined $registry->{$addr};
  };
};

for my $n (10, 100, 500, 2000, 10_000) {
  printf "\n--- %d Artist rows inflated from mock storage ---\n", $n;

  my @mock_rows = map { [$_, "Artist $_", 13, undef] } 1..$n;

  cmpthese(-2, {
    'old (registry DESTROY)' => sub {
      no warnings 'once';
      local *DBIO::Row::DESTROY = $old_destroy_sub;
      $storage->mock_persistent(qr/SELECT/, \@mock_rows,
        [qw(artistid name rank charfield)]);
      my @rows = $schema->resultset('Artist')->all;
      @rows = ();
    },
    'new (no DESTROY)' => sub {
      $storage->mock_persistent(qr/SELECT/, \@mock_rows,
        [qw(artistid name rank charfield)]);
      my @rows = $schema->resultset('Artist')->all;
      @rows = ();
    },
  });
}
