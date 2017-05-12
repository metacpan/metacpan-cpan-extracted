use t::lib;
use strict;
use Carp;
use Test::More;
use Class::AutoDB;
use autodbUtil;

use Bottom; use Top;

my $autodb=new Class::AutoDB(database=>testdb); # open database

my $bottom=new Bottom(name=>'bottom',id=>id_next());
my $top=new Top(name=>'top',id=>id_next());

my $test=new autodbTestObject(get_type=>'find');
$test->test_get
  (labelprefix=>'get:',
   label=>sub {my $test=shift; my $obj=$test->current_object; $obj && $obj->name;},
   correct_colls=>['Person'],coll2basekeys=>{Person=>[qw(name id)]},
   correct_objects=>[$bottom,$top],get_args=>{collection=>'Person'},);

done_testing();
