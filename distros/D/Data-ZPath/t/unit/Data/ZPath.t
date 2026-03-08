=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<Data::ZPath>.

=cut

use Test2::V0 -target => 'Data::ZPath';
use Test2::Tools::Spec;

describe "class `$CLASS`" => sub {

	tests 'method `new`' => sub {
		my $p = Data::ZPath->new('foo');
		ok( $p->isa('Data::ZPath'), 'constructed an object' );

		like(
			dies { Data::ZPath->new },
			qr/Missing expression/,
			'missing expression croaks',
		);
	};

	tests 'method `all`' => sub {
		my $p = Data::ZPath->new('foo,bar,baz');
		my $root = {
			foo => 1,
			bar => 2,
			baz => 3,
		};
		is( [ $p->all($root) ], [ 1, 2, 3 ], 'all returns all values' );
	};

	tests 'method `each`' => sub {
		my $p = Data::ZPath->new('foo');
		my $root = { foo => 3 };

		$p->each( $root, sub { $_ *= 10 } );
		is( $root->{foo}, 30, 'callback mutates matched scalar value' );

		like(
			dies { $p->each( { foo => 1 }, 'not-coderef' ) },
			qr/each\(\) requires a coderef/,
			'non-coderef callback croaks',
		);
	};

	tests 'method `evaluate`' => sub {
		my $p = Data::ZPath->new('foo,bar');
		my $root = {
			foo => 1,
			bar => 2,
		};

		my @list_ctx = $p->evaluate($root);
		is( scalar @list_ctx, 2, 'returns list of nodes in list context' );
		ok( $list_ctx[0]->isa('Data::ZPath::Node'),
			'list context elements are nodes' );

		my $scalar_ctx = $p->evaluate($root);
		ok( $scalar_ctx->isa('Data::ZPath::NodeList'),
			'returns node list object in scalar context' );
		is( [ map $_->value, $scalar_ctx->all ], [ 1, 2 ],
			'scalar context node list wraps all nodes' );

		my @vals = $p->evaluate( { foo => 7, bar => 9 }, first => 1 );
		is( scalar @vals, 1, 'first option short-circuits' );
		is( $vals[0]->value, 7, 'first value returned' );
	};

	tests 'method `first`' => sub {
		my $p = Data::ZPath->new('foo');
		is( $p->first( { foo => 1 } ), 1, 'first returns first value' );
		is( $p->first( {} ), U(), 'undef when no matches' );
	};

	tests 'method `last`' => sub {
		my $p = Data::ZPath->new('foo,bar,baz');
		my $root = {
			foo => 1,
			bar => 2,
			baz => 3,
		};
		is( $p->last($root), 3, 'last returns last value' );
	};
};

done_testing;
