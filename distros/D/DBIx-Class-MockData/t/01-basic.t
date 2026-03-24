#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use Test::More;
use Test::Exception;

use_ok 'DBIx::Class::MockData';

# Minimal in-memory schema
# Result classes are defined inline in this file, so we register them
# directly rather than using load_classes() which tries to load them
# from disk.

{
    package TestSchema::Result::User;
    use base 'DBIx::Class::Core';
    __PACKAGE__->table('users');
    __PACKAGE__->add_columns(
        id    => { data_type => 'integer', is_auto_increment => 1 },
        name  => { data_type => 'varchar', size => 100            },
        email => { data_type => 'varchar', size => 200            },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->add_unique_constraint(unique_email => ['email']);
    __PACKAGE__->has_many(orders => 'TestSchema::Result::Order', 'user_id');
}
{
    package TestSchema::Result::Order;
    use base 'DBIx::Class::Core';
    __PACKAGE__->table('orders');
    __PACKAGE__->add_columns(
        id      => { data_type => 'integer', is_auto_increment => 1 },
        user_id => { data_type => 'integer'                         },
        amount  => { data_type => 'numeric', size => [10, 2]        },
        status  => { data_type => 'varchar', size => 20             },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to(user => 'TestSchema::Result::User', 'user_id');
}
{
    package TestSchema;
    use base 'DBIx::Class::Schema';
    __PACKAGE__->register_class('User',  'TestSchema::Result::User');
    __PACKAGE__->register_class('Order', 'TestSchema::Result::Order');
}
{
    package TestSchema::Result::User;
    use base 'DBIx::Class::Core';
    __PACKAGE__->table('users');
    __PACKAGE__->add_columns(
        id    => { data_type => 'integer', is_auto_increment => 1 },
        name  => { data_type => 'varchar', size => 100            },
        email => { data_type => 'varchar', size => 200            },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->add_unique_constraint(unique_email => ['email']);
    __PACKAGE__->has_many(orders => 'TestSchema::Result::Order', 'user_id');
}
{
    package TestSchema::Result::Order;
    use base 'DBIx::Class::Core';
    __PACKAGE__->table('orders');
    __PACKAGE__->add_columns(
        id      => { data_type => 'integer', is_auto_increment => 1 },
        user_id => { data_type => 'integer'                         },
        amount  => { data_type => 'numeric', size => [10, 2]        },
        status  => { data_type => 'varchar', size => 20             },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to(user => 'TestSchema::Result::User', 'user_id');
}

# Connect is the caller's responsibility, we just pass what connect() returns
my $schema = TestSchema->connect('dbi:SQLite::memory:');

subtest 'new() with valid args' => sub {
    my $mock = DBIx::Class::MockData->new(
        schema     => $schema,
        schema_dir => '.',
    );
    isa_ok $mock, 'DBIx::Class::MockData';
    is $mock->{rows},    5, 'default rows = 5';
    is $mock->{verbose}, 0, 'default verbose = 0';
};

subtest 'new() requires schema' => sub {
    throws_ok { DBIx::Class::MockData->new(schema_dir => '.') }
        qr/schema is required/, 'dies without schema';
    throws_ok {
        DBIx::Class::MockData->new(schema => 'not_an_object', schema_dir => '.')
    } qr/DBIx::Class::Schema instance/, 'dies with non-schema object';
};

subtest 'new() requires schema_dir' => sub {
    throws_ok { DBIx::Class::MockData->new(schema => $schema) }
        qr/schema_dir is required/, 'dies without schema_dir';
};

subtest 'deploy->generate chain' => sub {
    my $mock = DBIx::Class::MockData->new(
        schema     => $schema,
        schema_dir => '.',
        rows       => 3,
        seed       => 42,
    );

    my $ret;
    lives_ok { $ret = $mock->deploy }   'deploy lives';
    isa_ok $ret, 'DBIx::Class::MockData', 'deploy returns $self';

    lives_ok { $ret = $mock->generate } 'generate lives';
    isa_ok $ret, 'DBIx::Class::MockData', 'generate returns $self';

    is $schema->resultset('User')->count,  3, '3 users inserted';
    is $schema->resultset('Order')->count, 3, '3 orders inserted';
};

subtest 'full chain: new->wipe->generate' => sub {
    lives_ok {
        DBIx::Class::MockData
            ->new(schema => $schema, schema_dir => '.', rows => 2, seed => 7, quiet => 1,)
            ->wipe
            ->generate;
    } 'chained wipe->generate lives';

    is $schema->resultset('User')->count,  2, '2 users after wipe+generate';
    is $schema->resultset('Order')->count, 2, '2 orders after wipe+generate';
};

subtest 'unique email constraint respected' => sub {
    my @emails = $schema->resultset('User')->get_column('email')->all;
    my %seen;
    $seen{$_}++ for @emails;
    my @dupes = grep { $seen{$_} > 1 } keys %seen;
    is scalar(@dupes), 0, 'all emails are unique';
};

subtest 'FK values reference existing parents' => sub {
    my %valid_ids = map { $_ => 1 }
        $schema->resultset('User')->get_column('id')->all;
    my @order_uids = grep { defined } $schema->resultset('Order')->get_column('user_id')->all;
    my @orphans    = grep { !$valid_ids{$_} } @order_uids;
    is scalar(@orphans), 0, 'all order.user_id reference valid users';
};

subtest 'dry_run returns $self, no DB writes' => sub {
    my $before = $schema->resultset('User')->count;
    my $mock   = DBIx::Class::MockData->new(
        schema => $schema, schema_dir => '.', rows => 3);
    my $ret;
    lives_ok { $ret = $mock->dry_run } 'dry_run lives';
    isa_ok $ret, 'DBIx::Class::MockData', 'dry_run returns $self';
    is $schema->resultset('User')->count, $before, 'no rows inserted by dry_run';
};

subtest '_generate_value by data_type' => sub {
    my $mock = DBIx::Class::MockData->new(
        schema => $schema, schema_dir => '.', seed => 1);

    like $mock->_generate_value('x', { data_type => 'integer' }, 1, 0),
        qr/^\d+$/, 'integer';
    like $mock->_generate_value('x', { data_type => 'numeric' }, 1, 0),
        qr/^\d+\.\d{1,2}$/, 'numeric';
    ok do { my $v = $mock->_generate_value('x', {data_type=>'boolean'}, 1, 0);
            $v == 0 || $v == 1 }, 'boolean is 0 or 1';
    like $mock->_generate_value('x', { data_type => 'datetime' }, 1, 0),
        qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/, 'datetime';
    like $mock->_generate_value('x', { data_type => 'date' }, 1, 0),
        qr/^\d{4}-\d{2}-\d{2}$/, 'date';
    like $mock->_generate_value('email', { data_type => 'varchar', size => 100 }, 1, 0),
        qr/\@example\.com$/, 'email column name gives email value';
};

subtest 'unique values include salt' => sub {
    my $mock = DBIx::Class::MockData->new(
        schema => $schema, schema_dir => '.', seed => 42);
    my $salt = $mock->{_salt};

    my $sv = $mock->_generate_value('email', { data_type => 'varchar', size => 50 }, 1, 1);
    like $sv, qr/$salt/, 'unique varchar includes salt';

    my $iv = $mock->_generate_value('id', { data_type => 'integer' }, 1, 1);
    is $iv, $salt + 1, 'unique integer = salt + row_num';
};

done_testing;
