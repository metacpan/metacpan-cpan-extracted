#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok('DBIx::Class::Async::Exception');
use_ok('DBIx::Class::Async::Exception::RelationshipAsColumn');
use_ok('DBIx::Class::Async::Exception::NotInStorage');
use_ok('DBIx::Class::Async::Exception::MissingColumn');
use_ok('DBIx::Class::Async::Exception::NoSuchRelationship');
use_ok('DBIx::Class::Async::Exception::AmbiguousColumn');
use_ok('DBIx::Class::Async::Exception::Factory');

{
    package Mock::Source;

    sub new {
        my ($class, %rels) = @_;
        bless {
            rels         => \%rels,
            result_class => 'My::Schema::Result::Operation'
        }, $class;
    }

    sub has_relationship  { exists $_[0]->{rels}{ $_[1] } }

    sub relationship_info {
        my ($self, $name) = @_;
        return unless exists $self->{rels}{$name};
        return {
            attrs => {
                accessor => $self->{rels}{$name}
            }
        };
    }

    sub result_class { shift->{result_class} }

    package Mock::Schema;

    sub new { bless { source => $_[1] }, $_[0] }

    sub sources { ('Operation') }

    sub source  {
        my ($self, $name) = @_;
        die "No such source $name\n" unless $name eq 'Operation';
        $self->{source};
    }
}

my $source = Mock::Source->new( Details => 'multi', Items => 'multi' );
my $schema = Mock::Schema->new($source);
my $RC     = 'My::Schema::Result::Operation';

subtest 'base class - throw and catch' => sub {
    throws_ok {
        DBIx::Class::Async::Exception->throw(
            message => 'Something went wrong',
            hint    => 'Try again',
        );
    } 'DBIx::Class::Async::Exception', 'throw() throws the right class';

    my $e = $@;
    is( $e->message, 'Something went wrong', 'message accessor' );
    is( $e->hint,    'Try again',            'hint accessor' );
    is( "$e",        'Something went wrong', 'stringifies to message' );
    ok( $e,                                  'boolean overload is true' );
};

subtest 'base class - rethrow preserves object identity' => sub {
    eval { DBIx::Class::Async::Exception->throw( message => 'Original' ) };
    my $original = $@;
    throws_ok { $original->rethrow } 'DBIx::Class::Async::Exception', 'rethrow throws';
    is( $@, $original, 'same object re-thrown' );
};

subtest 'base class - throw(existing_object) re-throws as-is' => sub {
    my $e = DBIx::Class::Async::Exception->new( message => 'Already built' );
    throws_ok { DBIx::Class::Async::Exception->throw($e) }
        'DBIx::Class::Async::Exception';
    is( $@, $e, 'same object re-thrown' );
};

subtest 'base class - loading base also loads full hierarchy' => sub {
    for my $subclass (qw(
        DBIx::Class::Async::Exception::RelationshipAsColumn
        DBIx::Class::Async::Exception::NotInStorage
        DBIx::Class::Async::Exception::MissingColumn
        DBIx::Class::Async::Exception::NoSuchRelationship
        DBIx::Class::Async::Exception::AmbiguousColumn
    )) {
        ok( $subclass->isa('DBIx::Class::Async::Exception'),
            "$subclass isa base class" );
    }
};

subtest 'RelationshipAsColumn - direct use and accessors' => sub {
    throws_ok {
        DBIx::Class::Async::Exception::RelationshipAsColumn->throw(
            message           => "[DBIx::Class::Async] Relationship 'Details' ...",
            relationship      => 'Details',
            relationship_type => 'multi',
            source_class      => $RC,
            operation         => 'update_or_create',
            hint              => "Omit 'Details' if no related rows.",
            original_error    => 'No such column ...',
        );
    } 'DBIx::Class::Async::Exception::RelationshipAsColumn';

    my $e = $@;
    ok( $e->isa('DBIx::Class::Async::Exception'),    'isa base class' );
    is( $e->relationship,      'Details',            'relationship accessor' );
    is( $e->relationship_type, 'multi',              'relationship_type accessor' );
    is( $e->operation,         'update_or_create',   'operation accessor' );
    like( $e->hint,            qr/Omit/,             'hint present' );
    is( $e->original_error,    'No such column ...', 'original_error preserved' );
    like( "$e",                qr/Details/,          'stringifies via message' );
};

subtest 'RelationshipAsColumn - relationship_type defaults to "relationship"' => sub {
    my $e = DBIx::Class::Async::Exception::RelationshipAsColumn->new(
        message      => 'test',
        relationship => 'Foo',
    );
    is( $e->relationship_type, 'relationship', 'default relationship_type' );
};

subtest 'NotInStorage - direct use and accessors' => sub {
    throws_ok {
        DBIx::Class::Async::Exception::NotInStorage->throw(
            message   => "[DBIx::Class::Async] Cannot update row not in storage",
            row_class => $RC,
            operation => 'update',
            hint      => 'Call insert() first.',
        );
    } 'DBIx::Class::Async::Exception::NotInStorage';

    my $e = $@;
    ok( $e->isa('DBIx::Class::Async::Exception'), 'isa base class' );
    is( $e->row_class, $RC,      'row_class accessor' );
    is( $e->operation, 'update', 'operation accessor' );
    like( $e->hint, qr/insert/i, 'hint present' );
};

