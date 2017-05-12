#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->parent->parent->subdir('t', 'lib')->stringify;

use Test::DBIx::Class;

use Class::MOP;

fixtures_ok 'basic', 'installed the basic fixtures from configuration files';

# test if applying the same role to multiple Moose::Meta::Attribute instances
# will create only one new anonymous class (a Moose internal, but essential for
# us)

{
  my $artist1 = Schema->resultset('Artist')->find({ artist_id => 1 });

  my $meta = Class::MOP::Class->initialize(ref $artist1);

  cmp_deeply(
    {
      map {
        $_ => ref $meta->get_attribute($_),
      } qw/ name title phone initials is_active /
    },
    {
      map {
        $_ => ref $meta->get_attribute('artist_id')
      } qw/ name title phone initials is_active /
    },
    "different DBIC column associated attributes have the same class"
  );
}

done_testing;
