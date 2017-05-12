package Test::Deploy;

$ENV{DBIC_NO_VERSION_CHECK} = 1;

use Data::Dumper;
use Test::Roo::Role;
use Test::Deep;
use Test::Exception;
use version 0.77;

my @column_noise = (qw(till until since changes renamed_from versioned));
my @relation_noise = ( @column_noise, qw(is_depends_on) );

sub cmp_table {
    my ( $class, $columns, $relations ) = @_;
    my $name = $class->source_name;

    cmp_deeply( [ $class->columns ], bag( keys %$columns ), "$name columns" );

    foreach my $column ( $class->columns ) {
        my %got = %{ $class->column_info($column) };
        foreach my $i (@column_noise) {
            delete $got{$i};
        }
        cmp_deeply( \%got, $columns->{$column}, "$name column $column" );
    }

    if ($relations) {
        cmp_deeply(
            [ $class->relationships ],
            bag( keys %$relations ),
            "$name relations"
        );

        foreach my $rel ( $class->relationships ) {
            my %got = %{ $class->relationship_info($rel) };
            foreach my $i (@relation_noise) {
                delete $got{attrs}->{$i};
            }
            cmp_deeply( \%got, $relations->{$rel}, "$name relation $rel" );
        }
    }
}

test 'deploy v0.001' => sub {
    my $self = shift;

    {

        # Pg can be noisy on stop if we stop it too soon after starting
        local $SIG{__WARN__} = sub { };
        $self->clear_database;
    }

    diag "Test::Deploy with " . $self->schema_class;

    no warnings 'redefine';
    local *DBIx::Class::Schema::schema_version = sub { '0.001' };

    my $schema;
    lives_ok(
        sub { $schema = $self->schema_class->connect( $self->connect_info ) },
        "Connect to schema" );

    my @versions = ( '0.001', '0.002', '0.003', '0.004', '0.400' );

    cmp_ok( $schema->schema_version, 'eq', '0.001', "Check schema version" );
    cmp_ok( $schema->get_db_version, '==', 0, "db version not defined yet" );

    lives_ok( sub { $schema->deploy }, "deploy schema" );
    cmp_ok( $schema->get_db_version, 'eq', '0.001', "Check db version" );

    cmp_deeply( [ $schema->stringified_ordered_schema_versions ],
        \@versions, "Check we found all expected versions" )
      || (diag "got: "
        . join( " ", $schema->stringified_ordered_schema_versions )
        . "\nexpect: "
        . join( " ", @versions ) );

    # tables
    cmp_deeply( [ $schema->sources ], bag(qw(Foo)), "class Foo only" );

    # column info
    my $foo_columns = {
        foos_id => {
            data_type         => 'integer',
            is_auto_increment => 1
        },
        height => {
            data_type   => "integer",
            is_nullable => 1,
        }
    };
    cmp_table( $schema->source('Foo'), $foo_columns );
};

test 'deploy v0.002' => sub {
    my $self = shift;
    $self->clear_database;

    no warnings 'redefine';
    local *DBIx::Class::Schema::schema_version = sub { '0.002' };

    my $schema = $self->schema_class->connect( $self->connect_info );

    my @versions = ( '0.001', '0.002', '0.003', '0.004', '0.400' );

    cmp_ok( $schema->schema_version, 'eq', '0.002', "Check schema version" );
    cmp_ok( $schema->get_db_version, '==', 0, "db version not defined yet" );

    lives_ok( sub { $schema->deploy }, "deploy schema" );
    cmp_ok( $schema->get_db_version, 'eq', '0.002', "Check db version" );

    cmp_deeply( [ $schema->stringified_ordered_schema_versions ],
        \@versions, "Check we found all expected versions" )
      || (diag "got: "
        . join( " ", $schema->stringified_ordered_schema_versions )
        . "\nexpect: "
        . join( " ", @versions ) );

    # tables
    cmp_deeply( [ $schema->sources ], bag(qw(Bar Foo)), "Bar and Foo" );

    # column info & relations
    my $bar_columns = {
        bars_id => {
            data_type         => "integer",
            is_auto_increment => 1
        },
        weight => {
            data_type   => "integer",
            is_nullable => 1,
        }
    };
    my $foo_columns = {
        foos_id => {
            data_type         => 'integer',
            is_auto_increment => 1
        },
        age => {
            data_type   => "integer",
            is_nullable => 1,
        },
        width => {
            data_type     => "integer",
            is_nullable   => 0,
            default_value => 1,
        },
    };
    cmp_table( $schema->source('Bar'), $bar_columns );
    cmp_table( $schema->source('Foo'), $foo_columns );
};

