use Test::Simple 'no_plan';
use strict;
use lib './lib';
use warnings;
use lib './t';
use TestOne;
ok(1);
$ENV{CGI_APP_RETURN_ONLY} = 1;

my $t = new TestOne;

ok($t,' instanced');
ok(ref $t,'object is ref');


use Smart::Comments '###';
#use Data::Dumper;
#my %modes = $t->run_modes;
#printf STDERR " runmodes %s\n\n", Data::Dumper::Dumper(\%modes);

my $vars ;
$vars= $t->_set_vars;
### vars to start with: $vars

$t->start_mode('test2');

ok( $t->_set_vars( V1 => 'THIS IS A TITLE' ), 'set vars');
ok( $t->tmpl_set( V2 => 'THIS IS A TITLE 2' ), 'tmpl_set');


ok( $t->_set_tmpl_default(q{var1 <TMPL_VAR V1><br>var2 <TMPL_VAR V2>},'test2.html'), 'set default template');



my $v;

ok( $v = $t->_tmpl('test2.html'), '_tmpl()');

ok( ref $v, '_tmpl() returns ref');

ok( $t->run, 'run()');



ok( $v = $t->_get_tmpl_name(), "_get_tmpl_name() $v");
ok( $v = $t->tmpl_inner_name, "tmpl_inner_name $v");

ok( $t->_tmpl_inner, '_tmpl_inner()');
ok( $t->_tmpl_outer, '_tmpl_outer()');



ok( $t->_tmpl('test2.html'), '_tmpl() returns object');


ok $v = $t->tmpl_output, "tmpl_output() \n$v";

$vars= $t->_set_vars;
### vars now: $vars

