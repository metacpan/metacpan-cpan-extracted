use strict;
use warnings;
use Test::More;

BEGIN {
	eval { require Moose }
		or plan skip_all => 'need Moose';
	plan tests => 4;
}

use Acme::Constructor::Pythonic
	'Moose::Meta::Class' => {
		constructor    => 'create_anon_class',
		alias          => 'AnonClass',
	},
	'Moose::Meta::Role' => {
		constructor    => 'create_anon_role',
		alias          => 'AnonRole',
	},
;

my $person_class = AnonClass(
	superclasses => [ 'Moose::Object' ],
);
my $singing_role = AnonRole(
	methods      => { sing => sub { "lalala!" } },
);
my $singer_class = AnonClass(
	superclasses => [ $person_class->name ],
	roles        => [ $singing_role->name ],
);

Acme::Constructor::Pythonic->import(
	$singer_class->name => {
		alias      => 'Singer',
		no_require => 1,
	},
);

my $sinatra = Singer();

ok( $sinatra->isa($person_class->name) );
ok( $sinatra->does($singing_role->name) );
ok( $sinatra->isa($singer_class->name) );

is($sinatra->sing, 'lalala!');
