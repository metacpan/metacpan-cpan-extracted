use warnings;
use strict;
use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);
use Test::More tests => 8;
use Data::Dumper;

$| = 1;
$Data::Dumper::Indent = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Useqq = 1;
$Data::Dumper::Deepcopy = 1;
BEGIN { use_ok('Data::StreamSerializer') };

my $t = { a => 'b' };
$t->{c} = $t;

my $sr = new Data::StreamSerializer $t;

my $str = '';
while(defined(my $part = $sr->next)) {
    $str .= $part;
}


ok $sr->recursion_detected, "Detected hash recursion";
eval $str;
ok !$@, 'Result is deserialized correctly';

my $a;
my $b = \$a;
my $c = \$b;
my $d = \$c;
my $e = \\\\\\\ $d;
$a = \$d;

$sr = new Data::StreamSerializer($a);
$sr->recursion_depth(2);
$str = '';
while(defined(my $part = $sr->next)) {
    $str .= $part;
}

ok $str eq 'undef', 'Scalar recursion';
ok $sr->recursion_detected, "Detected scalar recursion";
eval $str;
ok !$@, 'Result is deserialized correctly';

$t = [ qw( a b c ) ];
push @$t, $t;

$sr = new Data::StreamSerializer $t;
$str = '';
while(defined(my $part = $sr->next)) {
    $str .= $part;
}

ok $sr->recursion_detected, "Detected ARRAY recursion";
eval $str;
ok !$@, 'Result is deserialized correctly';
