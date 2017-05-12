use strict;
use Test;
BEGIN { plan tests => 8 }
use Config::Natural;
Config::Natural->options(-quiet => 1);
my $obj = new Config::Natural;

$obj->read_source(File::Spec->catfile('t','nerv.txt'));

# getting the tree (not of the Sepira) of the parameters
my $tree = undef;
$tree = $obj->param_tree();
ok( defined $tree );  #01
ok( ref $tree, 'HASH' );  #02

# now checking that everything's in place
ok( $tree->{nerv}[0]{name},             "Nerv"                );  #03
ok( $tree->{nerv}[0]{First_Children},   "Ayanami Rei"         );  #04
ok( $tree->{nerv}[0]{Second_Children},  "Soryu Asuka Langley" );  #05
ok( $tree->{nerv}[0]{Third_Children},   "Ikari Shinji"        );  #06
ok( $tree->{nerv}[0]{Fourth_Children},  "Suzuhara Toji"       );  #07
ok( $tree->{nerv}[0]{Fifth_Children},   "Nagisa Kaoru"        );  #08

