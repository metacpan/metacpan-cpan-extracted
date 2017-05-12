#!perl -T

use strict;
use Test::More;

use Acme::PlayCode;

my $from = <<'FROM';
my $a = 1 + 2;
if ( $b > 2 * 3 ) {
FROM

my $to = <<'TO';
my $a = 3; # 3 = 1 + 2
if ( $b > 6 ) { # 6 = 2 * 3
TO

my @froms = split(/\r?\n/, $from);
my @tos   = split(/\r?\n/, $to);

plan tests => scalar @froms + 1;

my $app = Acme::PlayCode->new();
$app->load_plugin('NumberPlus');

foreach my $i ( 0 .. $#froms ) {
    my $fr_line = $froms[$i];
    my $to_line = $tos[$i];
    my $played_line = $app->play($fr_line);
    is $played_line, $to_line;
}

my $ret = $app->play($from);
is($ret, $to, '1 ok');
