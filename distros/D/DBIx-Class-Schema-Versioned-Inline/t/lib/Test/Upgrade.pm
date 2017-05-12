package Test::Upgrade;

$ENV{DBIC_NO_VERSION_CHECK} = 1;

use Class::Unload;
use Test::Roo::Role;
use Test::Deep;
use Test::Exception;
use DBIx::Class::Schema::Loader qw/make_schema_at/;
use SQL::Translator;

my $sqlt_version = SQL::Translator->VERSION;

after each_test => sub {
    my $self = shift;
    Class::Unload->unload('Test::Schema');
};

test 'deploy 0.001' => sub {
    my $self = shift;

    diag "Test::Upgrade with " . $self->schema_class;

    # paranoia: we might not be the first test (and want no warnings from this)
    {
        local $SIG{__WARN__} = sub { };
        $self->clear_database;
    }

    no warnings 'redefine';
    local *DBIx::Class::Schema::schema_version = sub { '0.001' };

    my $schema;
    lives_ok(
        sub { $schema = $self->schema_class->connect( $self->connect_info ) },
        "Connect to schema" );

    lives_ok( sub { $schema->deploy }, "deploy schema" );

    cmp_ok( $schema->schema_version, 'eq', '0.001', "Check schema version" );
    cmp_ok( $schema->get_db_version, 'eq', '0.001', "Check db version" );

    cmp_deeply( [ $schema->sources ], [qw(Foo)], "class Foo only" );

    my $foo = $schema->source('Foo');
    cmp_deeply( [ $foo->columns ], bag(qw(foos_id height)), "Foo columns OK" );

    lives_ok(
        sub {
            $schema->populate( 'Foo',
                [ ['height'], map { [$_] } ( 1 .. 4 ), undef, undef ] );
        },
        "Insert records into Foo"
    );
    cmp_ok( $schema->resultset('Foo')->count, '==', 6, "6 Foos" );
    cmp_ok( $schema->resultset('Foo')->search( { height => undef } )->count,
        '==', 2, "2 null Foos" );

    my $aref = $schema->storage->dbh->selectall_arrayref(
        q(SELECT foos_id, height FROM foos ORDER BY foos_id ASC));
    cmp_deeply(
        $aref,
        [ [ 1, 1 ], [ 2, 2 ], [ 3, 3 ], [ 4, 4 ], [ 5, undef ], [ 6, undef ] ],
        "height values OK"
    ) || diag Dumper $aref;
};

test 'upgrade to 0.002' => sub {
    my $self = shift;

    no warnings 'redefine';
    local *DBIx::Class::Schema::schema_version = sub { '0.002' };

    my $schema = $self->schema_class->connect( $self->connect_info );

    cmp_ok( $schema->schema_version, 'eq', '0.002', "Check schema version" );
    cmp_ok( $schema->get_db_version, 'eq', '0.001', "Check db version" );

    # let's upgrade!

    lives_ok(
        sub { $schema->upgrade },
        "Upgrade " . $schema->get_db_version . " to " . $schema->schema_version
    );

    cmp_ok( $schema->get_db_version, 'eq', '0.002',
        "Check db version post upgrade" );
};

test 'test 0.002' => sub {
    my $self = shift;

    make_schema_at(
        'Test::Schema',
        {
            exclude => qr/dbix_class_schema_versions/,
            naming  => 'current',
        },
        [ $self->connect_info ],
    );

    my $schema = 'Test::Schema';

    cmp_bag( [ $schema->sources ], [qw(Bar Foo)], "Foo and Bar" );

    # columns
    my $foo = $schema->source('Foo');
    cmp_bag( [ Test::Schema::Result::Foo->columns ],
        [qw(age foos_id width)], "Foo columns OK" );
    my $bar = $schema->source('Bar');
    cmp_bag( [ $bar->columns ], [qw(bars_id weight)], "Bar columns OK" );
    cmp_ok( $schema->resultset('Foo')->count, '==', 7, "7 Foos" );
    cmp_ok( $schema->resultset('Bar')->count, '==', 1, "1 Bar" );

    my $aref = $schema->storage->dbh->selectall_arrayref(
        q(SELECT foos_id,width FROM foos ORDER BY foos_id ASC));
    cmp_deeply(
        $aref,
        [
            [ 1, 1 ], [ 2, 2 ], [ 3, 3 ], [ 4, 4 ],
            [ 5, 20 ], [ 6, 20 ], [ 7, 30 ]
        ],
        "width values OK"
    ) || diag Dumper $aref;
};

