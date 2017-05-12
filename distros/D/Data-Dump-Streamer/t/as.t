#!perl -w

#$Id: as.t 26 2006-04-16 15:18:52Z demerphq $#

use Test::More tests => 4;

use_ok 'Data::Dump::Streamer';

import Data::Dump::Streamer as => 'DDS';

{
    package Foo;
    use base Data::Dump::Streamer;
    import Data::Dump::Streamer as => 'Bar';
}

my $dds;

$dds = DDS->new;
ok($dds, "aliased namespace works for object construction");

$dds = Foo->new;
ok($dds, "derived package constructor works");

$dds = Bar->new;
ok($dds, "aliased namespace works with derived package constructor");
