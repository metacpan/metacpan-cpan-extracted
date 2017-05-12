#!perl -T

### This file tests primarily splice functionality

use Test::More tests => 17;
use Data::XHash qw/xh xhr/;
use Data::XHash::Splice;
use Data::Dumper;

my $tmpl = xh('one', { 2 => 'two'}, 'three', 4, 5, 6);
my ($xh, $del);

## splice all without replacement

$xh = xhr($tmpl->as_hashref());
is_deeply($xh->as_hashref(),
  [{0=>'one'},{2=>'two'},{3=>'three'},{4=>4},{5=>5},{6=>6}],
  'template copied OK');
$del = $xh->splice();
isa_ok($del, 'Data::XHash', 'default splice result');
is_deeply($xh->as_hashref(), [], 'original OK after splice()');
is_deeply($del->as_hashref(),
  [{0=>'one'},{2=>'two'},{3=>'three'},{4=>4},{5=>5},{6=>6}],
  'splice OK after splice()');

## splice with offset

$xh = xhr($tmpl->as_hashref());
$del = $xh->splice(3);
is_deeply($xh->as_hashref(), [{0=>'one'},{2=>'two'},{3=>'three'}],
  'original OK after splice(3)');
is_deeply($del->as_hashref(), [{4=>4},{5=>5},{6=>6}],
  'splice OK after splice(3)');

## splice with offset and length

$xh = xhr($tmpl->as_hashref());
$del = $xh->splice(2, 2);
is_deeply($xh->as_hashref(), [{0=>'one'},{2=>'two'},{5=>5},{6=>6}],
  'original OK after splice(2, 2)');
is_deeply($del->as_hashref(), [{3=>'three'},{4=>4}],
  'splice OK after splice(2, 2)');

## splice with negative offset and length

$xh = xhr($tmpl->as_hashref());
$del = $xh->splice(-4, -2);
is_deeply($xh->as_hashref(), [{0=>'one'},{2=>'two'},{5=>5},{6=>6}],
  'original OK after splice(-4, -2)');
is_deeply($del->as_hashref(), [{3=>'three'},{4=>4}],
  'splice OK after splice(-4, -2)');

## splice into empty

$xh = xh();
$xh->splice(undef, undef, 'one', { two => 2 });
is_deeply($xh->as_hashref(), [{0=>'one'},{two=>2}], 'splice 0 into empty OK');

## splice 0 to beginning

$xh = xh('first', 'last');
$xh->splice(0, 0, 'one', { two => 2 });
is_deeply($xh->as_hashref(), [{2=>'one'},{two=>2},{0=>'first'},{1=>'last'}],
  'splice 0 to beginning OK');

## splice 0 to middle

$xh = xh('first', 'last');
$xh->splice(1, 0, 'one', { two => 2 });
is_deeply($xh->as_hashref(), [{0=>'first'},{2=>'one'},{two=>2},{1=>'last'}],
  'splice 0 to middle OK');

## splice 0 to end

$xh = xh('first', 'last');
$xh->splice(2, 0, 'one', { two => 2 });
is_deeply($xh->as_hashref(), [{0=>'first'},{1=>'last'},{2=>'one'},{two=>2}],
  'splice 0 to end OK');

## splice 1 to beginning

$xh = xh('first', 'middle', 'last');
$xh->splice(0, 1, 'one', { two => 2 });
is_deeply($xh->as_hashref(), [{3=>'one'},{two=>2},{1=>'middle'},{2=>'last'}],
  'splice 1 to beginning OK');

## splice 1 to middle

$xh = xh('first', 'middle', 'last');
$xh->splice(1, 1, 'one', { two => 2 });
is_deeply($xh->as_hashref(), [{0=>'first'},{3=>'one'},{two=>2},{2=>'last'}],
  'splice 1 to middle OK');

## splice 1 to end

$xh = xh('first', 'middle', 'last');
$xh->splice(2, 1, 'one', { two => 2 });
is_deeply($xh->as_hashref(), [{0=>'first'},{1=>'middle'},{2=>'one'},{two=>2}],
  'splice 1 to end OK');

# END
