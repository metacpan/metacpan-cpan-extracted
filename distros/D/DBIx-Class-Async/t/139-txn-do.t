#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp;

use IO::Async::Loop;
use DBIx::Class::Async::Schema;

use lib 't/lib';

my $loop           = IO::Async::Loop->new;
my ($fh, $db_file) = File::Temp::tempfile(UNLINK => 1);
my $schema         = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$db_file", undef, undef, {},
    { workers      => 2,
      schema_class => 'TestSchema',
      async_loop   => $loop,
      cache_ttl    => 60,
    },
);

$schema->await($schema->deploy({ add_drop_table => 1 }));

subtest 'Dependent Cross-Table Transaction' => sub {
    my $txn_f = $schema->txn_do([
        {
            name      => 'new_user',
            action    => 'create',
            resultset => 'User',
            data      => { name => 'Alice', email => 'alice@example.com' }
        },
        {
            action    => 'create',
            resultset => 'Order',
            data      => {
                user_id => '$new_user.id',
                amount  => 150.00
            }
        }
    ]);

    my $inner_f = $schema->await($txn_f);
    my $res     = $inner_f;

    ok($res->{success}, "Transaction completed");

    my $search_f      = $schema->resultset('Order')->search_future({});
    my $orders        = $schema->await($search_f);
    my $user_search_f = $schema->resultset('User')->search_future({ name => 'Alice' });
    my $users         = $schema->await($user_search_f);

    is($orders->[0]{user_id}, $users->[0]{id}, "Order linked to correct User ID via register");
};

subtest 'Raw SQL: values must go through bind, not string interpolation (CPANSec CWE-89)' => sub {
    # SECURITY: prior to the fix, '$name.id'-style tokens were substituted
    # directly into the 'sql' text of a raw step via unescaped string
    # interpolation, before being handed to $dbh->do(). Because register
    # values are not always safe integers (e.g. a string/UUID primary
    # key an attacker can influence at create() time), this allowed SQL
    # injection through the module's own documented variable-chaining
    # feature. The fix stops substituting into 'sql' entirely: chained
    # values must be referenced via the 'bind' arrayref with a '?'
    # placeholder in the SQL, which the DB driver binds as a genuine,
    # injection-safe parameter.

    # 1. The SAFE, documented pattern: placeholder in SQL, value in bind.
    my $safe_txn_f = $schema->txn_do([
        {
            name      => 'safe_user',
            action    => 'create',
            resultset => 'User',
            data      => { name => 'Original Name', email => 'safe-raw@test.com' }
        },
        {
            action    => 'raw',
            sql       => 'UPDATE users SET name = ? WHERE id = ?',
            bind      => [ 'Modified via bind', '$safe_user.id' ],
        }
    ]);

    my $safe_res = $schema->await($safe_txn_f);
    ok($safe_res->{success}, 'Transaction using bind-parameter chaining succeeded');

    my $safe_users = $schema->await(
        $schema->resultset('User')->search_future({ email => 'safe-raw@test.com' })
    );
    is($safe_users->[0]{name}, 'Modified via bind',
        'Chained id correctly reached the query as a bound parameter');

    # 2. SECURITY REGRESSION: a '$name.id' token left inside the 'sql'
    # text itself must NOT be silently substituted. Attempting to use it
    # that way should surface as a query error (invalid syntax) rather
    # than silently succeeding with spliced-in text, proving the
    # substitution path is closed, not just quietly wrong.
    my $unsafe_txn_f = $schema->txn_do([
        {
            name      => 'unsafe_user',
            action    => 'create',
            resultset => 'User',
            data      => { name => 'Another Name', email => 'unsafe-raw@test.com' }
        },
        {
            action    => 'raw',
            sql       => 'UPDATE users SET name = \'should not interpolate\' WHERE id = $unsafe_user.id',
        }
    ]);

    my $unsafe_res = eval { $schema->await($unsafe_txn_f) };
    my $unsafe_err = $@;
    ok($unsafe_err, "A literal \$name.id left in raw SQL text is NOT interpolated (fails loudly instead of injecting)");

    my $unsafe_users = $schema->await(
        $schema->resultset('User')->search_future({ email => 'unsafe-raw@test.com' })
    );
    is(scalar @$unsafe_users, 0,
        'Whole transaction rolled back atomically, no partial write occurred, and no SQL injection happened');
};

$schema->disconnect;

done_testing;
