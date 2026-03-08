=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<Data::ZPath::_Ctx>.

=cut

use Test2::V0 -target => 'Data::ZPath::_Ctx';
use Test2::Tools::Spec;

use Data::ZPath::Node;

describe "class `$CLASS`" => sub {

	tests 'method `new`' => sub {
		my $ctx = Data::ZPath::_Ctx->new( { foo => 1 } );
		ok( $ctx->root->isa('Data::ZPath::Node'), 'root node wrapper created' );

		my $node = Data::ZPath::Node->from_root('x');
		my $ctx2 = Data::ZPath::_Ctx->new($node);
		is( $ctx2->root, $node, 'existing node reused' );
	};

	tests 'method `nodeset`' => sub {
		my $ctx = Data::ZPath::_Ctx->new( { foo => 1 } );
		is( $ctx->nodeset, [ $ctx->root ], 'nodeset initialized to root set' );
	};

	tests 'method `parentset`' => sub {
		my $ctx = Data::ZPath::_Ctx->new( { foo => 1 } );
		is( $ctx->parentset, U(), 'parentset starts undef' );
	};

	tests 'method `root`' => sub {
		my $ctx = Data::ZPath::_Ctx->new( { foo => 1 } );
		ok( $ctx->root->isa('Data::ZPath::Node'), 'root returns node object' );
	};

	tests 'method `with_nodeset`' => sub {
		my $ctx = Data::ZPath::_Ctx->new( { foo => 1 } );
		my $n = Data::ZPath::Node->from_root('child');
		my $next = $ctx->with_nodeset( [ $n ], [ $ctx->root ] );

		is( $next->nodeset, [ $n ], 'nodeset replaced' );
		is( $next->parentset, [ $ctx->root ], 'parentset replaced' );
		is( $next->root, $ctx->root, 'root preserved' );
		ok( $next != $ctx, 'new context instance returned' );
	};
};

done_testing;
