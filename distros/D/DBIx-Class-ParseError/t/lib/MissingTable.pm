package MissingTable;

use strict;
use warnings;
use Test::Roo::Role;
use Try::Tiny;
use Test::Exception;
use Test::Deep;

with 'Storage::Setup';

around BUILDARGS => sub {
    my ($orig, $class, $args) = @_;
    $args = {
        %$args,
        sources => [qw(Bar)],
    };
    return $class->$orig($args);
};

test 'no table foo' => sub {
    my $self = shift;
    ok(my $schema = $self->schema, 'got schema');
    ok(my $bar = $schema->resultset('Bar')->create({}), 'created Bar');
    my $exception = try {
        $schema->resultset('Foo')->create({
            name => 'Foo',
            is_foo => 1,
            bar => $bar,
        })
    } catch {
        my $error_str = $_;
        my $error = $self->test_parse_error({
            desc => 'Failed to create with missing table',
            type => 'missing_table',
            table => 'foo',
            source_name => 'Foo',
            error_str => $error_str,
        });
        my $is_sqlite = $self->db_driver eq 'SQLite';
        cmp_deeply(
            $error->column_data,
            {
                bar_id => $is_sqlite ? undef : 1,
                is_foo => $is_sqlite ? undef : 1,
                name => $is_sqlite ? undef : 'Foo',
            },
            'check column data'
        );
        $error;
    };
    dies_ok { $exception->rethrow };
};

1;
