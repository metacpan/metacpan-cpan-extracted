# -*- perl -*-
use Test::More tests => 6;
use Algorithm::Interval2Prefix;

is interval2regex('2340','2349'), '^(?:234\d)$', 'one \d';

is interval2regex('42','42'), '^(?:42)$', 'no \d';

ok !defined(interval2regex('42','41')), 'empty';

is interval2regex('23400','23499'), '^(?:234\d{2})$', 'more \d';

is interval2regex('2339','2349'), '^(?:2339|234\d)$', 'var \d';

is interval2regex('39967000', '39980999'),
  '^(?:39967\d{3}|39968\d{3}|39969\d{3}|3997\d{4}|39980\d{3})$',
  'doc example';
