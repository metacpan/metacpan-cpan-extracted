#!perl -T

use strict;
use Test::More tests => 1;

use Acme::PlayCode;

my $from = <<'FROM';
my $last_15_min = time() - 900;
FROM

my $to = <<'TO';
my $last_15_min = time() - 900;
TO

my $app = Acme::PlayCode->new();
$app->load_plugin('NumberPlus');
my $ret = $app->play($from);

is($ret, $to, '1 ok');
