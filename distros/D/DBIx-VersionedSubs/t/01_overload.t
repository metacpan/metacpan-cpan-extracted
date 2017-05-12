package My::App::Test;
use lib 'eg/lib';

use base 'My::App';
__PACKAGE__->setup();

sub func {
    return "value 1";
};

package main;
use strict;
use Test::More tests => 3;
use DBI;

my $dsn = $ENV{TEST_DBIX_VERSIONEDSUBS_DBI_DSN} || "dbi:SQLite:dbname=:memory:";

if (-f "$0.sqlite") {
    unlink "$0.sqlite" or diag "Couldn't unlink '$0.sqlite': $!";
}

My::App::Test->connect($dsn);
My::App::Test->dbh->do( $_ ) for split /;\n/sm, <<"";
    CREATE TABLE code_live (name VARCHAR(64),code VARCHAR(65536));
    create table code_history (
        version integer primary key not null,
        timestamp varchar(15) not null,
        name varchar(256) not null,
        action varchar(1) not null, -- IUD, redundant with old_* and new_*
        old_code varchar(65536) not null,
        new_code varchar(65536) not null
    );
    INSERT INTO code_live (name,code) VALUES ('func','return "value 2"');

my $old_func = \&My::App::Test::func;
is My::App::Test::func(), 'value 1',"Builtin code gets called";

My::App::Test->init_code;

isn't \&My::App::Test::func, $old_func, "Function address has changed";
is My::App::Test::func(), 'value 2', "New code from database gets called";
