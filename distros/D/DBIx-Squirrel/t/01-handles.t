use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;

package My::Squirrel {
    our @ISA = 'DBIx::Squirrel';
}

package My::Squirrel::db {    ## no critic (Modules::ProhibitMultiplePackages)
    our @ISA = 'DBIx::Squirrel::db';
}

package My::Squirrel::st {    ## no critic (Modules::ProhibitMultiplePackages)
    our @ISA = 'DBIx::Squirrel::st';
}

my @source = ('dbi:SQLite:dbname=:memory:', '', '', {RaiseError => 1});

subtest 'connect returns DBIx::Squirrel handles' => sub {
    my $dbh = DBIx::Squirrel->connect(@source);
    isa_ok $dbh, ['DBIx::Squirrel::db', 'DBI::db'], 'a database handle';
    isa_ok $dbh->prepare('SELECT 1'), ['DBIx::Squirrel::st', 'DBI::st'],
        'a statement handle';
    isa_ok DBIx::Squirrel->connect($dbh), ['DBIx::Squirrel::db'],
        'a clone of a database handle';
};

subtest "a subclass's own handle classes" => sub {
    my $dbh = My::Squirrel->connect(@source);
    isa_ok $dbh, ['My::Squirrel::db', 'DBIx::Squirrel::db'],
        'a database handle';
    isa_ok $dbh->prepare('SELECT 1'),
        ['My::Squirrel::st', 'DBIx::Squirrel::st'],
        'a statement handle';
};

# The DBI's classes come first in each handle class's @ISA, so a pipe or
# tap added to the DBI would silently take the place of ours.
subtest 'pipe and tap come from DBIx::Squirrel::Pipes' => sub {
    for my $class (qw(DBIx::Squirrel::db DBIx::Squirrel::st)) {
        for my $method (qw(pipe tap)) {
            ref_is $class->can($method),
                DBIx::Squirrel::Pipes->can($method),
                "${class}->$method";
        }
    }
};

subtest "the DBI's exports" => sub {

    package Importing::SQL {    ## no critic (Modules::ProhibitMultiplePackages)
        use DBIx::Squirrel qw(:sql_types neat);
    }
    is Importing::SQL::SQL_INTEGER(), DBI::SQL_INTEGER(),
        ':sql_types, as the DBI exports it';
    is Importing::SQL::neat('x'), DBI::neat('x'), 'and a function by name';

    # The warning and the error from using a module with a tag it doesn't
    # export, both as at this file's line 100.
    my sub mistake ($module) {
        my $code = qq{#line 100 "${\ __FILE__ }"\nuse $module qw(:nonesuch); 1};
        my $error;
        my $warning = warning { $error = eval($code) ? undef : $@ };    ## no critic (BuiltinFunctions::ProhibitStringyEval)
        return [$warning, $error];
    }
    is mistake('DBIx::Squirrel'), mistake('DBI'),
        'a tag the DBI has not, reported as the DBI reports it';
    like mistake('DBIx::Squirrel')->[1], qr( \ at\ \S+\ line\ 100\. )x,
        'at the line using it';

    package Importing::Subclass {    ## no critic (Modules::ProhibitMultiplePackages)
        My::Squirrel->import(':sql_types');
    }
    ok defined &Importing::Subclass::SQL_INTEGER, 'through a subclass too';
};

done_testing;
