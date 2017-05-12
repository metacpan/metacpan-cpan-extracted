
package DBIx::Romani::Query::XML::Select;

use DBIx::Romani::Query::XML::TTT;
use DBIx::Romani::Query::XML::SQL;
use DBIx::Romani::Query::Select;
use DBIx::Romani::Query::SQL::Column;
use XML::DOM;

use DBIx::Romani::Query::XML::Util qw/ 
	$NS_QUERY
	$NS_QUERY_OPERATOR
	get_element_text /;

use strict;

use Data::Dumper;

# NOTE: we do our best to ignore tags that aren't in our namespace so
# that the possibility to annotate with other tags is available.

sub create_result_from_node
{
	my $result_node = shift;

	my $name   = $result_node->getLocalName();
	my $ns_uri = $result_node->getNamespaceURI();

	my $alias_name;
	my $result;
	
	if ( $ns_uri eq $NS_QUERY )
	{
		if ( $name eq 'column' )
		{
			$alias_name = $result_node->getAttribute('as') || undef;
			
			my $args = {
				table => $result_node->getAttribute('table') || undef,
				name  => DBIx::Romani::Query::XML::Util::get_text ( $result_node )
			};
			$result = DBIx::Romani::Query::SQL::Column->new( $args );
		}
		elsif ( $name eq 'expr' )
		{
			# attempt to read all the elements from the node
			my @elements;
			my $node = $result_node->getFirstChild();
			while ( defined $node )
			{
				if ( $node->getNodeType() == XML::DOM::ELEMENT_NODE )
				{
					push @elements, $node;
				}
				$node = $node->getNextSibling();
			}

			if ( scalar @elements == 1 )
			{
				my $node = $elements[0];

				$result     = DBIx::Romani::Query::XML::SQL::create_value_from_node($node);
				$alias_name = $result_node->getAttribute('as') || undef;
			}
			else
			{
				die "Must have exactly one child element in the <expr/> tag";
			}
		}
	}

	if ( not defined $result )
	{
		die "Unknown result tag: ns:\"$ns_uri\" \"$name\"";
	}

	return { value => $result, as => $alias_name };
}

