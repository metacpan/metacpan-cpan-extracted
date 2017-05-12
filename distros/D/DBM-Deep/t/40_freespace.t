use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Exception;
use t::common qw( new_fh );

use_ok( 'DBM::Deep' );

{
    my ($fh, $filename) = new_fh();
    my $db = DBM::Deep->new({
        file => $filename,
        autoflush => 1,
    });

    $db->{foo} = '1234';
    $db->{foo} = '2345';

    my $size = -s $filename;
    $db->{foo} = '3456';
    cmp_ok( $size, '==', -s $filename, "A second overwrite doesn't change size" );

    $size = -s $filename;
    delete $db->{foo};
    cmp_ok( $size, '==', -s $filename, "Deleted space isn't released" );

    $db->{bar} = '2345';
    cmp_ok( $size, '==', -s $filename, "Added a new key after a delete reuses space" );

    $db->{baz} = {};
    $size = -s $filename;

    delete $db->{baz};
    $db->{baz} = {};

    cmp_ok( $size, '==', -s $filename, "delete and rewrite reuses space" );

    $db->{baz} = {};
    $size = -s $filename;

    $db->{baz} = {};

    cmp_ok( $size, '==', -s $filename, "delete and rewrite reuses space" );

    my $x = { foo => 'bar' };
    $db->{floober} = $x;

    delete $db->{floober};

    ok( !exists $x->{foo}, "Deleting floober makes \$x empty (exists)" );
    is( $x->{foo}, undef, "Deleting floober makes \$x empty (read)" );
    is( delete $x->{foo}, undef, "Deleting floober makes \$x empty (delete)" );

    eval { $x->{foo} = 'bar'; };
    like( $@, qr/Cannot write to a deleted spot in DBM::Deep/, "Exception thrown when writing" );

    cmp_ok( scalar( keys %$x ), '==', 0, "Keys returns nothing after deletion" );
}

{
    my ($fh, $filename) = new_fh();
    my $db = DBM::Deep->new({
        file => $filename,
        autoflush => 1,
    });

    $db->{ $_ } = undef for 1 .. 4;
    delete $db->{ $_ } for 1 .. 4;
    cmp_ok( keys %{ $db }, '==', 0, "We added and removed 4 keys" );

    # So far, we've written 4 keys. Let's write 13 more keys. This should -not-
    # trigger a reindex. This requires knowing how much space is taken. Good thing
    # we wrote this dreck ...
    my $size = -s $filename;

    my $data_sector_size = $db->_engine->data_sector_size;
    my $expected = $size + 9 * ( 2 * $data_sector_size );

    $db->{ $_ } = undef for 5 .. 17;

    cmp_ok( $expected, '==', -s $filename, "No reindexing after deletion" );
}

done_testing;
