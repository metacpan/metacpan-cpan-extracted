
package DBIx::Romani::Query::XML::Function;

use DBIx::Romani::Query::XML::Util;
use DBIx::Romani::Query::XML::TTT;
use DBIx::Romani::Query::XML::SQL;
use DBIx::Romani::Query::Function::Count;
use XML::DOM;
use strict;

use Data::Dumper;

sub create_function_from_node
{
	my $func_node = shift;

	my $name   = $func_node->getLocalName();
	my $ns_uri = $func_node->getNamespaceURI();

	my $func;

	if ( $ns_uri eq $DBIx::Romani::Query::XML::Util::NS_QUERY_FUNCTION )
	{
		if ( $name eq 'count' )
		{
			$func = DBIx::Romani::Query::Function::Count->new();
			$func->set_distinct( DBIx::Romani::Query::XML::Util::get_boolean( $func_node, 'distinct', 0 ) );
		}
	}

	if ( not defined $func )
	{
		die "Unknown function tag \"$ns_uri\" \"$name\"";
	}

	# add the children to the function
	my $node = $func_node->getFirstChild();
	while ( defined $node )
	{
		if ( $node->getNodeType() == XML::DOM::ELEMENT_NODE )
		{
			my $value = DBIx::Romani::Query::XML::SQL::create_value_from_node( $node );
			if ( not defined $value )
			{
				die "Function \"$name\" contains invalid value";
			}

			$func->add( $value );
		}

		$node = $node->getNextSibling();
	}

	return $func;
}

1;

