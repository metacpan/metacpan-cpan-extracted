
package DBIx::Romani::Query::XML::Util;
use base qw( Exporter );

use XML::DOM;
use strict;

our @EXPORT_OK = qw( 
	$NS_QUERY 
	$NS_QUERY_FUNCTION 
	$NS_QUERY_OPERATOR
	get_element_text
	get_boolean_attribute
	parse_boolean);

our $NS_QUERY          = 'http://www.carspot.com/query';
our $NS_QUERY_FUNCTION = 'http://www.carspot.com/query-function';
our $NS_QUERY_OPERATOR = 'http://www.carspot.com/query-operator';

# TEMP: for backward compatibility
sub get_text    { return get_element_text(@_); }
sub get_boolean { return get_boolean_attribute(@_); }

sub get_element_text
{
	my $node = shift;

	my $text = "";
	my $child = $node->getFirstChild();
	while ( defined $child )
	{
		if ( $child->getNodeType() == XML::DOM::TEXT_NODE )
		{
			$text .= $child->getNodeValue();
		}
		elsif ( $child->getNodeType() == XML::DOM::ELEMENT_NODE )
		{
			die sprintf "Expecting only text inside of \"%s\" tag", $node->getTagName();
		}

		$child = $child->getNextSibling();
	}

	return $text;
}

sub parse_boolean
{
	my $text = shift;

	if ( $text eq '0' or $text eq 'false' )
	{
		return 0;
	}
	elsif ( $text eq '1' or $text eq 'true' )
	{
		return 1;
	}
	else
	{
		die "Invalid boolean string \"$text\"";
	}
}

sub get_boolean_attribute
{
	my ($node, $attr, $default) = @_;

	if ( $node->getAttributeNode( $attr ) )
	{
		return parse_boolean( $node->getAttribute( $attr ) );
	}

	return $default;
}

1;

