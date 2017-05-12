# -*- perl -*-

use Test::More tests => 28;

BEGIN { use_ok( 'Array::Average' ); }

#No export
is(Array::Average::average(), undef, "no export () case");
is(Array::Average::average([2,3,4]), 3, "no export [] case");

#Exporter
#Normal Cases
is(average(), undef, "() case");
is(average(undef), undef, "() case");
is(average(3), "3", "1 scalar");
is(average(1,2,3,4,5), "3", "1 scalar");
is(average([1,2,3,4,5]), "3", "1 scalar");
is(average({a=>2,b=>3,c=>4}), "3", "1 scalar");

my $var=3;
my @var=(2,3,4);
my %var=(d=>2,e=>3,f=>4);
is(average($var), 3, "scalar");
is(average(@var), 3, "array");
is(average(\$var), 3, "scalar ref");
is(average(\@var), 3, "array ref");
is(average(\%var), 3, "hash ref");
is(average($var, \$var, @var, \%var, \@var), 3, "multi");

#Suported cases
is(average(3,undef), "3", "undef and scalar");
is(average(3,3), "3", "2 scalars");
is(average(2,3,4), "3", "3 scalars");
is(average(\3), "3", "scalar ref");
is(average(3,\3), "3", "scalar and scalar ref");
is(average(\3,\3), "3", "scalar ref and scalar ref");
is(average([3]), "3", "array ref");
is(average([3],3,{k=>3},1,\5,3,{a=>2,c=>4}), "3", "array ref, hash ref, scalar ref, scalars");
is(average(3,4,5,6,7), 5, "test scalars");
is(average([3,4,5,6],7), 5, "test scalars");
is(average(\3,\4,\5,6,7), 5, "test scalars");

is(average(2,4,[2,4,[2,4,[3,{a=>3,b=>[2,3,4], c=>{a=>2,b=>4}}]]]), 3, "test crazy data structure");


use Scalar::Util qw{dualvar};

is(average(dualvar(6,"six"), dualvar(4,"four")), 5, "test scalars");
