package Op::Update;

use strict;
use warnings;
use Test::Roo::Role;
use Try::Tiny;
use Test::Deep;
use Test::Exception;

with 'Storage::Setup';
requires 'should_skip';

has [qw(_foo _bar)] => ( is => 'rw' );

after setup => sub {
    my $self = shift;
    ok(my $schema = $self->schema, 'got schema');
    ok($self->_bar( $schema->resultset('Bar')->create({}) ), 'created Bar');
    ok( $self->_foo( $schema->resultset('Foo')->create({
        name => 'Foo',
        is_foo => 1,
        bar => $self->_bar,
    }) ), 'created Foo' );
};

test 'row->update' => sub {
    my $self = shift;
    my $row = $self->_foo;
    my $new_name = 'Bar';
    ok( $row->update({ name => $new_name }), 'updated Foo' );
    is($row->name, $new_name, 'updated to Bar');
};

my $time = time();

test 'primary key' => sub {
    my $self = shift;
    ok( my $new_row = $self->schema->resultset('Foo')->new({
        name => 'Foo' . $time++,
        is_foo => 1,
        bar => $self->_bar,
    })->insert, 'created new Foo' );
    my $exception = try {
        $new_row->update({ id => $self->_foo->id })
    } catch {
        my $error_str = $_;
        my $error = $self->test_parse_error({
            desc => 'Failed to update with duplicated PK',
            type => 'primary_key',
            table => 'foo',
            source_name => 'Foo',
            error_str => $error_str,
        });
        cmp_deeply($error->columns, [qw(id)], 'target column');
        cmp_deeply(
            $error->column_data,
            {
                id => 1,
            },
            'check column data'
        );
        $new_row->discard_changes;
        $error;
    };
    dies_ok { $exception->rethrow };
};

test 'foreign key' => sub {
    my $self = shift;
    ok(my $foo = $self->_foo, 'got Foo');
    my $exception = try {
        $foo->update({ bar_id => 1000 })
    } catch {
        my $error_str = $_;
        my $error = $self->test_parse_error({
            desc => 'Failed to update with invalid FK',
            type => 'foreign_key',
            table => 'foo',
            source_name => 'Foo',
            error_str => $error_str,
        });
        cmp_deeply($error->columns, [qw(bar_id)], 'target column');
        cmp_deeply(
            $error->column_data,
            {
                bar_id => 1000,
            },
            'check column data'
        );
        $foo->discard_changes;
        $error;
    };
    dies_ok { $exception->rethrow };
};

test 'not null' => sub {
    my $self = shift;
    ok(my $foo = $self->_foo, 'got Foo');
    my $exception = try {
        $foo->update({ name => undef })
    } catch {
        my $error_str = $_;
        my $error = $self->test_parse_error({
            desc => 'Failed to update with NULL on not null',
            type => 'not_null',
            table => 'foo',
            source_name => 'Foo',
            error_str => $error_str,
        });
        cmp_deeply($error->columns, [qw(name)], 'target column');
        cmp_deeply(
            $error->column_data,
            {
                name => undef,
            },
            'check column data'
        );
        $foo->discard_changes;
        $error;
    };
    dies_ok { $exception->rethrow };
};

test 'data type' => sub {
    my $self = shift;
    ok(my $foo = $self->_foo, 'got Foo');
    my $exception = try {
        $foo->update({ is_foo => 'text value' })
    } catch {
        my $error_str = $_;
        my $error = $self->test_parse_error({
            desc => 'Failed to update with invalid data type',
            type => 'data_type',
            table => 'foo',
            source_name => 'Foo',
            error_str => $error_str,
        });
        if ( my $reason = $self->should_skip('data_type', 'columns') ) {
            SKIP: {
                skip $reason, 1;
                cmp_deeply($error->columns, [qw(is_foo)], 'target column');
            }
        }
        cmp_deeply(
            $error->column_data,
            {
                is_foo => 'text value',
            },
            'check column data'
        );
        $foo->discard_changes;
        $error;
    };
    dies_ok { $exception->rethrow };
};

test 'missing column' => sub {
    my $self = shift;
    ok(my $foo = $self->_foo, 'got Foo');
    my $exception = try {
        $foo->update({ baz => 1000 })
    } catch {
        my $error_str = $_;
        my $error = $self->test_parse_error({
            desc => 'Failed to update with missing column',
            type => 'missing_column',
            table => 'foo',
            source_name => 'Foo',
            error_str => $error_str,
        });
        cmp_deeply(
            $error->columns, [qw(baz)],
        );
        $foo->discard_changes;
        $error;
    };
    dies_ok { $exception->rethrow };
};

test 'resultset update' => sub {
    my $self = shift;
    my $exception = try {
        $self->schema->resultset('Foo')->update({ id => 1, name => 'Foo' })
    } catch {
        my $error_str = $_;
        my $error = $self->test_parse_error({
            desc => 'Failed to update a resultset',
            type => 'primary_key',
            table => 'foo',
            source_name => 'Foo',
            error_str => $error_str,
        });
        cmp_deeply($error->columns, [ any(qw/id name/) ], 'target column');
        cmp_deeply(
            $error->column_data,
            {
                id => 1,
                name => 'Foo',
            },
            'check column data'
        );
        $error;
    };
    dies_ok { $exception->rethrow };
};

1;
