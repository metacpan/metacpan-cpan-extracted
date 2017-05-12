use strict;
use warnings;
use CQL::Parser;
use CQL::Visitor;
use Test::More tests=>2; 

# test the ability to visit term nodes and convert the dc 
# qualifiers

my $parser = CQL::Parser->new();
my $node = $parser->parse( "(dc.title=foo or bar) and dc.creator=baz" );
is( 
    $node->toCQL(), 
    '((dc.title = foo) or (bar)) and (dc.creator = baz)',
    'toCQL() prior to transformation' 
);

my $visitor = MyVisitor->new();
$visitor->visit($node);

is( 
    $node->toCQL(), 
    '((title = foo) or (bar)) and (creator = baz)',
    'visitor worked' 
);


## test visitor class

package MyVisitor;

use base qw( CQL::Visitor );

sub term {
    my ($self,$node) = @_;
    # remove dc prefix from qualifier
    # bad OO, digging right into object
    # need set methods at some point
    if ( $node->{qualifier} ) {
        $node->{qualifier} =~ s/^dc\.//;
    }
}

1;
