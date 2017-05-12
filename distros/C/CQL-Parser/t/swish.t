use strict;
use warnings;
use Test::More qw( no_plan );
use Test::Exception;

use_ok( 'CQL::Parser' );
my $parser = CQL::Parser->new();

my $node = $parser->parse( "origami" );
is( $node->toSwish(), 'origami', 'simple word search' );

$node = $parser->parse( "lexic*" );
is( $node->toSwish(), "lexic*", "right hand truncation" );

$node = $parser->parse( qq("library of congress") );
is( $node->toSwish(), qq("library of congress"), "phrase search" );

$node = $parser->parse( qq(librarians and "information scientists") );
is( $node->toSwish(), qq(librarians and "information scientists"), 
    'boolean intersection' );

$node = $parser->parse( qq(origami or "paper folding") );
is( $node->toSwish(), qq(origami or "paper folding"), 'boolean union' );

$node = $parser->parse( qq(Thanksgiving not Christmas) );
is( $node->toSwish(), qq(Thanksgiving not Christmas), 'boolean negation' );

$node = $parser->parse( qq(dc.creator="Thomas Jefferson") );
is( $node->toSwish(), qq(dc.creator = "Thomas Jefferson"), 'field searching' );

$node = $parser->parse( qq(("paper folding" or origami) and japanese) );
is( $node->toSwish(), qq(("paper folding" or origami) and japanese), 
    'nesting with parens' );

$node = $parser->parse( "title exact fish" );
throws_ok 
    { $node->toSwish() }
    qr/Swish doesn't support relations other than = and not/,
    'toSwish() fails on exact searches';
