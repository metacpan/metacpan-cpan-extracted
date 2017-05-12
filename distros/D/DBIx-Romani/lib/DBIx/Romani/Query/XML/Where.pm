
package DBIx::Romani::Query::XML::Where;

use DBIx::Romani::Query::XML::Util;
use DBIx::Romani::Query::XML::SQL;
use DBIx::Romani::Query::Comparison;
use DBIx::Romani::Query::Where;
use XML::DOM;
use strict;

use Data::Dumper;

sub create_where_from_node
{
	my $op_node = shift;

	my $name   = $op_node->getLocalName();
	my $ns_uri = $op_node->getNamespaceURI();

	my $op;

	# create the actual object
	if ( $ns_uri eq $DBIx::Romani::Query::XML::Util::NS_QUERY_OPERATOR )
	{
		if ( $name eq 'and' )
		{
			$op = DBIx::Romani::Query::Where->new( $DBIx::Romani::Query::Where::AND );
		}
		elsif ( $name eq 'equal' )
		{
			$op = DBIx::Romani::Query::Comparison->new( $DBIx::Romani::Query::Comparison::EQUAL );
		}
	}

	if ( not defined $op )
	{
		die "Unknown operator \"$ns_uri\" \"$name\"";
	}

	# go through the children
	my $node = $op_node->getFirstChild();
	while ( defined $node )
	{
		if ( $node->getNodeType() == XML::DOM::ELEMENT_NODE )
		{
			# operators can hold other things regarded as where
			$op->add( DBIx::Romani::Query::XML::SQL::create_where_from_node($node) );
		}

		$node = $node->getNextSibling();
	}

	return $op;
}

1;

