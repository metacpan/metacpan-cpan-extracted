use Test::More tests => 1+8*2+2;
use Test::Exception;

use Data::Typed::Expression;
use Data::Typed::Expression::Env;

# TODO: comment on deployment
#use Carp;
#$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

my $types = {
	vertex => {
		id => 'int',
		lon => 'double',
		lat => 'double'
	},
	arc => {
		from => 'vertex',
		to => 'vertex',
		cost => 'double',
	},
	graph => {
		v => 'vertex[]',
		a => 'arc[]'
	},
	
	'int' => undef,
	'double' => undef,
	'bool' => undef,
};

my $vars = {
	graph => 'graph',
	v => 'vertex',
	someid => 'int',
};


my $env = new_ok( Data::Typed::Expression::Env, [ $types, $vars ] );
my $t = sub {
	my $s = shift;
	my $expr = new_ok( Data::Typed::Expression, [ $s ] );
	lives_ok { $env->validate($expr) } "e := $s";
};

# 8 * 2 = 16 tests
$t->($_) for qw(
	graph
	graph.v
	graph.v[someid]
	graph.v[0]
	graph.v[0+1]
	graph.v[someid+1]
	graph.v[1+someid+1]
	graph.v[1+graph.v[graph.v[0].id-1].id]
);


my $expr = new_ok( Data::Typed::Expression, [ 'ala.ma.kota' ] );
dies_ok { $env->validate($expr) }

# jedit :mode=perl:

