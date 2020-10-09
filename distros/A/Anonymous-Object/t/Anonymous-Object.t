use Test::More;
use strict;
use warnings;
our ( $sub, $globref );

BEGIN {
	use_ok('Anonymous::Object');
	$sub     = sub { };
	$globref = \*globref;
}
subtest 'new' => sub {
	plan tests => 7;
	ok( my $obj = Anonymous::Object->new( {} ),
		q{my $obj = Anonymous::Object->new({})}
	);
	ok( $obj = Anonymous::Object->new(), q{$obj = Anonymous::Object->new()} );
	isa_ok( $obj, 'Anonymous::Object' );
	ok( $obj = Anonymous::Object->new(
			{  meta => { 'test' => 'test' } }
		),
		q{$obj = Anonymous::Object->new({  meta => { 'test' => 'test' } })}
	);
	ok( $obj = Anonymous::Object->new( { } ),
		q{$obj = Anonymous::Object->new({})}
	);
	eval { $obj = Anonymous::Object->new( { unique => 10, meta => [] } ) };
	like(
		$@,
		qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Anonymous::Object->new({ unique => 10, meta => [] })}
	);
	eval {
		$obj = Anonymous::Object->new( { unique => 10, meta => 'curae' } );
	};
	like(
		$@,
		qr/invalid|type|constraint|greater|atleast/,
		q{$obj = Anonymous::Object->new({ unique => 10, meta => 'curae' })}
	);
};
subtest 'meta' => sub {
	plan tests => 6;
	ok( my $obj = Anonymous::Object->new( {} ),
		q{my $obj = Anonymous::Object->new({})}
	);
	can_ok( $obj, 'meta' );
	is_deeply(
		$obj->meta( { 'test' => 'test' } ),
		{ 'test' => 'test' },
		q{$obj->meta({ 'test' => 'test' })}
	);
	eval { $obj->meta( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta([])} );
	eval { $obj->meta('penthos') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->meta('penthos')} );
	is_deeply( $obj->meta, { 'test' => 'test' }, q{$obj->meta} );
};
subtest 'hash_to_object' => sub {
	plan tests => 4;
	ok( my $obj = Anonymous::Object->new( {} ),
		q{my $obj = Anonymous::Object->new({})}
	);
	can_ok( $obj, 'hash_to_object' );
	eval { $obj->hash_to_object( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->hash_to_object([])} );
	eval { $obj->hash_to_object('algea') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->hash_to_object('algea')}
	);
};
subtest 'add_new' => sub {
	plan tests => 4;
	ok( my $obj = Anonymous::Object->new( {} ),
		q{my $obj = Anonymous::Object->new({})}
	);
	can_ok( $obj, 'add_new' );
	eval { $obj->add_new( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->add_new([])} );
	eval { $obj->add_new('penthos') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->add_new('penthos')} );
};
subtest 'add_methods' => sub {
	plan tests => 4;
	ok( my $obj = Anonymous::Object->new( {} ),
		q{my $obj = Anonymous::Object->new({})}
	);
	can_ok( $obj, 'add_methods' );
	eval { $obj->add_methods( {} ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->add_methods({})} );
	eval { $obj->add_methods('penthos') };
	like(
		$@,
		qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->add_methods('penthos')}
	);
};
subtest 'add_method' => sub {
	plan tests => 4;
	ok( my $obj = Anonymous::Object->new( {} ),
		q{my $obj = Anonymous::Object->new({})}
	);
	can_ok( $obj, 'add_method' );
	eval { $obj->add_method( [] ) };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->add_method([])} );
	eval { $obj->add_method('algea') };
	like( $@, qr/invalid|value|type|constraint|greater|atleast/,
		q{$obj->add_method('algea')} );
};
subtest 'build' => sub {
	plan tests => 2;
	ok( my $obj = Anonymous::Object->new( {} ),
		q{my $obj = Anonymous::Object->new({})}
	);
	can_ok( $obj, 'build' );
};
subtest 'stringify_struct' => sub {
	plan tests => 2;
	ok( my $obj = Anonymous::Object->new( {} ),
		q{my $obj = Anonymous::Object->new({})}
	);
	can_ok( $obj, 'stringify_struct' );
};
done_testing();
