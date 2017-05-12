#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 29;
use CQL::Token;

## test the CQL Lexer

use_ok( 'CQL::Lexer' );

## test tokenizing

my $lexer = CQL::Lexer->new();
isa_ok( $lexer, "CQL::Lexer" );

$lexer->tokenize( 'foo and bar' );
is_deeply( 
    [ getStrings( $lexer->getTokens() ) ], 
    ['foo', 'and', 'bar' ], 
    'foo and bar' );

$lexer->tokenize( 'foo and bar and baz' );
is_deeply( 
    [ getStrings( $lexer->getTokens() ) ], 
    ['foo', 'and', 'bar', 'and', 'baz' ], 
    'foo and bar and baz' );

$lexer->tokenize( 'foo<bar' );
is_deeply( 
    [ getStrings( $lexer->getTokens() ) ], 
    ['foo', '<', 'bar' ], 
    'foo<bar' );

$lexer->tokenize( 'foo<=bar' );
is_deeply( 
    [ getStrings( $lexer->getTokens() ) ],
    ['foo','<=','bar'], 
    'foo<=bar' );

$lexer->tokenize( 'foo>bar' );
is_deeply( 
    [ getStrings( $lexer->getTokens() ) ], 
    [ 'foo', '>', 'bar' ], 
    'foo>bar' );

$lexer->tokenize( 'foo>=bar' );
is_deeply( 
    [ getStrings( $lexer->getTokens() ) ], 
    ['foo','>=','bar'], 
    'foo>=bar' );

$lexer->tokenize( 'foo=bar' );
is_deeply( 
    [ getStrings( $lexer->getTokens() ) ], 
    ['foo', '=', 'bar' ], 
    'foo=bar' );

$lexer->tokenize( 'foo="bar bez"' );
is_deeply( 
    [ getStrings( $lexer->getTokens() ) ], 
    ['foo', '=', 'bar bez' ], 
    'foo="bar bez"' );

$lexer->tokenize( '(foo<10) and (bar>bez)' );
is_deeply( 
    [ getStrings( $lexer->getTokens() ) ], 
    [ '(','foo','<','10',')','and','(','bar','>','bez',')' ],
    '(foo<10) and (bar>bez)' );

$lexer->tokenize( '(foo<10) and (bar>bez)' );
is_deeply( 
    [ getTypes( $lexer->getTokens() ) ], 
    [ CQL_LPAREN, CQL_WORD, CQL_LT, CQL_WORD, CQL_RPAREN, CQL_AND, CQL_LPAREN,
        CQL_WORD, CQL_GT, CQL_WORD, CQL_RPAREN ],
    'token types for: (foo<10) and (bar>bez)' );



## test iterator methods

$lexer->tokenize( 'foo and bar' );
is( $lexer->nextToken()->getString(), 'foo', 'nextToken() foo' );
is( $lexer->nextToken()->getString(), 'and', 'nextToken() and' );
is( $lexer->nextToken()->getString(), 'bar', 'nextToken() bar' );
is( $lexer->nextToken()->getType(), CQL_EOF, 'nextToken() end of tokens' );
is( $lexer->nextToken()->getType(), CQL_EOF, 'nextToken() really the end!' );  
is( $lexer->prevToken()->getString(), 'bar', 'prevToken() bar' );
is( $lexer->prevToken()->getString(), 'and', 'prevToken() and' );
is( $lexer->prevToken()->getString(), 'foo', 'prevToken() foo' );
is( $lexer->prevToken()->getType(),CQL_EOF,'prevToken() beginning of tokens()');
is( $lexer->prevToken()->getType(),CQL_EOF,'really is the beginning!' );
is( $lexer->nextToken()->getString(), 'foo', 'nextToken() starting over' );
$lexer->reset(); ## reset iterator
is( $lexer->nextToken()->getString(), 'foo', 'nextToken() after reset()' );

## modifiers
$lexer->tokenize( "author = /fuzzy tailor" );
is_deeply( 
    [ getTypes( $lexer->getTokens() ) ], 
    [ CQL_WORD, CQL_EQ, CQL_MODIFIER, CQL_FUZZY, CQL_WORD ],
    'token types for: author = /fuzzy tailor' );

## make sure this works
$lexer->tokenize('"http://www.yahoo.com"');
my @tokens = $lexer->getTokens();
is( @tokens, 1, 'got 1 token' );
is( $tokens[0]->getString(), 'http://www.yahoo.com', 'got quoted url' );

## zero is a valid token
$lexer->tokenize('0');
@tokens = $lexer->getTokens();
is( @tokens, 1, 'lexed one token' );
is( $tokens[0]->getString(), '0', 'able to lex 0' );

## helper for returning a list of strings from a list of CQL::Token objects 
sub getStrings {
    return map { $_->getString() } @_;
}

sub getTypes {
    return map { $_->getType() } @_;
}
 
