use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::Community;
use Bio::Community::Member;

use_ok($_) for qw(
    Bio::Community::Alpha
);


my ($alpha, $c);


# Basic object

$c = Bio::Community->new;
$c->add_member( Bio::Community::Member->new(-id=>1), 1 );
$c->add_member( Bio::Community::Member->new(-id=>2), 2 );
$c->add_member( Bio::Community::Member->new(-id=>3), 3 );

$alpha = Bio::Community::Alpha->new( -community=>$c );
isa_ok $alpha, 'Bio::Community::Alpha';


# Get/set type of alpha diversity

is $alpha->type('observed'), 'observed';
delta_ok $alpha->get_alpha, 3.0;

is $alpha->type('menhinick'), 'menhinick';
delta_ok $alpha->get_alpha, 1.22474487139159;


# Test empty community

$c = Bio::Community->new;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'observed' )->get_alpha, 0.0, 'Empty community';
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'menhinick')->get_alpha, 0.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'margalef' )->get_alpha, 0.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'chao1'    )->get_alpha, 0.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'ace'      )->get_alpha, 0.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'jack1'    )->get_alpha, 0.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'jack2'    )->get_alpha, 0.0;

is Bio::Community::Alpha->new(-community=>$c, -type=>'buzas'      )->get_alpha, undef;
is Bio::Community::Alpha->new(-community=>$c, -type=>'heip'       )->get_alpha, undef;
is Bio::Community::Alpha->new(-community=>$c, -type=>'shannon_e'  )->get_alpha, undef;
is Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_e'  )->get_alpha, undef;
SKIP: {
test_skip(-tests => 1, -requires_module => 'Math::GSL::SF');
is Bio::Community::Alpha->new(-community=>$c, -type=>'brillouin_e')->get_alpha, undef;
}
is Bio::Community::Alpha->new(-community=>$c, -type=>'hill_e'     )->get_alpha, undef;
is Bio::Community::Alpha->new(-community=>$c, -type=>'mcintosh_e' )->get_alpha, undef;
is Bio::Community::Alpha->new(-community=>$c, -type=>'camargo'    )->get_alpha, undef;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'shannon'  )->get_alpha, 0.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson'  )->get_alpha, 0.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_r')->get_alpha, 0.0;
SKIP: {
test_skip(-tests => 1, -requires_module => 'Math::GSL::SF');
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'brillouin')->get_alpha, 0.0;
}
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'hill'     )->get_alpha, 0.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'mcintosh' )->get_alpha, 0.0;

is Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_d')->get_alpha, undef;
is Bio::Community::Alpha->new(-community=>$c, -type=>'berger'   )->get_alpha, undef;


# Test community with a single individual

$c = Bio::Community->new;
$c->add_member( Bio::Community::Member->new(-id=>1), 1);

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'observed' )->get_alpha, 1.0, 'Single-individual community';
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'menhinick')->get_alpha, 1.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'margalef' )->get_alpha, 0.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'chao1'    )->get_alpha, 1.0;
is       Bio::Community::Alpha->new(-community=>$c, -type=>'ace'      )->get_alpha, 1.0; # same as chao1
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'jack1'    )->get_alpha, 2.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'jack2'    )->get_alpha, 3.0;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'buzas'      )->get_alpha, 1.0;
is       Bio::Community::Alpha->new(-community=>$c, -type=>'heip'       )->get_alpha, undef;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'shannon_e'  )->get_alpha, 0.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_e'  )->get_alpha, 0.0;
SKIP: {
test_skip(-tests => 1, -requires_module => 'Math::GSL::SF');
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'brillouin_e')->get_alpha, 0.0;
}
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'hill_e'     )->get_alpha, 1.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'mcintosh_e' )->get_alpha, 1.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'camargo'    )->get_alpha, 1.0;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'shannon'  )->get_alpha, 0.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson'  )->get_alpha, 0.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_r')->get_alpha, 1.0;
SKIP: {
test_skip(-tests => 1, -requires_module => 'Math::GSL::SF');
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'brillouin')->get_alpha, 0.0;
}
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'hill'     )->get_alpha, 1.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'mcintosh' )->get_alpha, 0.0;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_d')->get_alpha, 1.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'berger'   )->get_alpha, 1.0;


# Test community with a few individuals from the same species

