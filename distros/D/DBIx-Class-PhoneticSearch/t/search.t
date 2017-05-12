use Test::More tests => 16;

use strict;
use warnings;

use lib qw(t/lib);
use Schema;

my $s = Schema->connect;

my $rs = $s->resultset('Item');

eval { $rs->search_phonetic( { foobar => 'xyz' } ) };

ok( $@, 'error on unknown columns: ' . $@ );

eval { $rs->search_phonetic( { id => 'xyz' } ) };

ok( $@, 'error on non-phonetic columns: ' . $@ );

$rs->create( { name1 => 'Meyer', name2 => 'Peter' } );

$rs->create( { name1 => 'Schmidt', name2 => 'Moritz' } );

my @found = $rs->search_phonetic( { name1 => 'Meyer', name2 => 'Peter' } );

is( @found, 1, 'one result found' );

@found = $rs->search_phonetic( { name1 => 'Meier', name2 => 'Peter' } );

is( @found, 1, 'one result found' );

@found =
  $rs->search_phonetic( { 'me.name1' => 'Meier', 'me.name2' => 'Peter' } );

is( @found, 1, 'one result found with prefix' );

@found = $rs->search_phonetic( [ name1 => 'Meier', name1 => 'Meyer' ] );

is( @found, 1, 'one result found in OR search' );

@found = $rs->search_phonetic( [ name1 => 'Meier', name1 => 'Foo' ] );

is( @found, 1, 'zero results found in OR search' );

@found = $rs->search_phonetic( [ name2 => 'Moriz' ] );

is( @found, 1, 'moriz found instead of moritz' );

is( $rs->update_phonetic_columns, 4, 'updates 4 rows' );

is( $rs->update_phonetic_column('name1'), 2, 'updates 2 rows' );

is( $rs->result_source->column_info('name1')->{phonetic_search}->{algorithm},
    'Phonix', 'algorithm is set' );

is( $rs->result_source->column_info('name2')->{phonetic_search}->{algorithm},
    'Koeln', 'algorithm is set' );

$rs->create( { name1 => 'Schmidt', name2 => 'Moriz' } );

$rs->create( { name1 => 'Schmidt', name2 => 'Moriiz' } );

@found = $rs->search_phonetic( { name2 => 'Moriiz' },
    { order_by => { -desc => 'name2 LIKE "Moriiz"' } } );

is( $found[0]->name2, "Moriiz", 'sorting for exact match' );

$rs->create( { name2 => 'John', name1 => 'Night' } );

is($rs->search_phonetic( { name2 => 'Jon' } )->first->name2, 'John');      # John
is($rs->search_phonetic( { name1  => 'Knight' } )->first->name1, 'Night');    # Night
is($rs->search_phonetic(
    {
        name2 => 'Jon',
        name1  => 'Knight'
    }
)->first->name1, 'Night');                                                   # Night
