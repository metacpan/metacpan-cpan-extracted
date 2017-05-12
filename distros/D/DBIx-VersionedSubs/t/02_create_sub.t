package My::App::Test;
use lib 'eg/lib';
use base 'My::App';
__PACKAGE__->setup();

package main;
use strict;
use Test::More tests => 4;
use DBI;

my $dsn = $ENV{TEST_DBIX_VERSIONEDSUBS_DBI_DSN} || "dbi:SQLite:dbname=:memory:";

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

my $res = eval {My::App::Test::func()};
my $err = $@;
is $res,undef,"func() doesn't exist";
like $err, '/^Undefined subroutine/', "... and Perl thinks so too";

My::App::Test->init_code;

$res = eval {My::App::Test::func()};
$err = $@;
is $res,"value 1","func() exists now";
is $err, '', "... and Perl thinks so too";