$c = Bio::Community->new;
$c->add_member( Bio::Community::Member->new(-id=>1), 3);

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'observed' )->get_alpha, 1.0, 'Few-individual community';
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'menhinick')->get_alpha, 0.5773503;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'margalef' )->get_alpha, 0.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'chao1'    )->get_alpha, 1.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'ace'      )->get_alpha, 1.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'jack1'    )->get_alpha, 1.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'jack2'    )->get_alpha, 1.0;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'buzas'      )->get_alpha, 1.0;
is       Bio::Community::Alpha->new(-community=>$c, -type=>'heip'       )->get_alpha, undef;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'shannon_e'  )->get_alpha, 0.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_e'  )->get_alpha, 0.0;
SKIP: {
test_skip(-tests => 1, -requires_module => 'Math::GSL::SF');
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'brillouin_e')->get_alpha, 0.0;
}
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'hill_e'     )->get_alpha, 1.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'mcintosh_e' )->get_alpha, 1.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'camargo'    )->get_alpha, 1.0;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'shannon'  )->get_alpha, 0.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson'  )->get_alpha, 0.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_r')->get_alpha, 1.0;
SKIP: {
test_skip(-tests => 1, -requires_module => 'Math::GSL::SF');
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'brillouin')->get_alpha, 0.0;
}
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'hill'     )->get_alpha, 1.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'mcintosh' )->get_alpha, 0.0;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_d')->get_alpha, 1.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'berger'   )->get_alpha, 1.0;


# Test community with a many individuals from the same species

$c = Bio::Community->new;
$c->add_member( Bio::Community::Member->new(-id=>1), 35 );

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'observed' )->get_alpha, 1.0, 'Single-species community';
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'menhinick')->get_alpha, 0.1690309;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'margalef' )->get_alpha, 0.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'chao1'    )->get_alpha, 1.0;
is       Bio::Community::Alpha->new(-community=>$c, -type=>'ace'      )->get_alpha, 1.0; # same as chao1
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'jack1'    )->get_alpha, 1.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'jack2'    )->get_alpha, 1.0;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'buzas'      )->get_alpha, 1.0;
is       Bio::Community::Alpha->new(-community=>$c, -type=>'heip'       )->get_alpha, undef;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'shannon_e'  )->get_alpha, 0.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_e'  )->get_alpha, 0.0;
SKIP: {
test_skip(-tests => 1, -requires_module => 'Math::GSL::SF');
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'brillouin_e')->get_alpha, 0.0;
}
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'hill_e'     )->get_alpha, 1.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'mcintosh_e' )->get_alpha, 1.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'camargo'    )->get_alpha, 1.0;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'shannon'  )->get_alpha, 0.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson'  )->get_alpha, 0.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_r')->get_alpha, 1.0;
SKIP: {
test_skip(-tests => 1, -requires_module => 'Math::GSL::SF');
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'brillouin')->get_alpha, 0.0;
}
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'hill'     )->get_alpha, 1.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'mcintosh' )->get_alpha, 0.0;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_d')->get_alpha, 1.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'berger'   )->get_alpha, 1.0;


# Test community with 2 species

$c = Bio::Community->new;
$c->add_member( Bio::Community::Member->new(-id=>1), 4 );
$c->add_member( Bio::Community::Member->new(-id=>2), 25 );

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'observed' )->get_alpha, 2.0, '2-species community';
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'menhinick')->get_alpha, 0.3713907;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'margalef' )->get_alpha, 0.2969742;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'chao1'    )->get_alpha, 2.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'ace'      )->get_alpha, 2.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'jack1'    )->get_alpha, 2.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'jack2'    )->get_alpha, 2.0;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'buzas'      )->get_alpha, 0.7468004;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'heip'       )->get_alpha, 0.4936008;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'shannon_e'  )->get_alpha, 0.5787946;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_e'  )->get_alpha, 0.4756243;
SKIP: {
test_skip(-tests => 1, -requires_module => 'Math::GSL::SF');
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'brillouin_e')->get_alpha, 0.5615533;
}
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'hill_e'     )->get_alpha, 0.8784224;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'mcintosh_e' )->get_alpha, 0.9036374;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'camargo'    )->get_alpha, 0.6379310;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'shannon'  )->get_alpha, 0.4011899;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson'  )->get_alpha, 0.2378121;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_r')->get_alpha, 1.3120125;
SKIP: {
test_skip(-tests => 1, -requires_module => 'Math::GSL::SF');
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'brillouin')->get_alpha, 0.3901122;
}
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'hill'     )->get_alpha, 1.1600000;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'mcintosh' )->get_alpha, 0.1559199;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_d')->get_alpha, 0.7621879;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'berger'   )->get_alpha, 0.8620690;


# Test community with 3 species

$c = Bio::Community->new;
$c->add_member( Bio::Community::Member->new(-id=>1), 1 );
$c->add_member( Bio::Community::Member->new(-id=>2), 2 );
$c->add_member( Bio::Community::Member->new(-id=>3), 3 );

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'observed' )->get_alpha, 3.0, '3-species community';
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'menhinick')->get_alpha, 1.22474487139159;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'margalef' )->get_alpha, 1.11622125310249;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'chao1'    )->get_alpha, 3.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'ace'      )->get_alpha, 3.6;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'jack1'    )->get_alpha, 4.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'jack2'    )->get_alpha, 4.0;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'buzas'      )->get_alpha, 0.916486424665735;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'heip'       )->get_alpha, 0.874729636998600;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'shannon_e'  )->get_alpha, 0.920619835714305;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_e'  )->get_alpha, 0.916666666666667;
SKIP: {
test_skip(-tests => 1, -requires_module => 'Math::GSL::SF');
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'brillouin_e')->get_alpha, 0.8552170;
}
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'hill_e'     )->get_alpha, 0.935248830832905;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'mcintosh_e' )->get_alpha, 0.881917103688197;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'camargo'    )->get_alpha, 0.777777777777778;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'shannon'  )->get_alpha, 1.01140426470735;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson'  )->get_alpha, 0.611111111111111;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_r')->get_alpha, 2.57142857142857;
SKIP: {
test_skip(-tests => 1, -requires_module => 'Math::GSL::SF');
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'brillouin')->get_alpha, 0.682390760370350;
}
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'hill'     )->get_alpha, 2.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'mcintosh' )->get_alpha, 0.636061424871458;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_d')->get_alpha, 0.388888888888889;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'berger'   )->get_alpha, 0.5;


