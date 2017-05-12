package My::App::Test;
use strict;
use lib 'eg/lib';
use base 'My::App';
__PACKAGE__->setup();

package main;
use strict;
use Test::More tests => 2;
use DBI;
use vars qw($t_package_begin_block);

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
    INSERT INTO code_live (name,code) VALUES ('BEGIN','$::t_package_begin_block = __PACKAGE__;');
    INSERT INTO code_live (name,code) VALUES ('get_package_declaration','return __PACKAGE__;');

My::App::Test->init_code;

is $t_package_begin_block, 'My::App::Test', "BEGIN block runs in correct package";
is My::App::Test::get_package_declaration(), 'My::App::Test', "DB-subroutine runs in correct package";

