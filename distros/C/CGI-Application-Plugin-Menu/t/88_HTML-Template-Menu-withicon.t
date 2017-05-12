use Test::Simple 'no_plan';
use strict;

use lib './lib';
use HTML::Template::Menu;
use HTML::Template;
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
$m->add('http://cpan.org');

$m->menu_class_set('mainmenu');

my $tmpl = new HTML::Template( scalarref => \q{
<div class="<TMPL_VAR MAIN_MENU_CLASS>"><p>
<TMPL_LOOP MAIN_MENU_LOOP>
   <nobr><b>
      <img src="/.icons/<TMPL_VAR ICON>.png">
      <a href="<TMPL_VAR URL>">[<TMPL_VAR LABEL>]</a></b></nobr></TMPL_LOOP></p>
</div>

} );

$tmpl->param( MAIN_MENU_LOOP => $m->loop );

my $o = $tmpl->output;

print STDERR $o;

