package My::App::Test;
use strict;
use lib 'eg/lib';
use base 'My::App';

sub test_syntax_error_overwrite {
    $::existing++;
};

__PACKAGE__->setup();

package main;
use strict;
use Test::More tests => 6;
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
    INSERT INTO code_live (name,code) VALUES ('BEGIN','" # syntax error in begin block');
    INSERT INTO code_live (name,code) VALUES ('test_syntax_error','" # syntax error in subroutine');
    INSERT INTO code_live (name,code) VALUES ('test_syntax_error_overwrite','" # syntax error in preexisting sub');

my @warnings;
$SIG{__WARN__} = sub {
    push @warnings, "@_";
};

My::App::Test->init_code;

for (@warnings) {
  like $_, q{/My::App::Test::\w+>> Can't find string terminator '"' anywhere before EOF at /}, 'The correct warning gets raised syntax error';
};
isn't 'My::App::Test'->can('test_syntax_error_overwrite'), undef, "The existing code was kept";
is 'My::App::Test'->can('test_syntax_error'), undef, "No code was defined for 'test_syntax_error' because of the syntax error";
My::App::Test::test_syntax_error_overwrite();
is $::existing, 1, "test_syntax_error_overwrite() is still the same code";
