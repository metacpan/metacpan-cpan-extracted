package My::App::Test;
use strict;
use lib 'eg/lib';
use base 'My::App';
__PACKAGE__->setup();

package main;
use strict;
use Test::More tests => 5;
use DBI;

my $dsn = $ENV{TEST_DBIX_VERSIONEDSUBS} || "dbi:SQLite:dbname=:memory:";

My::App::Test->connect($dsn);
My::App::Test->dbh->do( $_ ) for split /;\n/sm, <<'';
    CREATE TABLE code_live (name VARCHAR(64),code VARCHAR(65536));
    create table code_history (
        version integer primary key not null,
        timestamp varchar(15) not null,
        name varchar(256) not null,
        action varchar(1) not null, -- IUD, redundant with old_* and new_*
        old_code varchar(65536) not null,
        new_code varchar(65536) not null
    );
    INSERT INTO code_live (name,code) VALUES ('BEGIN','use vars qw($declared_var)');
    INSERT INTO code_live (name,code) VALUES ('test_declared_var','$declared_var++');
    INSERT INTO code_live (name,code) VALUES ('test_undeclared_var','$undeclared_var++');

my $warnings;
$SIG{__WARN__} = sub {
    $warnings .= "@_";
};

no warnings 'once';

My::App::Test->init_code;

like $warnings, '/Global symbol "\$undeclared_var" requires explicit package name /', 'The correct warnings get raised for undeclared variables';
isn't 'My::App::Test'->can('test_declared_var'), undef, "Some code was defined for 'test_declared_var'";
is 'My::App::Test'->can('test_undeclared_var'), undef, "No code was defined for 'test_undeclared_var' because of the 'strict' error";
My::App::Test::test_declared_var();
is $My::App::Test::declared_var, 1, "The declared variable got incremented";
is $My::App::Test::undeclared_var, undef, "The undeclared variable didn't get incremented";