# TODO: There is a lot of copy-paste ugly DOM blocks used to implement common idioms
# in our XML format.  Refactor, and move these into functios in Util.pm, so that this
# code is more sane, and this can be reused for other types of queries.
sub create_select_from_node
{
	my $select_node = shift;

	# check that we really have a select node.
	# NOTE: we only really need to do this because it can be used as a root tag
	# so there is no calling function to check it first...
	if ( $select_node->getNamespaceURI() ne $NS_QUERY or
	     $select_node->getLocalName() ne 'select' )
	{
		die sprintf "Not a valid select node: \"%s:%s\"", $select_node->getNamespaceURI, $select_node->getTagName();
	}

	# Let's get this party started ...
	my $select = DBIx::Romani::Query::Select->new();

	# do the short form
	if ( $select_node->getAttributeNode('from') )
	{
		$select->add_from( $select_node->getAttribute('from') );
	}

	my $section_node = $select_node->getFirstChild();
	while ( defined $section_node )
	{
		if ( $section_node->getNodeType() == XML::DOM::ELEMENT_NODE and
		     $section_node->getNamespaceURI() eq $NS_QUERY )
		{
			my $section_name = $section_node->getLocalName();

			if ( $section_name eq 'from' )
			{
				if ( scalar @{$select->get_from()} > 0 )
				{
					die "Cannot have multiple <from/> sections or use both the long and short form 'from'";
				}

				# add all the table froms
				my $node = $section_node->getFirstChild();
				while ( defined $node )
				{
					if ( $node->getNodeType() == XML::DOM::ELEMENT_NODE and
					     $node->getNamespaceURI() eq $NS_QUERY )
					{
						if ( $node->getLocalName() eq 'table' )
						{
							$select->add_from( get_element_text($node) );
						}
						else
						{
							die sprintf "Invalid tag \"%s\" in <from/>", $node->getTagName();
						}
					}

					$node = $node->getNextSibling();
				}
			}
			elsif ( $section_name eq 'result' )
			{
				if ( scalar @{$select->get_result()} > 0 )
				{
					die "Cannot have multiple <result/> sections in a <select/> query";
				}

				# add all the result columns
				my $node = $section_node->getFirstChild();
				while ( defined $node )
				{
					if ( $node->getNodeType() == XML::DOM::ELEMENT_NODE and
					     $node->getNamespaceURI() eq $NS_QUERY )
					{
						$select->add_result( create_result_from_node( $node ) );
					}
					$node = $node->getNextSibling();
				}
			}
			elsif ( $section_name eq 'where' )
			{
				if ( defined $select->get_where() )
				{
					die "Cannot have multiple <where/> sections in a <select/> query";
				}

				my @op_nodes;

				my $node = $section_node->getFirstChild();
				while ( defined $node )
				{
					if ( $node->getNodeType() == XML::DOM::ELEMENT_NODE and
					   ( $node->getNamespaceURI() eq $NS_QUERY or 
						 $node->getNamespaceURI() eq $NS_QUERY_OPERATOR ) )
					{
						push @op_nodes, $node;
					}
					$node = $node->getNextSibling();
				}

				if ( scalar @op_nodes == 1 )
				{
					my $where = DBIx::Romani::Query::XML::SQL::create_where_from_node( $op_nodes[0] );
					$select->set_where( $where );
				}
				else
				{
					die "The <where/> section can only have one child.";
				}
			}
			elsif ( $section_name eq 'join' )
			{
				if ( defined $select->get_join() )
				{
					die "Cannot have more than one <join/> section in a <select/> query";
				}

				my @op_nodes;

				my $node = $section_node->getFirstChild();
				while ( defined $node )
				{
					if ( $node->getNodeType() == XML::DOM::ELEMENT_NODE and
					   ( $node->getNamespaceURI() eq $NS_QUERY or 
						 $node->getNamespaceURI() eq $NS_QUERY_OPERATOR ) )
					{
						push @op_nodes, $node;
					}
					$node = $node->getNextSibling();
				}

				if ( scalar @op_nodes == 1 )
				{
					# create and set the join object
					my $args = {
						type  => $section_node->getAttribute( 'type' ),
						table => $section_node->getAttribute( 'table' ),
						on    => DBIx::Romani::Query::XML::SQL::create_where_from_node( $op_nodes[0] ),
					};
					$select->set_join( $args );
				}
				else
				{
					die "The <join/> section must have one and only one child.";
				}
			}
			elsif ( $section_name eq 'group-by' )
			{
				if ( scalar @{$select->get_group_by()} > 0 )
				{
					die "Cannot have multiple <group-by> sections in a <select/> query";
				}

				my @col_nodes;

				my $node = $section_node->getFirstChild();
				while ( defined $node )
				{
					if ( $node->getNodeType() == XML::DOM::ELEMENT_NODE and
					     $node->getNamespaceURI() eq $NS_QUERY )
					{
						if ( $node->getLocalName() eq 'column' )
						{
							push @col_nodes, $node;
						}
						else
						{
							die sprintf "Invalid tag \"%s\" used in <group-by/> section", $node->getTagName();
						}
					}

					$node = $node->getNextSibling();
				}

				if ( $section_node->getAttributeNode('column') and scalar @col_nodes > 0 )
				{
					die "Cannot use both the long form and short form <group-by/> tag";
				}

				# add the group bys
				if ( scalar @col_nodes == 0 )
				{
					$select->add_group_by( $section_node->getAttribute( 'column' ) );
				}
				else
				{
					foreach my $node ( @col_nodes )
					{
						$select->add_group_by( get_element_text($node) );
					}
				}
			}
			elsif ( $section_name eq 'order-by' )
			{
				if ( scalar @{$select->get_order_by()} > 0 )
				{
					die "Cannot have multiple <order-by> sections in a <select/> query";
				}

				my @col_nodes;

				my $node = $section_node->getFirstChild();
				while ( defined $node )
				{
					if ( $node->getNodeType() == XML::DOM::ELEMENT_NODE and
					     $node->getNamespaceURI() eq $NS_QUERY )
					{
						if ( $node->getLocalName() eq 'column' )
						{
							push @col_nodes, $node;
						}
						else
						{
							die sprintf "Invalid tag \"%s\" used in <order-by/> section", $node->getTagName();
						}
					}

					$node = $node->getNextSibling();
				}

				if ( $section_node->getAttributeNode('column') and scalar @col_nodes > 0 )
				{
					die "Cannot use both the long form and short form <order-by/> tag";
				}

				# add the group bys
				if ( scalar @col_nodes == 0 )
				{
					my $args = {
						column => $section_node->getAttribute( 'column' ),
						dir    => $section_node->getAttribute( 'dir' ) || 'asc'
					};
					$select->add_order_by($args);
				}
				else
				{
					foreach my $node ( @col_nodes )
					{
						my $args = {
							column => get_element_text($node),
							dir    => $node->getAttribute( 'dir' ) || 'asc'
						};
						$select->add_order_by($args);
					}
				}
			}
			else
			{
				die "Unknown section \"$section_name\" in <select/> query";
			}
		}

		$section_node = $section_node->getNextSibling();
	}

	return $select;
}

1;

