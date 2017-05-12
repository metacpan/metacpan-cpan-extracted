#!perl -T

use Test::More qw(no_plan);

BEGIN {
    use_ok( 'Color::TupleEncode', qw(:all) ) || print "Bail out!";
    use_ok( 'Color::TupleEncode::2Way' )     || print "Bail out!";
}

my @data = (

	    [qw(  0  0 ) ],[qw(   0 1    1    )],
	    [qw(  0  1 ) ],[qw(   0 0.5  1    )],
	    [qw(  0  2 ) ],[qw(   0 0.25 0.71 )],
	    [qw(  0  3 ) ],[qw(   0 0.12 0.5  )],
	    [qw(  0  4 ) ],[qw(   0 0.06 0.35 )],

	    [qw(  1  0   ) ],[qw( 0 0.50 1.00 )],
	    [qw(  2  0   ) ],[qw( 0 0.25 0.71 )],
	    [qw(  3  0   ) ],[qw( 0 0.12 0.5 )],
	    [qw(  4  0   ) ],[qw( 0 0.06 0.35 )],

	    [qw(  1  1   ) ],[qw( 180 0.38 0.87 )],
	    [qw(  2  2   ) ],[qw( 180 0.14 0.53 )],
	    [qw(  3  3   ) ],[qw( 180 0.05 0.33 )],

	    [qw(  1  2   ) ],[qw(  90 0.21 0.65 )],
	    [qw(  1  3   ) ],[qw(  59 0.11 0.47 )],
	    [qw(  1  4   ) ],[qw(  45 0.06 0.34 )],

	   );

my $tway = Color::TupleEncode->new();

$tway->set_options(-method=>"Color::TupleEncode::2Way");

is($tway->get_options(-method),"Color::TupleEncode::2Way","default -method");

$tway->set_options(-hzero=>1);
is($tway->get_options(-hzero),1,"get_options(-hzero)");

$tway->set_options(-saturation=>{power=>2});
is($tway->get_options(-saturation)->{power},2,"get_options(-saturation)->{power}");

$tway->set_options(-value=>{power=>1});
is($tway->get_options(-value)->{power},1,"get_options(-value)->{power}");

$tway->set_options(-orientation=>-1);
is($tway->get_options(-orientation),-1,"get_options(-orientation)");

$tway = Color::TupleEncode->new(method=>"Color::TupleEncode::2Way");

is({$tway->get_options()}->{-hzero},180,"get_options()->{hzero}");

$tway->set_options(-hzero=>200,
		   -saturation=>{power=>0.5,min=>0.2,max=>0.8,rmin=>0.5},
		   -value=>{power=>1.5,min=>0.1,max=>0.9,rmin=>0.25},
		   -orientation=>-1);
is($tway->get_options(-hzero),200,"get_options(-hzero)");
is($tway->get_options(-saturation)->{power},0.5,"get_options(-saturation)->{power}");
is($tway->get_options(-saturation)->{min},0.2,"get_options(-saturation)->{min}");
is($tway->get_options(-saturation)->{max},0.8,"get_options(-saturation)->{max}");
is($tway->get_options(-saturation)->{rmin},0.5,"get_options(-saturation)->{rmin}");
is($tway->get_options(-value)->{power},1.5,"get_options(-value)->{power}");
is($tway->get_options(-value)->{min},0.1,"get_options(-value)->{min}");
is($tway->get_options(-value)->{max},0.9,"get_options(-value)->{max}");
is($tway->get_options(-value)->{rmin},0.25,"get_options(-value)->{xmin}");

is($tway->get_options(-orientation),-1,"get_options(-orientation)");

$tway = Color::TupleEncode->new(method=>"Color::TupleEncode::2Way");

while (my ($data,$expected) = splice(@data,0,2)) {
  $tway->set_tuple($data);
  my @hsv = $tway->as_HSV();
  0&&diag(sprintf("as_HSV( %.1f , %.1f)",$tway->get_tuple),
	  " ",
	  sprintf("%5.2f %.2f %5.1f",@hsv),
	  " ",
	  sprintf("%5.1f %5.1f %5.1f",@$expected));
  is(join_comps(@hsv),
     join_comps(@$expected),
     sprintf("as_HSV(%f,%f)",@$data));
  is(join_comps(tuple_asHSV(tuple=>$data,options=>{$tway->get_options()})),
     join_comps(@$expected),
     sprintf("as_HSV(%f,%f)",@$data));
}

sub join_comps {
  my @comps = @_;
  return sprintf("%d,%.2f,%.2f",@comps);
}
