use Test::Simple 'no_plan';
use strict;

use lib './lib';
use HTML::Template::Menu;

ok(1,'loaded');

my $m = new HTML::Template::Menu;

$m->name_set('Test Menu');

ok( $m->add('/') );
ok( $m->add('/contact.html') );
ok( $m->add('view_more'));
ok( $m->add('/doc/review_coorporate.html'));
ok( $m->add('/doc/review_coorporate.php?val1=this'));
ok( $m->add('/tips'));
$m->add('/cars/');

$m->menu_class_set('mainmenu');

my $o = $m->output;

print STDERR $o;

