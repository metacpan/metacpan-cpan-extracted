use strict;
use Test::More;
use AI::MicroStructure;

plan tests => 2;

NEW_OK: {
    my $meta = AI::MicroStructure->new('foo');
    isa_ok( $meta, 'AI::MicroStructure' );
}

NEW_UNKNOWN: {
    my $meta = eval { AI::MicroStructure->new('bam') };
    isa_ok( $meta, 'AI::MicroStructure' );
}

1;