subtest 'MissingColumn - direct use and accessors' => sub {
    throws_ok {
        DBIx::Class::Async::Exception::MissingColumn->throw(
            message      => "[DBIx::Class::Async] Required column 'opdate' not provided",
            column       => 'opdate',
            source_class => $RC,
            operation    => 'create',
            hint         => "Add 'opdate' to your hashref.",
        );
    } 'DBIx::Class::Async::Exception::MissingColumn';

    my $e = $@;
    ok( $e->isa('DBIx::Class::Async::Exception'), 'isa base class' );
    is( $e->column,       'opdate', 'column accessor' );
    is( $e->source_class, $RC,      'source_class accessor' );
};

subtest 'NoSuchRelationship - direct use and accessors' => sub {
    throws_ok {
        DBIx::Class::Async::Exception::NoSuchRelationship->throw(
            message      => "[DBIx::Class::Async] No relationship 'Widgets' on $RC",
            relationship => 'Widgets',
            source_class => $RC,
            hint         => "Declare it with has_many().",
        );
    } 'DBIx::Class::Async::Exception::NoSuchRelationship';

    my $e = $@;
    ok( $e->isa('DBIx::Class::Async::Exception'), 'isa base class' );
    is( $e->relationship, 'Widgets', 'relationship accessor' );
};

subtest 'AmbiguousColumn - direct use and accessors' => sub {
    throws_ok {
        DBIx::Class::Async::Exception::AmbiguousColumn->throw(
            message => "[DBIx::Class::Async] Ambiguous column 'status'",
            column  => 'status',
            hint    => "Use 'me.status'.",
        );
    } 'DBIx::Class::Async::Exception::AmbiguousColumn';

    my $e = $@;
    ok( $e->isa('DBIx::Class::Async::Exception'), 'isa base class' );
    is( $e->column, 'status', 'column accessor' );
};

subtest 'Factory - produces RelationshipAsColumn' => sub {
    my $raw = "DBIx::Class::Row::store_column(): No such column 'Details' "
            . "on My::Schema::Result::Operation at ...";

    throws_ok {
        DBIx::Class::Async::Exception::Factory->throw_from_dbic_error(
            error        => $raw,
            schema       => $schema,
            result_class => $RC,
            operation    => 'update_or_create',
        );
    } 'DBIx::Class::Async::Exception::RelationshipAsColumn';

    my $e = $@;
    is( $e->relationship,      'Details',          'relationship' );
    is( $e->relationship_type, 'multi',            'relationship_type' );
    is( $e->operation,         'update_or_create', 'operation' );
    like( $e->hint,            qr/Omit/,           'hint' );
    is( $e->original_error,    $raw,               'original_error' );
};

subtest 'Factory - genuine unknown column produces base exception' => sub {
    my $raw = "DBIx::Class::Row::store_column(): No such column 'Nonexistent' "
            . "on My::Schema::Result::Operation at ...";

    throws_ok {
        DBIx::Class::Async::Exception::Factory->throw_from_dbic_error(
            error        => $raw,
            schema       => $schema,
            result_class => $RC,
        );
    } 'DBIx::Class::Async::Exception';

    ok( !$@->isa('DBIx::Class::Async::Exception::RelationshipAsColumn'),
        'NOT a RelationshipAsColumn' );
    like( $@->hint, qr/add_columns/i, 'hints at add_columns' );
};

subtest 'Factory - not in_storage' => sub {
    throws_ok {
        DBIx::Class::Async::Exception::Factory->throw_from_dbic_error(
            error     => 'Unable to perform update on a row not in_storage',
            operation => 'update',
        );
    } 'DBIx::Class::Async::Exception::NotInStorage';
    is( $@->operation, 'update', 'operation' );
};

subtest 'Factory - ambiguous column' => sub {
    throws_ok {
        DBIx::Class::Async::Exception::Factory->throw_from_dbic_error(
            error => "Column 'status' in where clause is ambiguous",
        );
    } 'DBIx::Class::Async::Exception::AmbiguousColumn';
    is( $@->column, 'status', 'column' );
    like( $@->hint, qr/me\.status/, 'hint' );
};

subtest 'Factory - unknown error wraps in base exception' => sub {
    my $raw = 'Some completely unknown internal DBIC error XYZ-99';
    throws_ok {
        DBIx::Class::Async::Exception::Factory->throw_from_dbic_error( error => $raw );
    } 'DBIx::Class::Async::Exception';
    is( $@->original_error, $raw, 'original_error preserved' );
};

subtest 'Factory - re-throws existing Async exception as-is' => sub {
    my $existing = DBIx::Class::Async::Exception->new( message => 'Already one of ours' );
    throws_ok {
        DBIx::Class::Async::Exception::Factory->throw_from_dbic_error( error => $existing );
    } 'DBIx::Class::Async::Exception';
    is( $@, $existing, 'same object, not re-wrapped' );
};

subtest 'Factory - make_from_dbic_error returns instead of throwing' => sub {
    my $raw = "DBIx::Class::Row::store_column(): No such column 'Details' "
            . "on My::Schema::Result::Operation at ...";

    my $e = DBIx::Class::Async::Exception::Factory->make_from_dbic_error(
        error        => $raw,
        schema       => $schema,
        result_class => $RC,
    );

    ok( $e->isa('DBIx::Class::Async::Exception::RelationshipAsColumn'),
        'returns RelationshipAsColumn object' );
    is( $e->relationship, 'Details', 'relationship' );
};

subtest 'stringification returns message only, not raw internals' => sub {
    my $e = DBIx::Class::Async::Exception->new(
        message        => '[DBIx::Class::Async] Something went wrong',
        original_error => 'DBIx::Class guts at line 99 of Storage/DBI.pm',
    );
    is( "$e", '[DBIx::Class::Async] Something went wrong',
        'stringification is the friendly message, not raw guts' );
};

done_testing;
