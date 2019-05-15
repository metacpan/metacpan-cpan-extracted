#!/usr/bin/env perl

use strict;
use warnings;
use Cfn;
use Test::More;

{
  my $obj = Cfn->new;
  $obj->addMetadata({ MyMDTest1 => { Ref => 'XXX' },
                      'MyMDTest2', 'String',
                      'MyMDTest3', { a => 'hash' },
                      'MyMDTest4', [ 1,2,3,4 ]
  });
  my $struct = $obj->as_hashref;

  is_deeply($struct->{Metadata}->{ MyMDTest1 }, { Ref => 'XXX' }, 'Got a Ref in MyMDTest1');
  cmp_ok($struct->{Metadata}->{ MyMDTest2 }, 'eq', 'String', 'Got a string in MyMDTest2');
  is_deeply($struct->{Metadata}->{ MyMDTest3 }, { a => 'hash' }, 'Got a hash in MyMDTest3');
  is_deeply($struct->{Metadata}->{ MyMDTest4 }, [ 1,2,3,4 ], 'Got an array in MyMDTest4');
}

{
  my $o = Cfn->new;
  $o->addMetadata({ MyMDTest1 => { Ref => 'XXX' } });
  my $s = $o->as_hashref;
  is_deeply($s->{Metadata}->{ MyMDTest1 }, { Ref => 'XXX' }, 'Got a Ref in MyMDTest1');
}

{
  my $o = Cfn->new;
  $o->addMetadata({ 'MyMDTest2', 'String' });
  my $s = $o->as_hashref;
  cmp_ok($s->{Metadata}->{ MyMDTest2 }, 'eq', 'String', 'Got a string in MyMDTest2');
}

{
  my $o = Cfn->new;
  $o->addMetadata({ 'MyMDTest3', { a => 'hash' } });
  my $s = $o->as_hashref;
  is_deeply($s->{Metadata}->{ MyMDTest3 }, { a => 'hash' }, 'Got a hash in MyMDTest3');
}

{
  my $o = Cfn->new;
  $o->addMetadata({ 'MyMDTest4', [ 1,2,3,4 ] });
  my $s = $o->as_hashref;
  is_deeply($s->{Metadata}->{ MyMDTest4 }, [ 1,2,3,4 ], 'Got an array in MyMDTest4');
}


done_testing;
