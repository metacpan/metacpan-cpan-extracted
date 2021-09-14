#!/usr/bin/env perl
use strict;
use warnings;

use IO::Async::Loop;
use Future::AsyncAwait;
use Scalar::Util qw(blessed);
use Database::Async;
use Database::Async::Engine::PostgreSQL;
use Log::Any::Adapter qw(Stderr), log_level => 'info';
use Log::Any qw($log);
use Syntax::Keyword::Try;

my $loop = IO::Async::Loop->new;
$loop->add(
    my $dbic = Database::Async->new(
        type => 'postgresql',
    )
);

try {
    my ($id) = await $dbic->query(
        # We don't expect this to exist, the idea is to trigger an error
        q{select * from invalid.function_name_xxxx()}
    )->single;
    warn "value was $id but we do not expect to get this far";
} catch ($e) {
    if(blessed $e and $e->isa('Protocol::Database::PostgreSQL::Error')) {
        $log->errorf('Database error %s received', $e->message);
    } else {
        $log->errorf('Generic exception %s received', $e);
    }
}

print "Done\n";

