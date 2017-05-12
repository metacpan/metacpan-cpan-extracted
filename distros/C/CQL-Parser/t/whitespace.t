use strict;
use warnings;
use Test::More tests => 1;
use CQL::Parser;

eval {
    my $parser = CQL::Parser->new();
    my $node = $parser->parse( "title=dinosaur\n" );
};

if ( $@ ) { fail( "didn't ignore trailing whitespace" ); }
else { pass( "ignored trailing whitespace" ); }
