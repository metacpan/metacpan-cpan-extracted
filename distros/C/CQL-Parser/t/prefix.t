use strict;
use warnings;
use Test::More qw( no_plan );

use_ok( 'CQL::PrefixNode' );
use_ok( 'CQL::TermNode' );
use_ok( 'CQL::AndNode' );

my $subtree = CQL::AndNode->new( 
    left    => CQL::TermNode->new( term => 'foo' ),
    right   => CQL::TermNode->new( term => 'bar' )
);

my $prefixNode = CQL::PrefixNode->new(
    name        => 'dc',
    identifier  => 'http://zthes.z3950.org/cql/1.0',
    subtree     => $subtree
);

isa_ok( $prefixNode, 'CQL::PrefixNode' );

my $prefix = $prefixNode->getPrefix();
isa_ok( $prefix, 'CQL::Prefix' );

is( $prefixNode->toCQL(), 
    '>dc="http://zthes.z3950.org/cql/1.0" ((foo) and (bar))', 
    'toCQL()' );

my $xml = $prefixNode->toXCQL();
$xml =~ s/[\r\n]//g;
$xml =~ s/> +/>/g;
is( $xml,
    '<triple xmlns="http://www.loc.gov/zing/cql/xcql/"><prefixes><prefix><name>dc</name><identifier>http://zthes.z3950.org/cql/1.0</identifier></prefix></prefixes><boolean><value>and</value></boolean><leftOperand><searchClause><index></index><term>foo</term></searchClause></leftOperand><rightOperand><searchClause><index></index><term>bar</term></searchClause></rightOperand></triple>', 
    'toXCQL()'
);
