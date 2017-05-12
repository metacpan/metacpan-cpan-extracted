use strict;
use warnings;
use Test::More qw( no_plan );
use Test::Exception;

use_ok( 'CQL::Parser' );
my $parser = CQL::Parser->new();

my $node = $parser->parse( "origami" );
is( $node->toLucene(), 'origami', 'simple word search' );

$node = $parser->parse( "lexic*" );
is( $node->toLucene(), "lexic*", "right hand truncation" );

$node = $parser->parse( qq("library of congress") );
is( $node->toLucene(), qq("library of congress"), "phrase search" );

$node = $parser->parse( qq(librarians and "information scientists") );
is( $node->toLucene(), qq(librarians AND "information scientists"), 
    'boolean intersection' );

$node = $parser->parse( qq(origami or "paper folding") );
is( $node->toLucene(), qq(origami OR "paper folding"), 'boolean union' );

$node = $parser->parse( qq(Thanksgiving not Christmas) );
is( $node->toLucene(), qq(Thanksgiving NOT Christmas), 'boolean negation' );

$node = $parser->parse( qq(dc.creator="Thomas Jefferson") );
is( $node->toLucene(), qq(dc.creator:"Thomas Jefferson"), 'field searching' );

$node = $parser->parse( qq(("paper folding" or origami) and japanese) );
is( $node->toLucene(), qq(("paper folding" OR origami) AND japanese), 
    'nesting with parens' );

$node = $parser->parse(qq(author = /fuzzy tailor));
is( $node->toLucene(), qq(author:tailor~), 'relation modifier of fuzzy search');

$node = $parser->parse(qq(complete prox dinosaur));
is( $node->toLucene(), qq("complete dinosaur"~1), "proximity search");

#$node = $parser->parse(qq(ribs prox/>/5/paragraph chevrons));
$node = $parser->parse(qq(ribs prox/distance>=5/unit=paragraph chevrons));
is( $node->toLucene(), qq("ribs chevrons"~5), "proximity search, ignore unsupported parameters");

$node = $parser->parse( "title exact fish" );
throws_ok 
    { $node->toLucene() }
    qr/Lucene doesn't support relations other than '='/,
    'toLucene() fails on exact searches';
