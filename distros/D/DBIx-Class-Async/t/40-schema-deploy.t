#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use IO::Async::Loop;
use Future::AsyncAwait;
use DBIx::Class::Async::Schema;

use lib 't/lib';
use TestSchema;

my $loop = IO::Async::Loop->new;

use File::Temp qw(tempfile);

my ($fh, $filename) = tempfile(UNLINK => 1, SUFFIX => '.db');

my $schema = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$filename",
    undef, undef, { RaiseError => 1, AutoCommit => 1 },
    {
        workers      => 1,
        schema_class => 'TestSchema',
        loop         => $loop
    }
);

# Use an async sub to handle the Future resolution cleanly
(async sub {
    eval {
        await $schema->deploy({ add_drop_table => 1 });

        pass("Schema deployed successfully via worker");

        # Verify deployment by attempting an insert
        my $user = await $schema->resultset('User')->create({
            name => 'deploy_bot',
            email=> 'bot@async.com',
        });

        ok($user->id, "Table 'User' exists and record was created (ID: " .
                      ($user->id // 'N/A') . ")");

        $schema->unregister_source('User');
        my $schema_class = $schema->{schema_class};

        eval { $schema_class->source('User') };
        like($@, qr/(?:is not registered|Can't find source for)/,
            "Metadata remains consistent after deployment");
    };

    if ($@) {
        if ($@ =~ /SQL::Translator/) {
            plan skip_all => "SQL::Translator required for deploy tests";
        } else {
            fail("Deployment test crashed: $@");
        }
    }

    $schema->disconnect;
    done_testing();
})->()->get; # Run the async block and wait for completion