test 'deploy v0.003' => sub {
    my $self = shift;
    $self->clear_database;

    no warnings 'redefine';
    local *DBIx::Class::Schema::schema_version = sub { '0.003' };

    my $schema = $self->schema_class->connect( $self->connect_info );

    my @versions = ( '0.001', '0.002', '0.003', '0.004', '0.400' );

    cmp_ok( $schema->schema_version, 'eq', '0.003', "Check schema version" );
    cmp_ok( $schema->get_db_version, '==', 0, "db version not defined yet" );

    lives_ok( sub { $schema->deploy }, "deploy schema" );
    cmp_ok( $schema->get_db_version, 'eq', '0.003', "Check db version" );

    cmp_deeply( [ $schema->stringified_ordered_schema_versions ],
        \@versions, "Check we found all expected versions" )
      || (diag "got: "
        . join( " ", $schema->stringified_ordered_schema_versions )
        . "\nexpect: "
        . join( " ", @versions ) );

    # tables

    cmp_deeply( [ $schema->sources ], bag(qw(Bar Tree)), "Bar and Tree" );

    # column info & relations
    my $bar_columns = {
        bars_id => {
            data_type         => "integer",
            is_auto_increment => 1
        },
        age => {
            data_type   => "integer",
            is_nullable => 1,
        },
        height => {
            data_type   => "integer",
            is_nullable => 1,
        },
        weight => {
            data_type   => "integer",
            is_nullable => 1,
        }
    };
    my $tree_columns = {
        "trees_id" => {
            data_type         => 'integer',
            is_auto_increment => 1,
        },
        "age" => { data_type => "integer", is_nullable => 1 },
        "width" =>
          { data_type => "integer", is_nullable => 0, default_value => 1 },
        "bars_id" =>
          { data_type => 'integer', is_foreign_key => 1, is_nullable => 1 },
    };
    my $bar_relations = {
        trees => {
            attrs => {
                accessor       => "multi",
                cascade_copy   => 1,
                cascade_delete => 1,
                join_type      => "LEFT",
            },
            class  => $self->schema_class . "::Result::Tree",
            cond   => { "foreign.bars_id" => "self.bars_id" },
            source => $self->schema_class . "::Result::Tree"
        }
    };
    my $tree_relations = {
        bar => {
            attrs => {
                accessor                  => "single",
                fk_columns                => { bars_id => 1 },
                is_foreign_key_constraint => 1,
                undef_on_null_fk          => 1,
            },
            class  => $self->schema_class . "::Result::Bar",
            cond   => { "foreign.bars_id" => "self.bars_id" },
            source => $self->schema_class . "::Result::Bar"
        }
    };
    cmp_table( $schema->source('Bar'),  $bar_columns,  $bar_relations );
    cmp_table( $schema->source('Tree'), $tree_columns, $tree_relations );
};

