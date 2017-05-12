BEGIN{
    use DBIx::VersionedSubs::Hash;
    use lib 'eg/lib';
    use My::App;
    no warnings 'once';
    @My::App::ISA = qw(DBIx::VersionedSubs::Hash);
};

package My::App::Test;
use lib 'eg/lib';
use base 'My::App';

package main;
use strict;
use Test::More tests => 6;
use DBI;

my $dsn = $ENV{TEST_DBIX_VERSIONEDSUBS_DBI_DSN} || "dbi:SQLite:dbname=:memory:";

my $app = My::App::Test->new({ code => \%My::App::Test:: });;
$app->connect($dsn);
$app->dbh->do( $_ ) for split /;\n/sm, <<"";
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
is $res,undef,"My::App::Test::func doesn't exist";
like $err, '/^Undefined subroutine/', "... and Perl thinks so too";

$app->init_code;

$res = eval {$app->dispatch('func')};
$err = $@;
is $res,"value 1","func() can be dispatched to";
is $err, '', "... and Perl thinks so too";

$res = eval {My::App::Test::func()};
$err = $@;
is $res,"value 1","My::App::Test::func() exists in the namespace as well";
is $err, '', "... and Perl thinks so too";
