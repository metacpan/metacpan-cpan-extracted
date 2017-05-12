package My::App::Test;
use lib 'eg/lib';
use base 'My::App';
__PACKAGE__->setup();

package main;
use strict;
use Test::More tests => 3;
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
    INSERT INTO code_live (name,code) VALUES ('BEGIN','$::block_was_run{BEGIN}++');
    INSERT INTO code_live (name,code) VALUES ('INIT','$::block_was_run{INIT}++');
    INSERT INTO code_live (name,code) VALUES ('CHECK','$::block_was_run{CHECK}++');

use vars qw(%block_was_run);

My::App::Test->init_code;
is $block_was_run{BEGIN}, 1, "BEGIN block runs once at init_code() time";
is $block_was_run{INIT}, undef, "INIT block was not run at init_code() time";
is $block_was_run{CHECK}, undef, "CHECK block was not run at init_code() time";
