
package DBIx::Romani::Query::XML::SQL;

use DBIx::Romani::Query::XML::Util;
use DBIx::Romani::Query::XML::TTT;
use DBIx::Romani::Query::XML::Where;
use DBIx::Romani::Query::XML::Function;
use DBIx::Romani::Query::Function::Count;
use strict;

use Data::Dumper;

sub create_value_from_node
{
	my $node = shift;

	if ( $node->getNamespaceURI() eq $DBIx::Romani::Query::XML::Util::NS_QUERY )
	{
		if ( $node->getTagName() eq 'ttt' )
		{
			if ( DBIx::Romani::Query::XML::TTT::get_node_type( $node ) eq 'func' )
			{
				return DBIx::Romani::Query::XML::TTT::create_ttt_from_node( $node );
			}
		}
		elsif ( $node->getTagName() eq 'literal' )
		{
			return DBIx::Romani::Query::SQL::Literal->new( DBIx::Romani::Query::XML::Util::get_text( $node ) );
		}
		elsif ( $node->getTagName() eq 'column' )
		{
			# TODO: we should be able to set the table name
			return DBIx::Romani::Query::SQL::Column->new( undef, DBIx::Romani::Query::XML::Util::get_text( $node ) );
		}
	}
	elsif ( $node->getNamespaceURI() eq $DBIx::Romani::Query::XML::Util::NS_QUERY_FUNCTION )
	{
		return DBIx::Romani::Query::XML::Function::create_function_from_node( $node );
	}

	# Not a valid value!
	return undef;
}

sub create_function_from_node
{
	my $node = shift;

	if ( $node->getNamespaceURI() eq $DBIx::Romani::Query::XML::Util::NS_QUERY )
	{
		if ( $node->getTagName() eq 'ttt' )
		{
			if ( DBIx::Romani::Query::XML::TTT::get_node_type( $node ) eq 'func' )
			{
				return DBIx::Romani::Query::XML::TTT::create_ttt_from_node( $node );
			}
		}
	}
	elsif ( $node->getNamespaceURI() eq $DBIx::Romani::Query::XML::Util::NS_QUERY_FUNCTION )
	{
		return DBIx::Romani::Query::XML::Function::create_function_from_node( $node );
	}

	return undef;
}

sub create_where_from_node
{
	my $node = shift;

	if ( $node->getNamespaceURI() eq $DBIx::Romani::Query::XML::Util::NS_QUERY and 
	     $node->getTagName() eq 'ttt' )
	{
		return DBIx::Romani::Query::XML::TTT::create_ttt_from_node( $node );
	}
	elsif ( $node->getNamespaceURI() eq $DBIx::Romani::Query::XML::Util::NS_QUERY_OPERATOR )
	{
		return DBIx::Romani::Query::XML::Where::create_where_from_node( $node );
	}
	else
	{
		# if it is not any type of operator, it must be a value!
		return create_value_from_node( $node );
	}
}

1;

