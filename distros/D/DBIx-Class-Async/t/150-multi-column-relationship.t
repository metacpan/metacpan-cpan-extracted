#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp;

use lib 't/lib';

use TestSchema;
use IO::Async::Loop;
use DBIx::Class::Async::Schema;

my $loop           = IO::Async::Loop->new;
my ($fh, $db_file) = File::Temp::tempfile(UNLINK => 1);
my $schema         = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$db_file", undef, undef, {},
    {
        workers      => 1,
        schema_class => 'TestSchema',
        async_loop   => $loop,
    }
);

$schema->await($schema->deploy({ add_drop_table => 1 }));

# Seed data
#
# sprocket: length 10.00
# thing:    width  5.00, uses the sprocket above
# cog:      identified by sprocketLength=10.00 AND thingWidth=5.00
my $sprocket = $schema->resultset('Sprocket')->create({
    sprocketLength => '10.00',
})->get;

my $thing = $schema->resultset('Thing')->create({
    sprocketID => $sprocket->sprocketID,
    thingWidth => '5.00',
})->get;

$schema->resultset('Cog')->create({
    sprocketLength => '10.00',
    thingWidth     => '5.00',
    cogPartNum     => 'COG-A1',
})->get;

# Approach A: join/prefetch via DBIC relationship coderef
subtest 'Approach A: cog via join/prefetch relationship' => sub {

    my $result = $schema->resultset('Thing')->search(
        { 'me.thingID' => $thing->thingID },
        { join => [ 'sprocket', 'cog' ] }
    )->all->get;

    is( scalar @$result, 1, 'Got exactly one thing' );

    my $found = $result->[0];
    is( $found->thingID,   $thing->thingID,     'thingID matches'   );
    is( $found->thingWidth + 0, 5,              'thingWidth correct' );

    # Prefetch both relationships in one query
    my $with_prefetch = $schema->resultset('Thing')->search(
        { 'me.thingID' => $thing->thingID },
        { prefetch => [ 'sprocket', 'cog' ] }
    )->all->get;

    my $t           = $with_prefetch->[0];
    my $cog_row     = $t->cog->get;
    my $sprocket_row = $t->sprocket->get;

    is( $cog_row->cogPartNum,              'COG-A1', 'Got correct cogPartNum via prefetch'       );
    is( $sprocket_row->sprocketLength + 0, 10,       'Got correct sprocketLength via prefetch'   );
};

# Approach B: helper method find_cog on Thing
subtest 'Approach B: cog via find_cog() helper method on Thing' => sub {

    my $result = $schema->resultset('Thing')->find(
        $thing->thingID
    )->get;

    ok( defined $result,                        'find() returned a row'               );
    isa_ok( $result, 'DBIx::Class::Async::Row', 'Got a Thing row'                     );

    my $sprocket_row = $result->sprocket->get;
    isa_ok( $sprocket_row, 'DBIx::Class::Async::Row', 'Got related Sprocket row'      );
    is( $sprocket_row->sprocketLength + 0, 10,  'sprocketLength correct'              );

    # find_cog uses the async schema to look up sprocket then cog
    my $cog_future = $result->find_cog($schema);
    ok( defined $cog_future,                    'find_cog() returned a Future'        );

    my $cog_row = $cog_future->get;
    ok( defined $cog_row,                       'find_cog() resolved to a row'        );
    isa_ok( $cog_row, 'DBIx::Class::Async::Row','Got related Cog row via find_cog()' );
    is( $cog_row->cogPartNum, 'COG-A1',         'cogPartNum correct via find_cog()'  );
};

# Confirm multiple things can share a sprocket
subtest 'Multiple things can share the same sprocket' => sub {

    $schema->resultset('Cog')->create({
        sprocketLength => '10.00',
        thingWidth     => '7.00',
        cogPartNum     => 'COG-B2',
    })->get;

    my $thing2 = $schema->resultset('Thing')->create({
        sprocketID => $sprocket->sprocketID,
        thingWidth => '7.00',
    })->get;

    my $cog1 = $thing->find_cog($schema)->get;
    my $cog2 = $thing2->find_cog($schema)->get;

    isnt( $cog1->cogPartNum, $cog2->cogPartNum,
        'Two things sharing a sprocket get different cogs based on thingWidth' );

    is( $cog1->cogPartNum, 'COG-A1', 'Thing 1 gets COG-A1' );
    is( $cog2->cogPartNum, 'COG-B2', 'Thing 2 gets COG-B2' );
};

$schema->disconnect;

done_testing;
