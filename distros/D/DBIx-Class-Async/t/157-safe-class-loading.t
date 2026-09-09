#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp;

use lib 't/lib';

use TestSchema;
use IO::Async::Loop;
use DBIx::Class::Async;
use DBIx::Class::Async::Schema;

# CPANSec CWE-94 involves the use of the dynamic class loader that allows
# the passing of dynamic values to eval "require $class". In doing this,
# there is actually a Perl code executed instead of just loading a module.
# The file thus tests the _safe_require_class() protection function but also
# assures that any unwanted schema_class value is rejected prior to the
# process of connect() invocation.

subtest '_safe_require_class rejects malformed class names' => sub {
    my $marker = "/tmp/cpansec-cwe94-unit-$$";
    unlink $marker;

    for my $payload (
        qq{1;system('touch $marker');package Evil},
        q{Foo::Bar; print "pwned"},
        q{../../etc/passwd},
        q{Foo Bar},
        q{},
    ) {
        my $ok = eval { DBIx::Class::Async::_safe_require_class($payload); 1 };
        ok(!$ok, "Rejected malformed/malicious class name: " . (length($payload) ? $payload : '(empty string)'));
    }

    ok(!-e $marker, 'No injected shell command executed via any payload');
    unlink $marker;
};

subtest '_safe_require_class loads a real, valid class name' => sub {
    my $ok = eval { DBIx::Class::Async::_safe_require_class('TestSchema::Result::User'); 1 };
    ok($ok, 'Valid, legitimate class name loads successfully') or diag $@;
    ok(TestSchema::Result::User->can('table'), 'Loaded class is actually usable');
};

subtest 'connect() rejects a malicious schema_class' => sub {
    my $marker = "/tmp/cpansec-cwe94-connect-$$";
    unlink $marker;

    my $loop             = IO::Async::Loop->new;
    my (undef, $db_file) = File::Temp::tempfile(UNLINK => 1);

    my $payload = qq{1;system('touch $marker');package Evil};

    my $schema = eval {
        DBIx::Class::Async::Schema->connect(
            "dbi:SQLite:dbname=$db_file", undef, undef, {},
            {
                workers      => 1,
                schema_class => $payload,
                async_loop   => $loop,
                cache_ttl    => 0,
            },
        );
    };
    my $err = $@;

    ok(!$schema, 'connect() did not return a usable schema for a malicious schema_class');
    ok($err, 'connect() raised an error instead');
    like($err, qr/Invalid schema_class name/, 'Error clearly identifies the invalid class name');
    ok(!-e $marker, 'No injected shell command executed as a side effect of connect()');

    unlink $marker;
};

done_testing;
