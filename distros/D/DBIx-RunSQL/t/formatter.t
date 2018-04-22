#!perl -w
use strict;
use Test::More;

use DBIx::RunSQL;

my $can_run = eval {
    require Text::Table;
    require DBD::SQLite;
    1
};

if (not $can_run) {
    plan skip_all => "Test prerequisite modules not installed: $@";
    exit;
};

plan tests => 1;

my $sql= <<'SQL';
    create table foo (
        name varchar(64)
      , age decimal(4)
    );
    insert into foo (name,age) values ('bar',100);
    insert into foo (name,age) values ('baz',1);
SQL

my $test_dbh = DBIx::RunSQL->create(
    dsn     => 'dbi:SQLite:dbname=:memory:',
    sql     => \$sql,
);

my $sth= $test_dbh->prepare(<<'SQL');
    select * from foo order by name;
SQL
$sth->execute;
my $result= DBIx::RunSQL->format_results( sth => $sth, formatter => 'Text::Table::JIRA' );
is_deeply [split /\r?\n/, $result],
['||name||age||',
 '| bar | 100| ',
 '| baz |   1| ',
]
;

package Text::Table::JIRA;
use strict;
use vars '@ISA';
require Text::Table;
BEGIN {
    @ISA = 'Text::Table';
}

sub new {
    my( $class, @headers ) = @_;

	my $sep = {
	    is_sep => 1,
		title => '||',
		body  => '| ',
	};

	@headers = ($sep, map {
	    $_, $sep,
	} @headers);
	$class->SUPER::new( @headers )
}
