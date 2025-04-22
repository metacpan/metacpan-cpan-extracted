#!/usr/bin/env perl

use Object::Pad;
use CAD::OpenSCAD;
use CAD::OpenSCAD::Math;
use CAD::OpenSCAD::GearMaker;
use CAD::OpenSCAD::Loft;
use Test::Simple tests => 8;
ok( $foo = new OpenSCAD,         'creating OpenSCAD object '  );
ok( $foo ->cube("cube"),     'creating cube'              );
ok( $foo ->items->{"cube"} =~/cube\(/g,'script generated' );
ok( $math = new CAD::OpenSCAD::Math,        'creating Math object '      );
ok( ${$math->add([1,1],[2,2])}[0]==3, 'Math Operations '  );
ok( $gm = new CAD::OpenSCAD::GearMaker(scad=>$foo),'creating Gear object');

my $profile=[[-1,1],[1,0.5],[1.75,0.25],[1.75,-0.25],[1,-0.5],[-1,-1]];
push @$face1,[0,$_->[0],$_->[1]] foreach(@$profile);
ok( $lt = new CAD::OpenSCAD::Loft(scad=>$foo),'creating Loft object');
ok( $lt->helix("loft1",$profile,4,20,3,2,1),
                                'creating a helix loft '  );



