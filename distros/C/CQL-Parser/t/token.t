use strict;
use warnings;
use Test::More qw( no_plan );

## can't use_ok here since we need to export constants
use CQL::Token;

my $token = CQL::Token->new( 'foo' );
is( $token->getType(), CQL_WORD, 'getType()' );
is( $token->getString(), 'foo', 'getString()' );

$token = CQL::Token->new( '<' );
is( $token->getType(), CQL_LT, '<' );

$token = CQL::Token->new( '>' );
is( $token->getType(), CQL_GT, '>' );

$token = CQL::Token->new( '<>' );
is( $token->getType(), CQL_NE, '<>' );

$token = CQL::Token->new( '<=' ); 
is( $token->getType(), CQL_LE, '=' );

$token = CQL::Token->new( '"foo bar"' );
is( $token->getType(), CQL_WORD, '"foo bar" is a CQL_WORD' );
is( $token->getString(), 'foo bar', "surrounding quotes removed" );

$token = CQL::Token->new( 'word' );
is( $token->getType(), CQL_PWORD, 'reserved keyword no quotes' );

$token = CQL::Token->new( '"word"' );
is( $token->getType(), CQL_WORD, 'reserved word surrounded by quotes' );

