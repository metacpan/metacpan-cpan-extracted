use Test::More tests => 18;

use Data::ConveyorBelt;
use List::Util qw( min );

{
    my @src = ( 1 .. 10 );

    my $machine = Data::ConveyorBelt->new;
    isa_ok $machine, 'Data::ConveyorBelt';
    isa_ok $machine->filters, 'ARRAY';
    is @{ $machine->filters }, 0, '0 filters defined';

    my $called_getter = 0;
    $machine->getter( sub {
        my($limit, $offset) = @_;
        $called_getter++;
        return [ @src[ $offset .. min($#src, $limit + $offset - 1) ] ];
    } );
    
    ## first 5 integers
    my $data = $machine->fetch( limit => 5 );
    isa_ok $data, 'ARRAY', 'got back an arrayref';
    is_deeply $data, [ 1 .. 5 ], 'data is 1..5';
    is $called_getter, 1, 'called getter once to get first 5 ints';

    ## Add a filter that only returns even integers.
    $machine->add_filter( sub {
        my($numbers) = @_;
        return [ grep { $_ % 2 == 0 } @$numbers ];
    } );
    is @{ $machine->filters }, 1, '1 filter added';

    ## basic usage: limit == 5, return all 5 even integers.
    $data = $machine->fetch( limit => 5 );
    isa_ok $data, 'ARRAY', 'got back an arrayref';
    is_deeply $data, [ 2, 4, 6, 8, 10 ], 'data is 2, 4, 6, 8, 10';

    ## limit == 3.
    $data = $machine->fetch( limit => 3 );
    isa_ok $data, 'ARRAY', 'got back an arrayref';
    is_deeply $data, [ 2, 4, 6 ], 'data is 2, 4, 6';

    ## limit + offset.
    $data = $machine->fetch( limit => 3, offset => 3 );
    isa_ok $data, 'ARRAY', 'got back an arrayref';
    is_deeply $data, [ 8, 10 ], 'data is 8, 10';

    ## Add a second filter (number > 5).
    $machine->add_filter( sub {
        my($numbers) = @_;
        return [ grep { $_ > 5 } @$numbers ];
    } );
    $data = $machine->fetch( limit => 5 );
    isa_ok $data, 'ARRAY', 'got back an arrayref';
    is_deeply $data, [ 6, 8, 10 ], 'data is 6, 8, 10';
}

## chunk_size
{
    my @src = ( 1 .. 10 );

    my $machine = Data::ConveyorBelt->new;
    my $called_getter = 0;
    $machine->getter( sub {
        my($limit, $offset) = @_;
        $called_getter++;
        return [ @src[ $offset .. min($#src, $limit + $offset - 1) ] ];
    } );
    my $data = $machine->fetch( limit => 5, chunk_size => 20 );
    isa_ok $data, 'ARRAY', 'got back an arrayref';
    is_deeply $data, [ 1 .. 5 ], 'data is 1..5';
    is $called_getter, 1, 'getter called once with chunk_size == 20';
}
