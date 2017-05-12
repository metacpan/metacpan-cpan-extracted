use Test::More tests => 3;

use Data::Pipeline::Parser;

my $parser = Data::Pipeline::Parser -> new();

my($e, $p) = ( {} );

$p = $parser -> parse($e, <<EODEF, {});

    IN: Array
    OUT: Array
    USE: Identity

    PIPELINE DOES IN ORDER:
        Array
        => Identity
        => Array
    DONE

EODEF

my $out = [ ];
$p -> run( from => { array => [qw(a b c d)] }, to => [ $out ] );

is_deeply($out, [qw(a b c d)]);

($e, $out) = ( {}, [] );
$p = $parser -> parse($e, <<EODEF, {});

    IN: Array
    OUT: Array
    USE: Count

    PIPELINE DOES IN ORDER:
        Array
        => Count
        => Array
    DONE

EODEF

eval {
$p -> run( from => { array => [qw(a b c d)] }, to => [ $out ] );
};

is_deeply($out, [{ count => 4 }]);

($e, $out) = ( {}, [] );
eval {
$p = $parser -> parse($e, <<EODEF, {});

    IN: CSV
    OUT: Array
    USE: Filter

    FROM: \file: "t/data/csv"

    PIPELINE DOES IN ORDER:
        CSV: file_has_header: TRUE
        => Filter: filters: foo: qr/e/
        => Array
    DONE

EODEF
};

eval { $p -> run( from => { file => 't/data/csv' }, to => [ $out ] ); };

TODO: {
local $TODO = "Still working on passing file info to CSV adapter";
is_deeply( $out, [
    {qw(foo Apple  bar 3  baz 2.50)},
    {qw(foo Pear   bar 2  baz 1.25)}
] );
}
