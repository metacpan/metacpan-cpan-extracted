
package DBIx::Romani::Query::XML::TTT;

use DBIx::Romani::Query::XML::Util;
use DBIx::Romani::Query::XML::Where;
use DBIx::Romani::Query::XML::SQL;
use DBIx::Romani::Query::SQL::TTT::Operator;
use DBIx::Romani::Query::SQL::TTT::Function;
use DBIx::Romani::Query::SQL::TTT::Keyword;
use DBIx::Romani::Query::SQL::TTT::Join;
use XML::DOM;
use strict;

use Data::Dumper;

# NOTE: Copied from DBIx::Romani::Query::Select!!
sub get_node_type
{
	my $ttt_node = shift;

	my $type;

	if ( $ttt_node->getAttributeNode( 'op' ) )
	{
		$type = 'op';
	}
	if ( $ttt_node->getAttributeNode( 'func' ) )
	{
		if ( $type )
		{
			$type = 'invalid';
		}
		else
		{
			$type = 'func';
		}
	}
	if ( $ttt_node->getAttributeNode( 'keyword' ) )
	{
		if ( $type )
		{
			$type = 'invalid';
		}
		else
		{
			$type = 'keyword';
		}
	}
	if ( not defined $type )
	{
		$type = 'join';
	}

	if ( $type eq 'invalid' )
	{
		die "<ttt/> can only contain one of the following attributes: op, func, keyword";
	}

	return $type;
}

sub create_ttt_from_node
{
	my $ttt_node = shift;

	my $type = get_node_type( $ttt_node );

	# first create ourselfs
	my $ttt;
	if ( $type eq 'op' )
	{
		$ttt = DBIx::Romani::Query::SQL::TTT::Operator->new( $ttt_node->getAttribute('op') );
	}
	elsif ( $type eq 'func' )
	{
		$ttt = DBIx::Romani::Query::SQL::TTT::Function->new( $ttt_node->getAttribute('func') );
	}
	elsif ( $type eq 'keyword' )
	{
		$ttt = DBIx::Romani::Query::SQL::TTT::Keyword->new( $ttt_node->getAttribute('keyword') );
	}
	elsif ( $type eq 'join' )
	{
		$ttt = DBIx::Romani::Query::SQL::TTT::Join->new();
	}

	# go through our children
	my $node = $ttt_node->getFirstChild();
	while ( defined $node )
	{
		if ( $node->getNodeType() == XML::DOM::ELEMENT_NODE )
		{
			# now we recurse using the generic handler!
			$ttt->add( DBIx::Romani::Query::XML::SQL::create_where_from_node($node) );
		}

		$node = $node->getNextSibling();
	}

	return $ttt;
}

1;

