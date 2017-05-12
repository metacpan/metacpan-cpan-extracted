#!perl -T

use strict;
use Test::More tests => 1;

use Acme::PlayCode;

my $from = <<'FROM';
my $a = <<'GG';
AAAAAAAAAAAbbbb
GG
my $b = <<HH;
sadsd
sadsad
HH
test(<<'TT');
TTTTxxxxxxx
TT
FROM

my $to = <<'TO';
my $a = <<'GG';
AAAAAAAAAAAbbbb
GG
my $b = <<HH;
sadsd
sadsad
HH
test(<<'TT');
TTTTxxxxxxx
TT
TO

my $app = Acme::PlayCode->new();
$app->load_plugin('Averything');
my $ret = $app->play($from);

is($ret, $to, '1 ok');