# Test community with 4 species

$c = Bio::Community->new;
$c->add_member( Bio::Community::Member->new(-id=>1), 1  );
$c->add_member( Bio::Community::Member->new(-id=>2), 2  );
$c->add_member( Bio::Community::Member->new(-id=>3), 11 );
$c->add_member( Bio::Community::Member->new(-id=>4), 1  );

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'observed' )->get_alpha, 4.0, '4-species community';
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'menhinick')->get_alpha, 1.0327956;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'margalef' )->get_alpha, 1.1078081;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'chao1'    )->get_alpha, 4.5;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'ace'      )->get_alpha, 7.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'jack1'    )->get_alpha, 6.0;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'jack2'    )->get_alpha, 7.0;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'buzas'      )->get_alpha, 0.5891230;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'heip'       )->get_alpha, 0.4521640;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'shannon_e'  )->get_alpha, 0.6183204;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_e'  )->get_alpha, 0.5807407;
SKIP: {
test_skip(-tests => 1, -requires_module => 'Math::GSL::SF');
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'brillouin_e')->get_alpha, 0.5274756;
}
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'hill_e'     )->get_alpha, 0.7518182;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'mcintosh_e' )->get_alpha, 0.9294867;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'camargo'    )->get_alpha, 0.4833333;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'shannon'  )->get_alpha, 0.8571740;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson'  )->get_alpha, 0.4355556;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_r')->get_alpha, 1.7716535;
SKIP: {
test_skip(-tests => 1, -requires_module => 'Math::GSL::SF');
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'brillouin')->get_alpha, 0.6724539;
}
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'hill'     )->get_alpha, 1.3636364;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'mcintosh' )->get_alpha, 0.3352716;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_d')->get_alpha, 0.5644444;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'berger'   )->get_alpha, 0.7333333;


# Test community with decimals

$c = Bio::Community->new;
$c->add_member( Bio::Community::Member->new(-id=>1), 0.3  );
$c->add_member( Bio::Community::Member->new(-id=>2), 2.2  );
$c->add_member( Bio::Community::Member->new(-id=>3), 11.7 );
$c->add_member( Bio::Community::Member->new(-id=>4), 1.4  );

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'observed' )->get_alpha, 4.0, 'Decimals';
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'menhinick')->get_alpha, 1.0127394;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'margalef' )->get_alpha, 1.0919928;
throws_ok { Bio::Community::Alpha->new(-community=>$c, -type=>'chao1' )->get_alpha} qr/EXCEPTION.*integer/msi;
throws_ok { Bio::Community::Alpha->new(-community=>$c, -type=>'ace'   )->get_alpha} qr/EXCEPTION.*integer/msi;
throws_ok { Bio::Community::Alpha->new(-community=>$c, -type=>'jack1' )->get_alpha} qr/EXCEPTION.*integer/msi;
throws_ok { Bio::Community::Alpha->new(-community=>$c, -type=>'jack2' )->get_alpha} qr/EXCEPTION.*integer/msi;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'buzas'      )->get_alpha, 0.5477421;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'heip'       )->get_alpha, 0.3969895;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'shannon_e'  )->get_alpha, 0.5657844;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_e'  )->get_alpha, 0.5455840;
SKIP: {
test_skip(-tests => 1, -requires_module => 'Math::GSL::SF');
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'brillouin_e')->get_alpha, 0.4462784;
}
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'hill_e'     )->get_alpha, 0.7725286;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'mcintosh_e' )->get_alpha, 0.9427872;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'camargo'    )->get_alpha, 0.4391026;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'shannon'  )->get_alpha, 0.7843437;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson'  )->get_alpha, 0.4091880;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_r')->get_alpha, 1.6925859;
SKIP: {
test_skip(-tests => 1, -requires_module => 'Math::GSL::SF');
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'brillouin')->get_alpha, 0.5744541;
}
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'hill'     )->get_alpha, 1.3333333;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'mcintosh' )->get_alpha, 0.3097916;

delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'simpson_d')->get_alpha, 0.5908120;
delta_ok Bio::Community::Alpha->new(-community=>$c, -type=>'berger'   )->get_alpha, 0.7500000;



done_testing();

exit;
