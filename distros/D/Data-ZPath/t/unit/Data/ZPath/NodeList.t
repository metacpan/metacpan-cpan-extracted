=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<Data::ZPath::NodeList>.

=cut

use Test2::V0 -target => 'Data::ZPath::NodeList';
use Test2::Tools::Spec;

use Data::ZPath::Node;

describe "class `$CLASS`" => sub {

	tests 'method `new`' => sub {
		my $node1 = Data::ZPath::Node->from_root('a');
		my $node2 = Data::ZPath::Node->from_root('b');
		my $list = Data::ZPath::NodeList->new( $node1, $node2 );
		ok( $list->isa('Data::ZPath::NodeList'), 'constructed node list object' );
	};

	tests 'method `all`' => sub {
		my $node1 = Data::ZPath::Node->from_root('a');
		my $node2 = Data::ZPath::Node->from_root('b');
		my $node3 = Data::ZPath::Node->from_root('c');
		my $list = Data::ZPath::NodeList->new( $node1, $node2, $node3 );

		is( [ $list->all ], [ $node1, $node2, $node3 ],
			'all returns every node' );
		is( [ Data::ZPath::NodeList->new->all ], [], 'all on empty list is empty' );
	};

	tests 'method `find`' => sub {
		my $node = Data::ZPath::Node->from_root( { foo => 10 } );
		my $list = Data::ZPath::NodeList->new( $node );
		is( $list->find('foo')->first->value, 10, 'find works' );
	};

	tests 'method `first`' => sub {
		my $node1 = Data::ZPath::Node->from_root('a');
		my $node2 = Data::ZPath::Node->from_root('b');
		my $list = Data::ZPath::NodeList->new( $node1, $node2 );

		is( $list->first, $node1, 'first returns first node' );
		is( Data::ZPath::NodeList->new->first, U(), 'first on empty list is undef' );
	};

	tests 'method `grep`' => sub {
		my $node1 = Data::ZPath::Node->from_root('a');
		my $node2 = Data::ZPath::Node->from_root('b');
		my $node3 = Data::ZPath::Node->from_root('c');
		my $list = Data::ZPath::NodeList->new( $node1, $node2, $node3 );

		is( [ $list->grep(sub { $_ eq 'b' })->all ], [ $node2 ],
			'grep filters the list' );
	};

	tests 'method `last`' => sub {
		my $node1 = Data::ZPath::Node->from_root('a');
		my $node2 = Data::ZPath::Node->from_root('b');
		my $list = Data::ZPath::NodeList->new( $node1, $node2 );

		is( $list->last, $node2, 'last returns last node' );
		is( Data::ZPath::NodeList->new->last, U(), 'last on empty list is undef' );
	};

	tests 'method `map`' => sub {
		my $node1 = Data::ZPath::Node->from_root('a');
		my $node2 = Data::ZPath::Node->from_root('b');
		my $node3 = Data::ZPath::Node->from_root('c');
		my $list = Data::ZPath::NodeList->new( $node1, $node2, $node3 );

		is( [ $list->map(sub { uc $_ })->values ], [ qw/ A B C / ],
			'map transforms the list' );
	};

	tests 'method `values`' => sub {
		my $node1 = Data::ZPath::Node->from_root('a');
		my $node2 = Data::ZPath::Node->from_root('b');
		my $node3 = Data::ZPath::Node->from_root('c');
		my $list = Data::ZPath::NodeList->new( $node1, $node2, $node3 );

		is( [ $list->values ], [ qw/ a b c / ],
			'values returns every node, but as raw values' );
	};
};

done_testing;
