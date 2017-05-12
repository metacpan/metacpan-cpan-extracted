
use strict;
use warnings;
use Test::More qw(no_plan);

use Data::Range::Compare::Stream;
use Data::Range::Compare::Stream::Iterator::Array;

use_ok('Data::Range::Compare::Stream::Iterator::Validate');

{
  eval{ Data::Range::Compare::Stream::Iterator::Validate->new };
  ok($@,'should croak with an error when no iterator is passed in');
}

{
  my $o=Data::Range::Compare::Stream::Iterator::Array->new(sorted=>1);
  my $c='Data::Range::Compare::Stream';
  # bad ranges
  $o->insert_range($c->new);          # 1
  $o->insert_range($c->new(0));       # 2
  $o->insert_range($c->new(undef,0)); # 3
  $o->insert_range($c->new(1,0));     # 4

  # good ranges
  $o->insert_range($c->new(0,0));
  $o->insert_range($c->new(1,2));

  my $check;
  my $sub=sub { ++$check };
  my $s=Data::Range::Compare::Stream::Iterator::Validate->new($o,on_bad_range=>$sub);
  {
    ok($s->has_next,'object should have next');
    my $result=$s->get_next;
    my $string=$result->to_string;
    cmp_ok($string,'eq','0 - 0','range check');
  }
  {
    ok($s->has_next,'object should have next');
    my $result=$s->get_next;
    my $string=$result->to_string;
    cmp_ok($string,'eq','1 - 2','range check');
  }
  ok(!$s->has_next,'iterator should be empty');
  cmp_ok($check,'==',4,'invalid range count');
}
