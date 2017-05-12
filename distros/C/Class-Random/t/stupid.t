# $Id: stupid.t,v 1.2 2002/08/06 17:04:02 pmh Exp $

use strict;

print "1..2\n";
my %count;

package T;
use Class::Random choose => ['A'],['B'];

sub new{
  bless {};
}

package S;
use Class::Random shuffle => qw(A B);

sub new{
  bless {};
}

package A;
sub foo{
  ++$count{a_foo};
}
sub bar{
  ++$count{a_bar};
}

package B;

sub foo{
  ++$count{b_foo};
}
sub bar{
  ++$count{b_bar};
}

package main;

my $test;
foreach(
  [choose => 'T'],
  [shuffle => 'S'],
){
  my($mode,$class)=@$_;
  my $t=$class->new;

  %count=();
  for(1..100){
    $t->foo;
    $t->bar;
  }

  my $ok;
  foreach(qw(a_foo a_bar b_foo b_bar)){
    if($count{$_}<25){
      $ok="Failed to call $_ enough times to pass $mode test";
    }
  }
  ++$test;
  if(defined $ok){
    print "not ok $test # $ok\n";
  }else{
    print "ok $test # $mode\n";
  }
}

