=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<Data::ZPath::Node>.

=cut

use Test2::V0 -target => 'Data::ZPath::Node';
use Test2::Tools::Spec;

my $HAS_XML = eval {
	require XML::LibXML;
	1;
};

describe "class `$CLASS`" => sub {

	tests 'method `from_root`' => sub {
		my $node = Data::ZPath::Node->from_root( { foo => 1 } );
		ok( $node->isa('Data::ZPath::Node'), 'constructed node object' );
	};

	tests 'method `attributes`' => sub {
		skip_all 'XML::LibXML not available' unless $HAS_XML;
		my $doc = XML::LibXML->load_xml( string => '<r a="x" b="y" />' );
		my $node = Data::ZPath::Node->from_root($doc);
		my @attrs = $node->attributes;
		is( scalar @attrs, 2, 'attributes returns XML attributes' );

		my $perl = Data::ZPath::Node->from_root( { foo => 1 } );
		is( scalar $perl->attributes, U(), 'non-XML node has no attributes' );
	};

	tests 'method `children`' => sub {
		my $hash_node = Data::ZPath::Node->from_root( {
			alpha => 1,
			beta  => 2,
		} );
		my @hash_children = $hash_node->children;
		is( scalar @hash_children, 2, 'hash produced two children' );

		my $array_node = Data::ZPath::Node->from_root( [ 10, 20 ] );
		my @array_children = $array_node->children;
		is( scalar @array_children, 2, 'array produced two children' );

		if ( $HAS_XML ) {
			my $doc = XML::LibXML->load_xml(
				string => '<r>  <c>hi</c><!--note--></r>',
			);
			local $Data::ZPath::XmlIgnoreWS = 1;
			my $xml_node = Data::ZPath::Node->from_root($doc);
			my @xml_children = $xml_node->children;
			ok( scalar @xml_children >= 2,
				'xml children include element and comment' );
		}
	};

	tests 'method `dump`' => sub {
		my $node = Data::ZPath::Node->from_root( { foo => 1 } );
		my $dump = $node->dump;
		is( $dump->{'@type'}, 'map', 'dump includes type' );
		ok( exists $dump->{children}, 'dump includes children' );
	};

	tests 'method `find`' => sub {
		my $node = Data::ZPath::Node->from_root( { foo => 10 } );
		is( $node->find('foo')->first->value, 10, 'find works' );
	};

	tests 'method `id`' => sub {
		my $node = Data::ZPath::Node->from_root( { foo => 1 } );
		ok( defined $node->id, 'reference root has stable id' );
	};

	tests 'method `index`' => sub {
		my $node = Data::ZPath::Node->from_root( [ 10, 20 ] );
		my ($child) = $node->children;
		is( $child->index, 0, 'index returns child index' );
	};

	tests 'method `ix`' => sub {
		my $node = Data::ZPath::Node->from_root( [ 10, 20 ] );
		my ($child) = $node->children;
		is( $child->ix, 0, 'ix returns child index' );
	};

	tests 'method `key`' => sub {
		my $node = Data::ZPath::Node->from_root( { foo => 1 } );
		my ($child) = $node->children;
		is( $child->key, 'foo', 'key returns hash key' );
	};

	tests 'method `name`' => sub {
		my $node = Data::ZPath::Node->from_root( { foo => 1 } );
		my ($child) = $node->children;
		is( $child->name, 'foo', 'name falls back to key for Perl values' );

		if ( $HAS_XML ) {
			my $doc = XML::LibXML->load_xml( string => '<r a="x" />' );
			my $el = Data::ZPath::Node->from_root($doc);
			is( $el->name, 'r', 'name returns element name for XML' );
		}
	};

	tests 'method `number_value`' => sub {
		my $num = Data::ZPath::Node->from_root(42);
		is( $num->number_value, 42, 'number value numericifies number' );

		my $str = Data::ZPath::Node->from_root('forty-two');
		is( $str->number_value, U(), 'non-numeric yields undef' );

		local $Data::ZPath::UseBigInt = 1;
		my $big = Data::ZPath::Node->from_root('12345678901234567890');
		ok( $big->number_value->isa('Math::BigInt'),
			'large integer upgraded to Math::BigInt' );
	};

	tests 'method `parent`' => sub {
		my $root = Data::ZPath::Node->from_root( { foo => 1 } );
		is( $root->parent, U(), 'root parent is undef' );

		my ($child) = $root->children;
		is( $child->parent, $root, 'child parent set' );
	};

	tests 'method `primitive_value`' => sub {
		my $num = Data::ZPath::Node->from_root(42);
		is( $num->primitive_value, 42, 'primitive value returns scalar' );

		my $bool = Data::ZPath::Node->from_root( \1 );
		is( $bool->primitive_value, T(), 'primitive normalizes bool true' );
	};

	tests 'method `raw`' => sub {
		my $node = Data::ZPath::Node->from_root( { foo => 1 } );
		is( $node->raw->{foo}, 1, 'raw returns wrapped data' );
	};

	tests 'method `slot`' => sub {
		my $node = Data::ZPath::Node->from_root( { foo => 10 } );
		my ($child) = $node->children;
		ok( $child->slot, 'slot available for primitive Perl scalar' );
		$child->slot->(33);
		is( $node->raw->{foo}, 33, 'slot mutates source value' );
	};

	tests 'method `string_value`' => sub {
		my $num = Data::ZPath::Node->from_root(42);
		is( $num->string_value, '42', 'string value stringifies primitive' );

		my $undef = Data::ZPath::Node->from_root(undef);
		is( $undef->string_value, U(), 'undef stays undef' );
	};

	tests 'method `type`' => sub {
		my $num = Data::ZPath::Node->from_root(42);
		is( $num->type, 'number', 'number type recognized' );

		my $str = Data::ZPath::Node->from_root('forty-two');
		is( $str->type, 'string', 'string type recognized' );

		my $bool = Data::ZPath::Node->from_root( \1 );
		is( $bool->type, 'boolean', 'boolean type recognized' );
	};

	tests 'method `value`' => sub {
		my $num = Data::ZPath::Node->from_root(42);
		is( $num->value, 42, 'value returns scalar' );

		my $bool = Data::ZPath::Node->from_root( \1 );
		is( $bool->value, T(), 'value normalizes bool true' );
	};

	tests 'method `with_slot`' => sub {
		my $node = Data::ZPath::Node->from_root( { foo => 10 } );
		my ($child) = $node->children;
		my $fake_slot = sub { 99 };

		is( $child->with_slot($fake_slot), $child,
			'with_slot returns node object' );
		is( $child->slot, $fake_slot, 'with_slot replaces slot' );
	};
};

done_testing;
