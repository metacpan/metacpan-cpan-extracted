#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use IO::Async::Loop;
use File::Temp qw(tempfile);
use DBIx::Class::Async::Schema;

use lib 't/lib';
use TestSchema;

my $loop = IO::Async::Loop->new;
my ($fh, $db_file) = tempfile(UNLINK => 1);

my $schema = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$db_file",
    undef, undef, { RaiseError => 1 },
    { workers => 1, schema_class => 'TestSchema', loop => $loop }
);

my $rs = $schema->resultset('User');

# 1. Define a custom class that adds a specific method
{
    package My::Custom::User;
    use parent 'DBIx::Class::Async::Row';

    sub hello_name {
        my $self = shift;
        return "Hello, " . $self->get_column('name');
    }
}

subtest "Result Class Overrides" => sub {
    # 2. Tell the ResultSet to use our custom class
    my $custom_rs = $rs->search({}, { result_class => 'My::Custom::User' });

    is($custom_rs->result_class, 'My::Custom::User', "result_class accessor returns custom class");

    # 3. Manually trigger new_result
    my $row = $custom_rs->new_result({ name => 'John', id => 1 });

    isa_ok($row, 'My::Custom::User', "Row object is instance of custom class");
    isa_ok($row, 'DBIx::Class::Async::Row', "Row object still inherits from base Row");

    # 4. Verify custom logic works
    is($row->hello_name, "Hello, John", "Custom method logic works");
    is($row->get_column('id'), 1, "Standard column data is still accessible");
};

subtest "Chaining behavior" => sub {
    my $rs_chained = $rs->result_class('My::Custom::User');
    my $rs_next = $rs_chained->search({ active => 1 });

    is($rs_next->result_class, 'My::Custom::User', "result_class persists across searches");
};

done_testing();
