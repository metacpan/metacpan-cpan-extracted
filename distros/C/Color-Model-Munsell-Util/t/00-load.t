#!perl -T
use strict;
use Test::More 'no_plan';
use Color::Model::Munsell;

BEGIN {
    use_ok( 'Color::Model::Munsell::Util', qw(huedegree calc_Yc Munsell2xyY Munsell2XYZ Munsell2XYZD65 Munsell2rgb Munsell2RGB) ) || print "Bail out!
";
}

diag( "Testing Color::Model::Munsell::Util $Color::Model::Munsell::Util::VERSION, Perl $], $^X" );


my $m = Color::Model::Munsell->new("5.5R 4.5/14");
ok( huedegree($m->hue) == 5.5,          "huedegree()" );
ok( sprintf("%.1f",calc_Yc($m->value)) == 15.2,"calc_Yc() = ".calc_Yc($m->value)   );
ok( Munsell2xyY($m),                    "Munsell2xyY()" );
ok( Munsell2XYZ($m),                    "Munsell2XYZ()" );
ok( Munsell2XYZD65($m),                 "Munsell2XYZD65()" );
ok( Munsell2rgb($m),                    "Munsell2rgb()" );
ok( Munsell2RGB($m),                    "Munsell2RGB()" );


