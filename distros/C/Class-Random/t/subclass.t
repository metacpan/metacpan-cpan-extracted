# $Id: subclass.t,v 1.2 2002/08/06 17:04:37 pmh Exp $

use strict;

print "1..2\n";

package A;
sub foo{
  'foo';
}
sub bar{
  'bar';
}
sub new{
  return bless {},$_[0];
}

package B;
sub foo{
  'bar';
}
sub bar{
  'foo';
}
sub new{
  return bless {},$_[0];
}

BEGIN{
  $A::VERSION=1;
  $B::VERSION=1;
}

package R;
use Class::Random subclass => qw(A B);

package main;

my %count;

for(1..100){
  my $obj=R->new;
  ++$count{ref $obj};
}

my $t;
for(qw(A B)){
  ++$t;
  print $count{$_}>10 ? "ok $t\n" : "not ok $t\n";
}

