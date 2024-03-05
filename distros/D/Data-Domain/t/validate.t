#!perl
use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Data::Domain qw/:all/;
use Try::Tiny;
use Time::HiRes  qw/gettimeofday/;

my $dom;
my $msg;
my $val;


# -default with a constant value
$dom = String(-default => "foo");
is $dom->validate(undef), "foo", "default string";
is $dom->validate("bar"), "bar", "regular string handling";

# -default with a sub
$dom = List(-items => [Nat, Nat], -default => sub {[gettimeofday]});
my $t1 = $dom->validate(undef);
my $t2 = $dom->validate(undef);
ok $t2->[0] > $t1->[0] || ($t2->[0] == $t1->[0] && $t2->[1] >= $t1->[1]), "-default calling a sub";

# -default with a sub that uses the $context
$dom = List(-all => String(-default => sub {join ",", @{shift->{path}}}));
$val = $dom->validate([undef, 999, undef]);
is_deeply $val, [0, 999, 2], "sub for -default uses the context";


# nested defaults
$dom = Struct(foo => Int,
              bar => Int(-default => 123),
              zim => List(-items => [String, String(-default => "qqq")],
                          -default => [qw/a b c/]));
$val = $dom->validate({foo => 456, zim => ["aaa"]});
my $expected = { bar => 123,
                 foo => 456,
                 zim => ['aaa', 'qqq'] };
is_deeply($val, $expected, "-default for nested domains");

# invalid input
undef $val;
try {$val = $dom->validate({foo => "foo", bar => "bar"})} catch {$msg = $_};
ok ! $val, "invalid input";
like $msg, qr/\bbar\b.*?invalid number/, "proper error msg";


# -if_absent
$dom = Struct(arg1 => String(-default => 'foo'), arg2 => String(-if_absent => 'bar'));
$val = $dom->validate({});
is_deeply($val, {arg1 => 'foo', arg2 => 'bar'}, "-if_absent when absent");
$val = $dom->validate({arg1 => 'bar', arg2 => 'be', arg3 => 'cue'});
is_deeply($val, {arg1 => 'bar', arg2 => 'be', arg3 => 'cue'}, "-if_absent not applied");
$val = $dom->validate({arg1 => undef, arg2 => undef, arg3 => 'cue'});
is_deeply($val, {arg1 => 'foo', arg2 => undef, arg3 => 'cue'}, "-if_absent with explicit undef");


# optional sublist
$dom = List(String, List(-all => String, -optional => 1), String);
$val = $dom->validate(['foo', undef, 'bar']);
$expected = ['foo', undef, 'bar'];
is_deeply($val, $expected, "optional sublist");


# func_signature
{ my $sig = List(Int, Int, Int(-default => 1))->func_signature;
  sub func_extractor {
    my ($x, $y, $z) = &$sig;
    return $x + $y + $z;
  }
  
  is(func_extractor(3, 2), 6, "func_extractor");
}

# meth_signature
{ my $sig = Struct(x => Int, y => Int, z => Int(-default => 1))->meth_signature;
  my $meth = sub {
    my ($self, %args) = &$sig;
    return $args{x} + $args{y} + $args{z};
  };
  my $fake_obj = bless {}, "Foo";
  is $fake_obj->$meth(x => 1, y => 1), 3, "meth_extractor";
}

# func_signature for All_of domain
{ my $sig = All_of(Int, String(-regex => qr/^1.*9$/))->func_signature;
  sub all_of_func_extractor {
    my ($x) = &$sig;
    return "I got number $x";
  }
  is all_of_func_extractor(13579), "I got number 13579", "All_of func_extractor";
}


done_testing;






