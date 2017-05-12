#!/usr/bin/perl -w
use strict;
use Test::More;
use Data::Dumper;
use DBI;

my $have_sqlite = eval 'require DBD::SQLite; $DBD::SQLite::VERSION >= 1.14 or die "DBD::SQLite::VERSION is $DBD::SQLite::VERSION, we need 1.14+"; 1';
if (! $have_sqlite) {
    plan skip_all => "DBD::SQLite not installed ($@)";
    exit 0;
};

# Monkeypatching!
unless ( defined &DBD::SQLite::db::column_info )
{
    require 't/dbd-sqlite-column-info.pm';
    *DBD::SQLite::db::column_info = \&_sqlite_column_info;
}

plan tests => 4;
use_ok 'DBIx::DataAudit';

# DBI->installed_versions;

my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', undef, undef);
$/ = ";\n";
while (<DATA>) {
    chomp;
    next unless /\S/; # SQLite ...
    #diag $_;
    $dbh->do($_);
};

my $result = DBIx::DataAudit->audit(dbh => $dbh, table => 'test');
isa_ok $result, 'DBIx::DataAudit';
my $info = $result->template_data;
is_deeply $info, {
    table => 'test',
    headings => [qw[column min max count values null avg blank empty missing ]],
    rows  => [
        ['c_bigint',  '1', '10', '3', '2', '0', '7', 'n/a', 'n/a', 'n/a' ],
        ['c_boolean', 'n/a', 'n/a', '3', '2', '0', 'n/a', 'n/a', 'n/a', 'n/a' ],
	['c_char',    'A', 'Z', '3', '2', '0', 'n/a', '0',   '0',   '0' ],
	['c_character_varying',    'A', 'Z', '3', '2', '0', 'n/a', '0',   '0',   '0' ],
        ['c_datetime', '2008-01-01 00:00:01', '2008-04-01 00:10:01', '3', '2', '0', 'n/a', 'n/a', 'n/a', 'n/a' ],
        ['c_date', '2008-01-01', '2008-04-01', '3', '2', '0', 'n/a', 'n/a', 'n/a', 'n/a' ],
        ['c_decimal', '1', '10', '3', '2', '0', '7', 'n/a', 'n/a', 'n/a' ],
        ['c_inet', 'n/a', 'n/a', '3', '2', '0', 'n/a', 'n/a', 'n/a', 'n/a' ],
        ['c_integer', '1', '10', '3', '2', '0', '7', 'n/a', 'n/a', 'n/a' ],
        ['c_int', '1', '10', '3', '2', '0', '7', 'n/a', 'n/a', 'n/a' ],
        ['c_smallint', '1', '10', '3', '2', '0', '7', 'n/a', 'n/a', 'n/a' ],
        ['c_text', 'A', 'Z', '3', '2', '0', 'n/a', '0', '0', '0' ],
        ['c_time', '00:00:01', '00:10:01', '3', '2', '0', 'n/a', 'n/a', 'n/a', 'n/a' ],
        ['c_timestamp', '2008-01-01 00:00:01', '2008-04-01 00:10:01', '3', '2', '0', 'n/a', 'n/a', 'n/a', 'n/a' ],
        ['c_tinyint', '1', '10', '3', '2', '0', '7', 'n/a', 'n/a', 'n/a' ],
        ['c_varchar', 'A', 'Z', '3', '2', '0', 'n/a', '0', '0', '0' ]
    ]
}, 'Expected information retrieved' or diag Dumper $info;

my $info2 = $result->template_data;
is_deeply $info, $info2, 'Analytics are idempotent';

# diag $result->as_text();

__DATA__
create table test (
    c_bigint BIGINT,
    c_boolean BOOLEAN,
    c_char CHAR,
    c_character_varying CHARACTER VARYING,
    c_datetime DATETIME,
    c_date DATE,
    c_decimal DECIMAL(12,2),
    -- ENUM
    c_inet INET,
    c_integer INTEGER,
    c_int INT,
    c_smallint SMALLINT,
    c_text TEXT,
    c_time TIME,
    -- 'TIMESTAMP WITHOUT TIME ZONE' ,
    c_timestamp TIMESTAMP,
    c_tinyint TINYINT,
    c_varchar VARCHAR(64)
);

-- minima
INSERT INTO test (c_bigint,c_boolean,c_char,c_character_varying,c_datetime,c_date,c_decimal,
    c_inet, c_integer, c_int, c_smallint, c_text, c_time, c_timestamp, c_tinyint, c_varchar
)
VALUES (
    1,1,'A','A','2008-01-01 00:00:01','2008-01-01',1.00,
    '192.168.0.1',1,1,1,'A','00:00:01','2008-01-01 00:00:01',1,'A'
);

-- maxima
INSERT INTO test (c_bigint,c_boolean,c_char,c_character_varying,c_datetime,c_date,c_decimal,
    c_inet, c_integer, c_int, c_smallint, c_text, c_time, c_timestamp, c_tinyint, c_varchar
)
VALUES (
    10,10,'Z','Z','2008-04-01 00:10:01','2008-04-01',10.00,
    '192.168.0.254',10,10,10,'Z','00:10:01','2008-04-01 00:10:01',10,'Z'
);

-- duplicate maxima
INSERT INTO test (c_bigint,c_boolean,c_char,c_character_varying,c_datetime,c_date,c_decimal,
    c_inet, c_integer, c_int, c_smallint, c_text, c_time, c_timestamp, c_tinyint, c_varchar
)
VALUES (
    10,10,'Z','Z','2008-04-01 00:10:01','2008-04-01',10.00,
    '192.168.0.254',10,10,10,'Z','00:10:01','2008-04-01 00:10:01',10,'Z'
);

