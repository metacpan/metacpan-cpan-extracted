use strict;
use warnings;
use Test::More qw( no_plan );

use_ok( 'CQL::TermNode' );
use_ok( 'CQL::AndNode' );
use_ok( 'CQL::OrNode' );
use_ok( 'CQL::NotNode' );
use_ok( 'CQL::ProxNode' );

## create a couple terms
my $term1 = CQL::TermNode->new( term => 'foo' );
isa_ok( $term1, 'CQL::TermNode' );
my $term2 = CQL::TermNode->new( term => 'bar' );
isa_ok( $term2, 'CQL::TermNode' );

## AND 
my $and = CQL::AndNode->new( left=>$term1, right=>$term2 );
isa_ok( $and, 'CQL::AndNode' );
is( $and->toCQL(), '(foo) and (bar)', 'and toCQL()' );
my $xcql = $and->toXCQL(0);
$xcql =~ s/[\r\n]//g;
$xcql =~ s/> +</></g;
is( $xcql, 
qq(<triple xmlns="http://www.loc.gov/zing/cql/xcql/"><boolean><value>and</value></boolean><leftOperand><searchClause><index></index><term>foo</term></searchClause></leftOperand><rightOperand><searchClause><index></index><term>bar</term></searchClause></rightOperand></triple>), 
    ,'toXCQL()' );

## OR
my $or = CQL::OrNode->new( left=>$term1, right=>$term2 );
isa_ok( $or, 'CQL::OrNode' );
is( $or->toCQL(), '(foo) or (bar)', 'or toCQL()' );

## NOT
my $not = CQL::NotNode->new( left=>$term1, right=>$term2 );
isa_ok( $not, 'CQL::NotNode' );
is( $not->toCQL(), '(foo) not (bar)', 'not toCQL()' );

## PROX
my $prox = CQL::ProxNode->new( $term1 );
$prox->addSecondTerm( $term2 );
$prox->addModifier( "relation", '>' );
$prox->addModifier( "distance", '2' );

isa_ok( $prox, 'CQL::ProxNode' );
is( $prox->toCQL(), '(foo) prox/distance>2 (bar)', 'prox toCQL()' );
