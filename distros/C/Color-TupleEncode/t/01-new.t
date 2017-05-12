#!perl -T

use Test::More qw(no_plan);

BEGIN {
    use_ok( 'Color::TupleEncode' ) || print "Bail out!";
    use_ok( 'Color::TupleEncode',qw(:all) ) || print "Bail out!";
}

isa_ok(Color::TupleEncode->new(),"Color::TupleEncode");
isa_ok(Color::TupleEncode->new()->new(),"Color::TupleEncode");
can_ok(Color::TupleEncode->new(),qw(set_tuple get_tuple as_RGB as_RGBhex as_RGB255 as_HSV));

eval {
  my $tway = Color::TupleEncode->new(1);
};

like($@,qr/must be a hash/i,"new(1)");

eval {
  my $tway = Color::TupleEncode->new(1..5);
};

like($@,qr/must be a hash/i,"new(1..5)");

eval {
  my $tway = Color::TupleEncode->new([]);
};

like($@,qr/must be a hash/i,"new([])");

eval {
  my $tway = Color::TupleEncode->new(tuple=>[]);
};

like($@,qr/wrong number of values in tuple/i,"new([])");


eval {
  my $tway = Color::TupleEncode->new(tuple=>[undef,undef,undef]);
};

like($@,qr/value at index .* is not defined/i,"new(tuple=>[undef,undef,undef])");

eval {
  my $tway = Color::TupleEncode->new(tuple=>[1,undef,undef]);
};

like($@,qr/value at index .* is not defined/i,"new(tuple=>[1,undef,undef])");

eval {
  my $tway = Color::TupleEncode->new(tuple=>[1,undef,3]);
};

like($@,qr/value at index .* is not defined/i,"new(tuple=>[1,undef,3])");

eval {
  my $tway = Color::TupleEncode->new(tuple=>[1]);
};

like($@,qr/wrong number of values in tuple/i,"new(tuple=>[1])");

eval {
  my $tway = Color::TupleEncode->new(tuple=>[1,2]);
};

like($@,qr/wrong number of values in tuple/i,"new(tuple=>[1,2])");

eval {
  my $tway = Color::TupleEncode->new(tuple=>[1..4]);
};

like($@,qr/wrong number of values in tuple/i,"new(tuple=>[1..4])");

eval {
  my $tway = Color::TupleEncode->new(tuple=>[1..3]);
};

is($@,"","new(tuple=>[1..3])");

isa_ok(Color::TupleEncode->new(tuple=>[+1,+2,-3]),"Color::TupleEncode");
isa_ok(Color::TupleEncode->new(tuple=>[+1.0,+2.0,-3.0]),"Color::TupleEncode");
isa_ok(Color::TupleEncode->new(tuple=>[+1.0e1,+2.0e-2,-3.0e-03]),"Color::TupleEncode");

eval {
  my $tway = Color::TupleEncode->new(tuple=>[1,2,3]);
};

is($@,"","new(tuple=>[1,2,3])");

eval {
  my $tway = Color::TupleEncode->new(tuple=>[1..3],options=>{-saturation=>1});
};

is($@,"","new(tuple=>[1..3],options=>{-saturation=>1})");

eval {
  my $tway = Color::TupleEncode->new(tuple=>[1..3],options=>{-value=>1});
};

is($@,"","new(tuple=>[1..3],options=>{-value=>1})");

eval {
  my $tway = Color::TupleEncode->new(tuple=>[1..3],options=>{-saturation=>1,-value=>1});
};

is($@,"","new(tuple=>[1..3],options->{-saturation=>1,-value=>1})");

eval {
  my $tway = Color::TupleEncode->new(tuple=>[1..3],options=>{-saturation=>1,-value=>1,-z=>1});
};

like($@,qr/does not support option/i,"new(tuple=>[1..3],options=>{-saturation=>1,-value=>1,-z=>1})");

eval {
  my $tway = Color::TupleEncode->new(options=>{-saturation=>1,-value=>1});
};

is($@,"","new(options=>{-saturation=>1,-value=>1}");

eval {
  my $tway = Color::TupleEncode->new(tuple=>[1..3],options=>{-z=>1});
};

like($@,qr/does not support option/i,"new(tuple=>[1..3],options=>{-z=>1})");

eval {
  my $tway = Color::TupleEncode->new(tuple=>["a",1,1]);
};

like($@,qr/not a number/i,"new(tuple=>['a',1,1])");

eval {
  my $tway = Color::TupleEncode->new(tup=>[1,1,1]);
};

like($@,qr/do not understand/i,"new(tup=>[1,1,1])");

eval {
  my $tway = Color::TupleEncode->new(tuple=>[1,1,1],opt=>{});
};

like($@,qr/do not understand/i,"new(tuple=>[1,1,1],opt=>{})");

my $tway = Color::TupleEncode->new();
my $method = "Color::TupleEncode::Baran";
is($tway->get_options(-method),$method,"default method $method");

$tway = Color::TupleEncode->new(method=>"Color::TupleEncode::Baran");
is($tway->get_options(-method),$method,"default method $method");

eval {
  my $tway = Color::TupleEncode->new(method=>[]);
};
like($@,qr/must be a string/i,"new(method=>[])");



