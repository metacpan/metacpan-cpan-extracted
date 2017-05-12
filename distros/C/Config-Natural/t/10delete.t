use strict;
use Test;
BEGIN { plan tests => 2 }
use Config::Natural;
Config::Natural->options(-quiet => 1);
my $obj = new Config::Natural;

$obj->read_source(File::Spec->catfile('t','eva.txt'));

# Episode 0:23, Namida
$obj->delete('Eva_00');
ok( $obj->param('Eva_00'), undef );  #01

undef $obj;
$obj = new Config::Natural;
$obj->read_source(File::Spec->catfile('t','shito.txt'));

# Episode 0:24, Saigo no Shi-Sha
$obj->delete_all;
ok( $obj->param(), 0 );  #02
