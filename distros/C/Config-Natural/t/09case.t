use strict;
use Test;
BEGIN { plan tests => 3 }
use Config::Natural;
Config::Natural->options(-quiet => 1);
my $obj = new Config::Natural;

# set case-insensitive option
$obj->case_sensitive(0);
ok( $obj->case_sensitive, 0 );  #01

$obj->read_source(File::Spec->catfile('t','children.txt'));

# check that arguments can be retrieved independently of the case
ok( $obj->param('First_Children'), $obj->param('first_children') );  #02

# check that arguments can be set independantly of the case
$obj->param({first_children => "Ayanami Rei 3"});  # Episode 0:23, Namida
ok( $obj->param('first_children'), $obj->param('FIRST_CHILDREN') );  #03
