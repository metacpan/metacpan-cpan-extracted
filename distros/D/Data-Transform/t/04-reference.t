#!/usr/bin/perl -w
# $Id$
# vim: filetype=perl

# Exercises Filter::Reference without the rest of POE.

use strict;
use lib qw(t/);

use TestFilter;
use Test::More;

plan tests => 9 + $COUNT_FILTER_INTERFACE + $COUNT_FILTER_STANDARD;

use_ok('Data::Transform::Reference');

test_filter_interface('Data::Transform::Reference');

# A trivial, special-case serializer and reconstitutor.

sub freeze {
  my $thing = shift;
  return reverse(join "\0", ref($thing), $$thing) if ref($thing) eq 'SCALAR';
  return reverse(join "\0", ref($thing), @$thing) if ref($thing) eq 'Package';
#  return reverse(join "\0", ref($thing), @$thing) if ref($thing) eq 'ARRAY';
  die;
}

sub thaw {
  my $thing = reverse(shift);
  my ($type, @stuff) = split /\0/, $thing;
  if ($type eq 'SCALAR') {
    my $scalar = $stuff[0];
    return \$scalar;
  }
#  if ($type eq 'ARRAY') {
#    return \@stuff;
#  }
  if ($type eq 'Package') {
    return bless \@stuff, $type;
  }
  die;
}

my $filter;

eval { $filter = Data::Transform::Reference->new };
like($@, qr/requires a serialize parameter/, 'no serialize param fails');

eval { $filter = Data::Transform::Reference->new(serialize => 'freeze') };
like($@, qr/serialize parameter must be a CODE ref/, 'bad serialize param fails');

eval { $filter = Data::Transform::Reference->new(serialize => \&freeze) };
like($@, qr/requires a deserialize parameter/, 'no deserialize param fails');

eval { $filter = Data::Transform::Reference->new(serialize => \&freeze, deserialize => 'thaw') };
like($@, qr/deserialize parameter must be a CODE ref/, 'bad deserialize param fails');

$filter = Data::Transform::Reference->new(serialize => \&freeze, deserialize => \&thaw);

isa_ok($filter, 'Data::Transform::Reference');

my $data = "test";
my $ref = \$data;
my $frozen = &freeze($ref);
{ use bytes;
        $frozen = length($frozen) . "\0" . $frozen;
}
test_filter_standard($filter,
        [$frozen],
        [$ref],
        [$frozen],
);
# Run some tests under a certain set of conditions.
sub test_freeze_and_thaw {
  my ($filter) = @_;

  my $scalar     = 'this is a test';
  my $scalar_ref = \$scalar;
  my $object_ref = bless [ 1, 1, 2, 3, 5 ], 'Package';

  my $put = $filter->put( [ $scalar_ref, $object_ref ] );
  my $got = $filter->get( $put );

  is_deeply(
    $got,
    [ $scalar_ref, $object_ref ],
    "filter successfully froze and thawed"
  );
}

# Test each combination of things.
test_freeze_and_thaw($filter);

# Test get_pending.

#my $pending_filter = Data::Transform::Reference->new();
use Storable qw();
$filter = Data::Transform::Reference->new(serialize => Storable->can('nfreeze'), deserialize => Storable->can('thaw'));
is($filter->get_pending(), undef, 'nothing left in filter after previous tests');

my $frozen_thing   = $filter->put( [ [ 2, 4, 6 ] ] );
$filter->get_one_start($frozen_thing);
my $pending_thing  = $filter->get($filter->get_pending());

is_deeply(
  $pending_thing, [ [ 2, 4, 6 ], [ 2, 4, 6 ] ],
  "filter reports proper pending data"
);

