package My::App::Test;
use lib 'eg/lib';
use base 'My::App';
__PACKAGE__->setup();

sub func {
    return "original value"
}

package main;
use strict;
use Test::More tests => 9;
use DBI;

my $dsn = $ENV{TEST_MRVAIN_DBI_DSN} || "dbi:SQLite:dbname=:memory:";

#My::App::Test->setup;
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
    INSERT INTO code_live (name,code) VALUES ('func','return "value 1"');

is My::App::Test::func(),"original value","Unoverridden code works";
My::App::Test->init_code;

my $initial_db_code_version = My::App::Test->live_code_version;
is $initial_db_code_version, 0, "We start out at DB code version 0";
my $initial_perl_code_version = My::App::Test->code_version;
is $initial_perl_code_version, 0, "We start out at Perl code version 0";

is My::App::Test::func(),"value 1","Installing subroutines from init_code() works";
My::App::Test->update_sub('func','return "value 2"');
is My::App::Test::func(),"value 1","Replacing subroutines doesn't take place immediately";

cmp_ok( My::App::Test->live_code_version,">",My::App::Test->code_version,"Our version indicates a code change" );

My::App::Test->update_code;
is My::App::Test::func(),"value 2","Replacing subroutines takes place after ->update_code()";

is( My::App::Test->live_code_version,My::App::Test->code_version,"The code versions are equal" );

cmp_ok( My::App::Test->live_code_version,">",$initial_db_code_version,"Our code version increased" );
