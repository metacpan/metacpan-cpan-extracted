#!/usr/bin/env perl
use Object::Pad;
use CAD::OpenSCAD::Math;
use Test::Simple tests => 8;
ok( $foo = new CAD::OpenSCAD::Math,         'creating OpenSCAD::Math object '  );
ok(  $foo ->equal([2,3],[2,3]) ,          'test equals '                       );
ok(! $foo ->equal([1,1],[1,2]) ,             'test not equals '                );
ok( $foo ->equal([1,[2,3]],[1,[2,3]]) ,      'test nested mixed equals '       );
ok( $foo->equal( $foo ->add  ([1,1],[1,2]),[2,3] ),'test add '                 );
ok( $foo->equal( $foo ->add  ([1,1,2],[1,2,4]),[2,3,6] ),'test add '           );
print $foo->serialise($foo->rotate([1,1,2],[0,$foo->pi,0])),":\n";
print $foo->serialise([-1,1,-2]),":\n";    
ok( $foo->serialise([-1,1]) eq $foo->serialise($foo->rotate([1,1],$foo->pi/2)),'test 2d rotate ' );
ok( $foo->serialise([-1,1,-2]) eq $foo->serialise($foo->rotate([1,1,2],[0,$foo->pi,0])),'test 3d rotate ' );
   