test 'upgrade to 0.003' => sub {
    my $self = shift;

    no warnings 'redefine';
    local *DBIx::Class::Schema::schema_version = sub { '0.003' };

    my $schema = $self->schema_class->connect( $self->connect_info );

    cmp_ok( $schema->schema_version, 'eq', '0.003', "Check schema version" );
    cmp_ok( $schema->get_db_version, 'eq', '0.002', "Check db version" );

    # let's upgrade!

    lives_ok(
        sub { $schema->upgrade },
        "Upgrade " . $schema->get_db_version . " to " . $schema->schema_version
    );

    cmp_ok( $schema->get_db_version, 'eq', '0.003',
        "Check db version post upgrade" );
};

test 'test 0.003' => sub {
    my $self = shift;

    make_schema_at(
        'Test::Schema',
        {
            exclude => qr/dbix_class_schema_versions/,
            naming  => 'current',
        },
        [ $self->connect_info ],
    );

    my $schema = 'Test::Schema';

    cmp_bag( [ $schema->sources ], [qw(Bar Tree)], "Tree and Bar" )
      or diag Dumper( $schema->sources );

    # columns
    my $tree = $schema->source('Tree');
    cmp_bag(
        [ Test::Schema::Result::Tree->columns ],
        [qw(age bars_id trees_id width)],
        "Tree columns OK"
    );
    my $bar = $schema->source('Bar');
    cmp_bag(
        [ $bar->columns ],
        [qw(age bars_id height weight)],
        "Bar columns OK"
    );

    my $aref = $schema->storage->dbh->selectall_arrayref(
        q(SELECT trees_id,width FROM trees ORDER BY trees_id ASC));
    cmp_deeply(
        $aref,
        [
            [ 1, 1 ],  [ 2, 2 ],  [ 3, 3 ],  [ 4, 4 ],
            [ 5, 20 ], [ 6, 20 ], [ 7, 30 ], [ 8, 40 ]
        ],
        "width values OK"
    );    # || diag Dumper $aref;
};

test 'upgrade to 0.004' => sub {
    my $self = shift;

    no warnings 'redefine';
    local *DBIx::Class::Schema::schema_version = sub { '0.004' };

    my $schema = $self->schema_class->connect( $self->connect_info );

    cmp_ok( $schema->schema_version, 'eq', '0.004', "Check schema version" );
    cmp_ok( $schema->get_db_version, 'eq', '0.003', "Check db version" );

    # let's upgrade!

    lives_ok(
        sub { $schema->upgrade },
        "Upgrade " . $schema->get_db_version . " to " . $schema->schema_version
    );

    cmp_ok( $schema->get_db_version, 'eq', '0.004',
        "Check db version post upgrade" );
};

test 'test 0.004' => sub {
    my $self = shift;

    make_schema_at(
        'Test::Schema',
        {
            exclude => qr/dbix_class_schema_versions/,
            naming  => 'current',
        },
        [ $self->connect_info ],
    );

    my $schema = 'Test::Schema';

    cmp_bag( [ $schema->sources ], [qw(Bar Tree)], "Tree and Bar" )
      or diag Dumper( $schema->sources );

    # columns
    my $tree = $schema->source('Tree');
    cmp_bag(
        [ Test::Schema::Result::Tree->columns ],
        [qw(age bars_id trees_id width)],
        "Tree columns OK"
    );
    my $bar = $schema->source('Bar');
    cmp_bag(
        [ $bar->columns ],
        [qw(age bars_id height weight)],
        "Bar columns OK"
    );
};

test 'upgrade to 0.400' => sub {
    my $self = shift;

    no warnings 'redefine';
    local *DBIx::Class::Schema::schema_version = sub { '0.400' };

    my $schema = $self->schema_class->connect( $self->connect_info );

    cmp_ok( $schema->schema_version, 'eq', '0.400', "Check schema version" );
    cmp_ok( $schema->get_db_version, 'eq', '0.004', "Check db version" );

    # let's upgrade!

    lives_ok(
        sub { $schema->upgrade },
        "Upgrade " . $schema->get_db_version . " to " . $schema->schema_version
    );

    cmp_ok( $schema->get_db_version, 'eq', '0.400',
        "Check db version post upgrade" );
};

test 'test 0.400' => sub {
    my $self = shift;

    make_schema_at(
        'Test::Schema',
        {
            exclude => qr/dbix_class_schema_versions/,
            naming  => 'current',
        },
        [ $self->connect_info ],
    );

    my $schema = 'Test::Schema';

    cmp_bag( [ $schema->sources ], [qw(Bar Tree)], "Tree and Bar" )
      or diag Dumper( $schema->sources );

    # columns
    my $tree = $schema->source('Tree');
    cmp_bag(
        [ Test::Schema::Result::Tree->columns ],
        [qw(age bars_id trees_id width)],
        "Tree columns OK"
    );
    my $bar = $schema->source('Bar');
    cmp_bag( [ $bar->columns ], [qw(age bars_id height)], "Bar columns OK" );
};

1;
