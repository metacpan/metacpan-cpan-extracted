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

subtest 'Scalar-ref inline SQL function as non-autoincrement char PK' => sub {

    ok(
        do { eval { $schema->resultset('Event') }; !$@ },
        'resultset() can resolve Event source'
    );

    eval {
        $schema->resultset('Event')->create({
            EventId   => \q{ lower(hex(randomblob(16))) },
            TapeoutId => '550e8400-e29b-41d4-a716-446655440000',
            Content   => 'Test event content',
            IpAddr    => 2130706433,
            Author    => 'test_author',
            Context   => 'test_context',
        })->get;
    };

    like(
        $@,
        qr/Cannot use a scalar-ref.*EventId/,
        'scalar-ref char PK croaks with a clear descriptive error'
    );
};

subtest 'Perl-side UUID as non-autoincrement char PK works correctly' => sub {

    my $uuid = do { require Data::UUID; lc Data::UUID->new->create_str };

    my $row = eval {
        $schema->resultset('Event')->create({
            EventId   => $uuid,
            TapeoutId => '550e8400-e29b-41d4-a716-446655440000',
            Content   => 'Sanity check row',
            IpAddr    => 2130706433,
            Author    => 'test_author',
            Context   => undef,
        })->get;
    };

    ok( !$@,                                 'create() did not throw'             );
    isa_ok( $row, 'DBIx::Class::Async::Row', 'Returned a Row object'              );
    is( $row->EventId, $uuid,                'EventId matches the UUID we passed' );
};

subtest 'Scalar-ref on non-PK select column is unaffected by the guard' => sub {

    # Insert a known row to search against
    my $uuid = do { require Data::UUID; lc Data::UUID->new->create_str };

    $schema->resultset('Event')->create({
        EventId   => $uuid,
        TapeoutId => '550e8400-e29b-41d4-a716-446655440000',
        Content   => 'Dynamic SQL test row',
        IpAddr    => 2130706433,
        Author    => 'test_author',
        Context   => undef,
    })->get;

    # Scalar ref in +select (non-PK) should pass the guard and work correctly
    my $result = eval {
        $schema->resultset('Event')
            ->search(
                { EventId => $uuid },
                {
                    '+select'    => [ { '' => \"strftime('%Y-%m-%d %H:%M:%f', 'now')", -as => 'ts' } ],
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                }
            )->all->get;
    };

    ok( !$@,                    'scalar-ref on non-PK select column did not throw' );
    ok( $result && @$result,    'Got results back'                                  );
    ok( $result->[0]{ts},       'Got timestamp value from dynamic select column'   );

    sleep 1;

    my $result2 = eval {
        $schema->resultset('Event')
            ->search(
                { EventId => $uuid },
                {
                    '+select'    => [ { '' => \"strftime('%Y-%m-%d %H:%M:%f', 'now')", -as => 'ts' } ],
                    result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                }
            )->all->get;
    };

    isnt(
        $result->[0]{ts},
        $result2->[0]{ts},
        'Dynamic SQL in +select bypasses cache correctly (timestamps differ)'
    );
};

$schema->disconnect;

done_testing;
