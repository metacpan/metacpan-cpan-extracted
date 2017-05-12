use strict;
use Test;
BEGIN { plan tests => 2 }

package Film;
use base qw(Class::DBI::Replication);

sub teardown {
    my $class = shift;
    for my $db ('Main', 'Slaves_0', 'Slaves_1') {
	my $meth = "db_$db";
	Film->$meth()->do(<<'SQL');
DROP TABLE IF EXISTS Movies
SQL
	;
    }
}

sub setup {
    my $class = shift;
    $class->teardown;
    for my $db ('Main', 'Slaves_0', 'Slaves_1') {
	my $meth = "db_$db";
	Film->$meth()->do(<<'SQL');
CREATE TABLE Movies (
        title                   VARCHAR(255) NOT NULL,
        director                VARCHAR(80) NOT NULL,
        rating                  CHAR(5),
        PRIMARY KEY(title)
)
SQL
	;
    }
}

Film->set_master(
    'dbi:mysql:test', 'root', '', { AutoCommit => 1, RaiseError => 1, },
);
Film->set_slaves(
    ['dbi:mysql:test_0', 'root', '', { AutoCommit => 1, RaiseError => 1, } ],
    ['dbi:mysql:test_1', 'root', '', { AutoCommit => 1, RaiseError => 1, } ],
);
    
Film->table('Movies');
Film->columns(Primary => qw(Title));
Film->columns(All     => qw(Director Title Rating));

package main;

Film->setup;

my $f = Film->create({
    Title => 'Foo',
    Director => 'Bar',
    Rating => '1111',
});

ok($f->isa('Film'));

# SELECT will fail...
my $f_sel = Film->retrieve('Foo');
ok(! $f_sel);

END { Film->teardown; }




