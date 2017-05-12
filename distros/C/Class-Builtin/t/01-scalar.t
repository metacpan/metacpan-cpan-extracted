#!perl -T
use strict;
use warnings;
use Class::Builtin;
use Test::More qw/no_plan/; #tests => 1;
use Encode;

my $o = OO('小飼弾');
is(ref $o, 'Class::Builtin::Scalar', ref $o);

is($o->length, 9, sprintf qq('%s'->length), $o);
is($o->utf8->length, 3, sprintf qq('%s'->utf8->length), $o);
is($o->utf8->[2], decode_utf8('弾'), sprintf qq('%s'->utf8->[2]), $o);

$o = OO(0.00);
is (!$o, !!1, 'bool');
is ("$o", "0", '""');
is ($o+0, 0, '0+');

my $a  = 42;
my $b  = atan2(1,1) * 4;
my $oa = OO $a;
my $ob = OO $b;

for my $op (qw{+ - * / % ** << >> & | ^ . x }){
    my $code = eval qq{ sub { \$_[0] $op \$_[1] } };
    my $c  = $code->($a,  $b);
    my $oc = $code->($oa, $b);
    ok (ref $oc, "ref (OO($a) $op $b)");
    is ($c, $oc, "OO($a) $op $b");
    $oc = $code->($oa, $ob);
    ok (ref $oc, "ref (OO($a) $op OO($b)");
    is ($c, $oc, "OO($a) $op OO($b)");
}

__END__
