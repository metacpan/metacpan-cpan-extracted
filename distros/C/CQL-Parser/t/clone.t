use strict;
use warnings;
use Test::More qw( no_plan );

use_ok( 'CQL::Parser' );
my $parser = CQL::Parser->new();

## get a parse tree
my $node = $parser->parse( 'foo and ( bar or baz )' );

## make a clone from the root down
my $clone = $node->clone();
is( $node->toCQL(), $clone->toCQL(), 'original and clone have same CQL' );

## transform the copy and make sure original is still the same
my $visitor = MyVisitor->new();
$visitor->visit($clone);
is( $node->toCQL(), '(foo) and ((bar) or (baz))', 'original node unaltered' );
is( $clone->toCQL(), '(goo) and ((goo) or (goo))', 'clone altered' );

## kind of bogus visitor that transforms all term nodes into
## 'goo'

package MyVisitor;

use base qw( CQL::Visitor );

sub term {
    my ($self,$term) = @_;
    $term->{term} = 'goo';
}

1;
