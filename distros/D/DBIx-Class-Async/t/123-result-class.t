#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp;
use IO::Async::Loop;
use DBIx::Class::Async::Schema;

use lib 't/lib';

my $loop           = IO::Async::Loop->new;
my ($fh, $db_file) = File::Temp::tempfile(SUFFIX => '.db', UNLINK => 1);
my $schema         = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$db_file", undef, undef, {},
    { workers      => 2,
      schema_class => 'TestSchema',
      async_loop   => $loop,
      cache_ttl    => 60,
    },
);

$schema->await($schema->deploy({ add_drop_table => 1 }));

# CUSTOM CLASS DEFINITION
{
    package My::Custom::User;
    use parent 'DBIx::Class::Async::Row';

    sub hello_name {
        my $self = shift;
        # Note: get_column works because DBIx::Class::Async::Row provides it
        return "Hello, " . $self->get_column('name');
    }
}

subtest "Schema class() method" => sub {
    my $class_name = eval { $schema->class('User') };
    diag $@ if $@;

    ok($class_name, "Fetched class name for 'User'");
    is($class_name, 'TestSchema::Result::User', "Default class name matches TestSchema definition");
};

subtest "Result Class Overrides" => sub {
    my $rs = $schema->resultset('User');

    # OVERRIDE via search attributes
    my $custom_rs = $rs->search({}, { result_class => 'My::Custom::User' });

    is($custom_rs->result_class, 'My::Custom::User', "result_class accessor returns the override");

    # TEST THE HYBRID BLISSING
    my $row = $custom_rs->new_result({ name => 'John', id => 1 });

    isa_ok($row, 'My::Custom::User', "Row object 'isa' custom class");
    isa_ok($row, 'DBIx::Class::Async::Row', "Row object 'isa' Async::Row base class");

    # Check if the anon class name followed our rule
    like(ref($row), qr/^DBIx::Class::Async::Anon::/, "Row is blessed into the hybrid anonymous namespace");

    # 6. VERIFY CUSTOM LOGIC
    is($row->hello_name, "Hello, John", "Custom method 'hello_name' executed correctly");
    is($row->get_column('id'), 1, "Standard column data is still accessible");
};

subtest "Chaining and Immutability" => sub {
    my $rs = $schema->resultset('User');

    my $rs_chained = $rs->result_class('My::Custom::User');

    ok($rs_chained != $rs, "ResultSet is cloned, not modified in place");
    is($rs->result_class, 'TestSchema::Result::User', "Original RS remains untouched");
    is($rs_chained->result_class, 'My::Custom::User', "Chained RS has the override");

    my $rs_next = $rs_chained->search({ active => 1 });
    is($rs_next->result_class, 'My::Custom::User', "result_class persists across chained searches");
};

subtest "Schema class() method Integration" => sub {
    my $class_name = $schema->class('User');
    is($class_name, 'TestSchema::Result::User', "Direct class() call returns correct string");

    my $rs = $schema->resultset('User');
    is($rs->result_class, $class_name, "ResultSet correctly inherited class name via Schema::class()");

    eval { $schema->class('NonExistentSource') };
    like($@, qr/No such source/, "class() croaks correctly on invalid source");
};

subtest "Malicious result_class is rejected, not executed (CPANSec CWE-94)" => sub {
    # SECURITY: The class name was utilised here to evaluate "require $target_class,"
    # so the text was run as Perl code. The exploit involved crafting a
    # string composed of a class name followed by Perl commands separated by
    # semicolons. Thus, code execution would occur when loading the records.
    # The specific instance was guarded by an unrelated always-true
    # condition, however, the risk was present at other possible points in
    # the code. A fix has been implemented that checks result_class for a
    # valid Perl package format beforehand and uses a secure method for
    # loading.
    my $marker = "/tmp/cpansec-cwe94-marker-$$";
    unlink $marker;

    my $payload = qq{1;system('touch $marker');package Evil};

    my $rs = $schema->resultset('User')->result_class($payload);

    my $result = eval {
        $schema->await($rs->create({ name => 'x', email => 'cwe94@test.com' }));
    };
    my $err = $@;

    ok($err, "Malicious result_class string is rejected with an error");
    like($err, qr/Invalid (?:result_class|class) name/,
        "Rejected specifically for looking like an invalid class name");
    ok(!-e $marker, "No injected code executed as a side effect");

    unlink $marker;
};

$schema->disconnect;

done_testing;
