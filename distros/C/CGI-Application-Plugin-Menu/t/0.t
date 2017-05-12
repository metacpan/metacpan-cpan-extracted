use Test::Simple 'no_plan';
use strict;
use lib './lib';
use lib './t';
use MTest;
use Smart::Comments '###';
$CGI::Application::Plugin::Menu::DEBUG = 1;

my $a = new MTest;


ok($a,'instanced');

my $o = $a->menu;
ok($o,'got menu basic');
ok($o->name eq 'main', 'name is main');

ok( $o->add('view_stuff') , 'added item');

my $h = $o->_get_menuitems;

### $h



ok( ! $o->add('view_stuff') , 'cannot add same item again');

ok($o->count ==1 ,'menuitems count is 1');



ok( $o->add('search_stuff') , 'added item');
ok($o->count ==2 ,'menuitems count is 2');

ok( $o->add('browse_stuff') , 'added item');
ok($o->count ==3 ,'menuitems count is 3');


ok( $o->add('http://leocharre.com','My Self Site') , 'added item');
ok( $o->add('http://cpan.org') , 'added item');

my $loop = $o->loop;

### $loop

my $output = $o->output;
ok($output,'got output');

### $output


ok($a->menus_count == 1 ,'menus count is one');

ok($a->menu('session'),'new menu');
ok($a->menus_count == 2 ,'menus count is two');


ok( $a->menu_delete('session'),'deleted menu "session"' );
ok( $a->menus_count == 1 ,'menu count is now 1');


