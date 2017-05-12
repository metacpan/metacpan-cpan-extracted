#!perl -T
use strict;
use warnings;
use Test::More 'no_plan';

BEGIN {
    use_ok( 'Color::Model::RGB', ':all' ) || print "Bail out!\n";
}

diag( "Testing Color::Model::RGB $Color::Model::RGB::VERSION, Perl $], $^X" );




note("--- Exporting function\n");
ok(set_format('#%02x%02x%02x',1), "set_format()");
my ($fmt,$flg) = get_format();
ok($fmt eq '#%02x%02x%02x' && $flg==1, "get_format()");




note("--- Methods\n");
my ($o,$r,$g,$b,$w) = (O,R,G,B,W);
ok(($o->r() == 0.0 and $o->g() == 0.0 and $o->b() == 0.0), "O");
ok(($r->r() == 1.0 and $r->g() == 0.0 and $r->b() == 0.0), "R");
ok(($g->r() == 0.0 and $g->g() == 1.0 and $g->b() == 0.0), "G");
ok(($b->r() == 0.0 and $b->g() == 0.0 and $b->b() == 1.0), "B");
ok(($w->r() == 1.0 and $w->g() == 1.0 and $w->b() == 1.0), "B and r(),g(),b()");
ok(($o->r256() == 0   and $o->g256() == 0   and $o->b256() == 0  ), "O - 256");
ok(($r->r256() == 255 and $r->g256() == 0   and $r->b256() == 0  ), "R - 256");
ok(($g->r256() == 0   and $g->g256() == 255 and $g->b256() == 0  ), "G - 256");
ok(($b->r256() == 0   and $b->g256() == 0   and $b->b256() == 255), "B - 256");
ok(($w->r256() == 255 and $w->g256() == 255 and $w->b256() == 255), "W - 256, and r256(),g256(),b256()");

my $col1 = Color::Model::RGB->new(0.25, 0.5, 0.75);
ok ( $col1->hexstr() eq '4080c0', "new()");
my $col2 = rgb(0.2, 0.6, 0.8);
ok ( $col2->hexstr() eq '3399cc', "rgb()");
my $col3 = rgb256(64,128,192);
ok ( $col3->hexstr() eq '4080c0', "rgb256()");
my $col4 = rgbhex('#4080c0');
ok ( $col3->hexstr() eq '4080c0', "rgbhex() and hexstr()");

$col1->r(0.5);
ok ( $col1->hexstr() eq '8080c0', "mutate with r()");
$col2->g(0.4);
ok ( $col2->hexstr() eq '3366cc', "mutate with g().");
$col3->b(1);
ok ( $col3->hexstr() eq '4080ff', "mutate with b()");

my $col5 = rgb(-1.0,-0.5,0.5)->truncate;
ok ( $col5->hexstr() eq '000080', "truncate()");
ok ( $col5->stringify() eq '#000080', "stringify()");
my $col6 = rgb(0.5,0.75,1.0);
ok ( $col6->stringify('[%.2f,%.2f,%.2f]',0) eq '[0.50,0.75,1.00]', "stringify(format,flag)");



