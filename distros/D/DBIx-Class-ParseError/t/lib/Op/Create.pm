package Op::Create;

use strict;
use warnings;
use Test::Roo::Role;
use Try::Tiny;
use Test::Exception;
use Test::Deep;

with 'Storage::Setup';

has _bar => ( is => 'rw' );

test 'rs->create' => sub {
    my $self = shift;
    ok(my $schema = $self->schema, 'got schema');
    ok($self->_bar( $schema->resultset('Bar')->create({}) ), 'created Bar');
    ok( $schema->resultset('Foo')->create({
        name => 'Foo',
        is_foo => 1,
        bar => $self->_bar,
    }), 'created Foo' );
};

my $time = time();

test 'primary key' => sub {
    my $self = shift;
    ok(my $schema = $self->schema, 'got schema');
    my $exception = try {
        my $foo = $schema->resultset('Foo')->new({
            id => 1,
            name => 'Foo' . $time++,
            is_foo => 1,
            bar => $self->_bar,
        });
        $foo->insert;
    } catch {
        my $error_str = $_;
        my $error = $self->test_parse_error({
            desc => 'Failed to create with duplicated PK',
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
                bar_id => 1,
                is_foo => 1,
                name => re('^Foo'),
            },
            'check column data'
        );
        $error;
    };
    dies_ok { $exception->rethrow };
};

test 'foreign key' => sub {
    my $self = shift;
    ok(my $schema = $self->schema, 'got schema');
    my $exception = try {
        $schema->resultset('Foo')->create({
            name => 'Foo' . $time++,
            is_foo => 1,
            bar_id => 1000
        });
    } catch {
        my $error_str = $_;
        my $error = $self->test_parse_error({
            desc => 'Failed to create with invalid FK',
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
                is_foo => 1,
                name => re('^Foo'),
            },
            'check column data'
        );
        $error;
    };
    dies_ok { $exception->rethrow };
};

test 'unique key' => sub {
    my $self = shift;
    ok(my $schema = $self->schema, 'got schema');
    my $exception = try {
        $schema->resultset('Foo')->create({
            name => 'Foo',
            is_foo => 1,
            bar => $self->_bar,
        })
    } catch {
        my $error_str = $_;
        my $error = $self->test_parse_error({
            desc => 'Failed to create with duplicated name',
            type => 'unique_key',
            table => 'foo',
            source_name => 'Foo',
            error_str => $error_str,
        });
        cmp_deeply($error->columns, [qw(name)], 'target column');
        cmp_deeply(
            $error->column_data,
            {
                bar_id => 1,
                is_foo => 1,
                name => 'Foo',
            },
            'check column data'
        );
        $error;
    };
    dies_ok { $exception->rethrow };
};

test 'composed unique key' => sub {
    my $self = shift;
    ok(my $schema = $self->schema, 'got schema');
    my $exception = try {
        $schema->resultset('Baz')->create({
            name => 'Foo',
            other_name => 'Foo',
        })
    } catch {
        my $error_str = $_;
        my $error = $self->test_parse_error({
            desc => 'Failed to create with duplicated name/other_name',
            type => 'unique_key',
            table => 'foo',
            source_name => 'Foo',
            error_str => $error_str,
        });
        cmp_deeply($error->columns, [qw(name other_name)], 'target column');
        cmp_deeply(
            $error->column_data,
            {
                name => 'Foo',
                other_name => 'Foo',
            },
            'check column data'
        );
        $error;
    };
    dies_ok { $exception->rethrow };
};

test 'not null' => sub {
    my $self = shift;
    ok(my $schema = $self->schema, 'got schema');
    my $test_column_data = sub {
        my ($error, $data) = @_;
        cmp_deeply(
            $error->column_data, $data,
            'check column data'
        );
    };
    my $test_parse_error = sub {
        my $error_str = shift;
        my $error = $self->test_parse_error({
            desc => 'Failed to create with NULL on not null',
            type => 'not_null',
            table => 'foo',
            source_name => 'Foo',
            error_str => $error_str,
        });
    };

    my $exception = try {
        $schema->resultset('Foo')->create({
            name => undef,
            is_foo => 1,
            bar => $self->_bar,
        })
    } catch {
        my $error = $test_parse_error->($_);
        cmp_deeply($error->columns, [qw(name)], 'target column');
        $test_column_data->($error, {
            bar_id => 1,
            is_foo => 1,
            name => undef,
        });
        $error;
    };
    dies_ok { $exception->rethrow };
    try {
        $schema->resultset('Foo')->create({
            is_foo => 1,
            bar => $self->_bar,
        })
    } catch {
        my $error = $test_parse_error->($_);
        cmp_deeply($error->columns, [qw(name)], 'target column');
        $test_column_data->($error, {
            bar_id => 1,
            is_foo => 1,
        });
        $error;
    };
};

test 'data type' => sub {
    my $self = shift;
    ok(my $schema = $self->schema, 'got schema');
    my $exception = try {
        $schema->resultset('Foo')->create({
            name => 'Foo' . $time++,
            is_foo => 'text value',
            bar => $self->_bar,
        })
    } catch {
        my $error_str = $_;
        my $error = $self->test_parse_error({
            desc => 'Failed to create with invalid data type',
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
                bar_id => 1,
                is_foo => 'text value',
                name => re('^Foo'),
            },
            'check column data'
        );
        $error;
    };
    dies_ok { $exception->rethrow };
};

test 'missing column' => sub {
    my $self = shift;
    ok(my $schema = $self->schema, 'got schema');
    my $test_columns = sub {
        my ($error, $data) = @_;
        cmp_deeply(
            $error->columns, $data,
            'check columns'
        );
    };
    my $test_parse_error = sub {
        my $error_str = shift;
        my $error = $self->test_parse_error({
            desc => 'Failed to create with missing column',
            type => 'missing_column',
            table => 'foo',
            source_name => 'Foo',
            error_str => $error_str,
        });
    };

    my $exception = try {
        $schema->resultset('Foo')->create({
            name => 'Foo' . $time++,
            is_foo => 1,
            baz => 1000
        })
    } catch {
        my $error_str = $_;
        my $error = $test_parse_error->($error_str);
        $test_columns->($error, [qw(baz)]);
        $error;
    };
    dies_ok { $exception->rethrow };
    try {
        $schema->resultset('Foo')->create({
            name => 'Foo' . $time++,
            is_foo => 1,
            baz => 1000,
            buzz => 100,
        })
    } catch {
        my $error_str = $_;
        my $error = $test_parse_error->($error_str);
        $test_columns->($error, [ any(qw/baz buzz/) ]);
        $error;
    };
    dies_ok { $exception->rethrow };
};

1;
