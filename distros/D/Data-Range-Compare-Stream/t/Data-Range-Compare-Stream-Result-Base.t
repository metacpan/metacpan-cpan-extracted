use strict;
use warnings;

use Test::More tests=>11;

use_ok('Data::Range::Compare::Stream::Result::Base');

{
  my $base=new Data::Range::Compare::Stream::Result::Base(0,1);
  ok(defined($base),'base object should exist');
  cmp_ok($base.'','eq',''.'0 - 1','instance in string context test');
  cmp_ok($base.'','eq',''.$base->get_common,'instance in string context test');
  cmp_ok($base->boolean,'==',1,'boolean check');
  ok($base,'base should return true');

}

{
  package MyTest;
  use strict;
  use warnings;

  use base qw(Data::Range::Compare::Stream::Result::Base);

  use overload
    'bool'=>\&boolean,
      '""'=>\&to_string,
        Fallback=>1;

  sub boolean { 0 }
  sub to_string { 'test' }

  1;
}

{
  my $base=new MyTest(0,1);
  ok(defined($base),'base object should exist');
  cmp_ok($base.'','eq',''.'test','instance in string context test');
  cmp_ok($base.'','eq',''.$base->get_common,'instance in string context test');
  cmp_ok($base->boolean,'==',0,'boolean check');
  ok(!$base,'base should return true');

}
