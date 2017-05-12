use strict;
use Test::More;
use Acme::MetaSyntactic;

plan tests => 2;

NEW_OK: {
    my $meta = Acme::MetaSyntactic->new('foo');
    isa_ok( $meta, 'Acme::MetaSyntactic' );
}

NEW_UNKNOWN: {
    my $meta = eval { Acme::MetaSyntactic->new('bam') };
    isa_ok( $meta, 'Acme::MetaSyntactic' );
}

