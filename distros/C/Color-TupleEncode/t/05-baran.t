#!perl -T

use Test::More qw(no_plan);

BEGIN {
    use_ok( 'Color::TupleEncode', qw(:all) ) || print "Bail out!";
    use_ok( 'Color::TupleEncode::Baran' )    || print "Bail out!";
}

my @data = (
	    [1.0,1.0,1.0],[255,255,255],
	    [0.3,0.3,0.3],[255,255,255],
	    [0.1,0.1,0.1],[255,255,255],
	    [0.0,0.0,0.0],[255,255,255],

	    [1.0,0.0,0.0],[255,  0,  0],
	    [1.0,0.2,0.2],[255, 51, 51],
	    [0.9,1.0,1.0],[255,229,230],
	    [0.5,1.0,1.0],[255,127,127],
	    [0.2,1.0,1.0],[255, 51, 51],
	    [0.1,1.0,1.0],[255, 25, 25],
	    [0.5,1.0,1.0],[255,127,127],
	    [0.4,0.2,0.2],[255,204,204],

	    [0.0,1.0,0.0],[  0,255,  0],
	    [1.0,0.0,1.0],[  0,255,  0],
	    [0.2,0.5,0.2],[179,255,178],
	    [1.0,0.4,1.0],[102,255,102],
	    
	    [0.0,0.0,1.0],[  0,  0,255],
	    [0.9,0.9,0.1],[ 51, 51,255],

	    [0.3,0.9,0.6],[255,255,102],
	    [1.0,0.0,0.5],[255,255,  0],
	    [0.1,0.5,0.3],[255,255,153],
	    [1.0,0.6,0.8],[255,255,153],

	    [0.8,0.9,1.0],[255,204,255],
	    [0.0,0.5,1.0],[255,  0,255],
	    [0.2,0.5,0.8],[255,102,255],
	    [0.8,0.5,0.2],[255,102,255],
	    [0.6,0.3,0.0],[255,102,255],
	    [1.0,0.9,0.9],[255,229,230],
	    [0.0,0.1,0.2],[255,204,255],

	    [0.4,0.2,0.5],[179,255,230],
	    [0.5,1.0,0.0],[  0,255,255],
	    [0.1,0.0,0.2],[204,255,255],
	    [0.8,1.0,0.6],[153,255,255],

	    [0.0,0.8,0.6],[255,153, 51],
	    [0.0,1.0,0.3],[153,255,  0],
	    [1.0,0.8,0.0],[102,  0,255],
	   );

my $tway = Color::TupleEncode->new();

$tway->set_options(-method=>"Color::TupleEncode::Baran");
is($tway->get_options(-method),"Color::TupleEncode::Baran","default -method");

is($tway->get_tuple_size,3,"tuple size 3");

$tway->set_options(-saturation=>1);
is($tway->get_options(-saturation),1,"get_options(-saturation)");

$tway->set_options(-saturation=>2,-value=>1);
is($tway->get_options(-saturation),2,"get_options(-saturation)");
is($tway->get_options(-value),1,"get_options(-value)");
is(join(",",$tway->get_options(qw(-saturation -value))),"2,1","get_options(-saturation -value)");

$tway = Color::TupleEncode->new(options=>{-saturation=>3});
is($tway->get_options(qw(-value)),undef,"new(-saturation=>3)");

$tway = Color::TupleEncode->new();
is($tway->get_options(-ha),0,"get_options(-ha)");
is($tway->get_options(-hb),120,"get_options(-hb)");
is($tway->get_options(-hc),240,"get_options(-hc)");

is({$tway->get_options()}->{-ha},0,"get_options()");
is({$tway->get_options()}->{-hb},120,"get_options()");
is({$tway->get_options()}->{-hc},240,"get_options()");

$tway->set_options(-ha=>60,-hb=>180,-hc=>300);
is($tway->get_options(-ha),60,"get_options(-ha)");
is($tway->get_options(-hb),180,"get_options(-hb)");
is($tway->get_options(-hc),300,"get_options(-hc)");

$tway = Color::TupleEncode->new(options=>{-saturation=>{dmin=>0,dmax=>1}});

while (my ($data,$expected) = splice(@data,0,2)) {
  $tway->set_tuple($data);
  my @hsv = $tway->as_HSV();
  my @rgb255 = $tway->as_RGB255();
  my $rgbhex = $tway->as_RGBhex();
  0&&diag(sprintf("as_HSV( %.1f , %.1f , %.1f)",$tway->get_tuple),
       " ",
       sprintf("%5.2f %4.2f %5.1f",@hsv),
       " ",
       sprintf("%5.1f %5.1f %5.1f",@rgb255),
       " ",
       sprintf("%5.1f %5.1f %5.1f",@$expected),
	  " ",
	  $rgbhex);
  is(join(",",@rgb255),
     join(",",@$expected),
     sprintf("as_HSV(%f,%f,%f)",@$data));
  is(join(",",tuple_asRGB255(tuple=>$data,options=>{$tway->get_options()})),
     join(",",@$expected),
     sprintf("as_HSV(%f,%f,%f)",@$data));
}