test 'deploy v0.004' => sub {
    my $self = shift;
    $self->clear_database;

    no warnings 'redefine';
    local *DBIx::Class::Schema::schema_version = sub { '0.004' };

    my $schema = $self->schema_class->connect( $self->connect_info );

    my @versions = ( '0.001', '0.002', '0.003', '0.004', '0.400' );

    cmp_ok( $schema->schema_version, 'eq', '0.004', "Check schema version" );
    cmp_ok( $schema->get_db_version, '==', 0, "db version not defined yet" );

    lives_ok( sub { $schema->deploy }, "deploy schema" );
    cmp_ok( $schema->get_db_version, 'eq', '0.004', "Check db version" );

    cmp_deeply( [ $schema->stringified_ordered_schema_versions ],
        \@versions, "Check we found all expected versions" )
      || (diag "got: "
        . join( " ", $schema->stringified_ordered_schema_versions )
        . "\nexpect: "
        . join( " ", @versions ) );

    # tables
    cmp_deeply( [ $schema->sources ], bag(qw(Bar Tree)), "Bar and Tree" );

    # column info & relations
    my $bar_columns = {
        bars_id => {
            data_type         => "integer",
            is_auto_increment => 1
        },
        age => {
            data_type     => "integer",
            is_nullable   => 0,
            default_value => 18
        },
        height => {
            data_type   => "integer",
            is_nullable => 1,
        },
        weight => {
            data_type   => "integer",
            is_nullable => 1,
        },
    };
    my $tree_columns = {
        "trees_id" => {
            data_type         => 'integer',
            is_auto_increment => 1,
        },
        "age" => { data_type => "integer", is_nullable => 1 },
        "width" =>
          { data_type => "integer", is_nullable => 0, default_value => 1 },
        "bars_id" =>
          { data_type => 'integer', is_foreign_key => 1, is_nullable => 1 },
    };
    my $bar_relations = {
        trees => {
            attrs => {
                accessor       => "multi",
                cascade_copy   => 1,
                cascade_delete => 1,
                join_type      => "LEFT",
            },
            class  => $self->schema_class . "::Result::Tree",
            cond   => { "foreign.bars_id" => "self.bars_id" },
            source => $self->schema_class . "::Result::Tree"
        }
    };
    my $tree_relations = {
        bar => {
            attrs => {
                accessor                  => "single",
                fk_columns                => { bars_id => 1 },
                is_foreign_key_constraint => 1,
                undef_on_null_fk          => 1,
            },
            class  => $self->schema_class . "::Result::Bar",
            cond   => { "foreign.bars_id" => "self.bars_id" },
            source => $self->schema_class . "::Result::Bar"
        }
    };
    cmp_table( $schema->source('Bar'),  $bar_columns,  $bar_relations );
    cmp_table( $schema->source('Tree'), $tree_columns, $tree_relations );
};

test 'deploy v0.400' => sub {
    my $self = shift;
    $self->clear_database;

    no warnings 'redefine';
    local *DBIx::Class::Schema::schema_version = sub { '0.400' };

    my $schema = $self->schema_class->connect( $self->connect_info );

    my @versions = ( '0.001', '0.002', '0.003', '0.004', '0.400' );

    cmp_ok( $schema->schema_version, 'eq', '0.400', "Check schema version" );
    cmp_ok( $schema->get_db_version, '==', 0, "db version not defined yet" );

    lives_ok( sub { $schema->deploy }, "deploy schema" );
    cmp_ok( $schema->get_db_version, 'eq', '0.400', "Check db version" );

    cmp_deeply( [ $schema->stringified_ordered_schema_versions ],
        \@versions, "Check we found all expected versions" )
      || (diag "got: "
        . join( " ", $schema->stringified_ordered_schema_versions )
        . "\nexpect: "
        . join( " ", @versions ) );

    # tables
    cmp_deeply( [ $schema->sources ], bag(qw(Bar Tree)), "Bar and Tree" );

    # column info & relations
    my $bar_columns = {
        bars_id => {
            data_type         => "integer",
            is_auto_increment => 1
        },
        age => {
            data_type     => "integer",
            is_nullable   => 0,
            default_value => 18
        },
        height => {
            data_type   => "integer",
            is_nullable => 1,
        },
    };
    my $tree_columns = {
        "trees_id" => {
            data_type         => 'integer',
            is_auto_increment => 1,
        },
        "age" => { data_type => "integer", is_nullable => 1 },
        "width" =>
          { data_type => "integer", is_nullable => 0, default_value => 1 },
        "bars_id" =>
          { data_type => 'integer', is_foreign_key => 1, is_nullable => 1 },
    };
    my $bar_relations = {
        trees => {
            attrs => {
                accessor       => "multi",
                cascade_copy   => 1,
                cascade_delete => 1,
                join_type      => "LEFT",
            },
            class  => $self->schema_class . "::Result::Tree",
            cond   => { "foreign.bars_id" => "self.bars_id" },
            source => $self->schema_class . "::Result::Tree"
        }
    };
    my $tree_relations = {
        bar => {
            attrs => {
                accessor                  => "single",
                fk_columns                => { bars_id => 1 },
                is_foreign_key_constraint => 1,
                undef_on_null_fk          => 1,
            },
            class  => $self->schema_class . "::Result::Bar",
            cond   => { "foreign.bars_id" => "self.bars_id" },
            source => $self->schema_class . "::Result::Bar"
        }
    };
    cmp_table( $schema->source('Bar'),  $bar_columns,  $bar_relations );
    cmp_table( $schema->source('Tree'), $tree_columns, $tree_relations );
};

1;
