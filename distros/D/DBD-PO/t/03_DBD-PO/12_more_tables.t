#!perl
#!perl -T

use strict;
use warnings;

use Test::DBD::PO::Defaults qw(
    $PATH $TRACE $DROP_TABLE
    trace_file_name
    $TABLE_12 $FILE_12
);
use Test::More tests => 22 + 1;
use Test::NoWarnings;
use charnames qw(:full);

BEGIN {
    require_ok('DBI');
}

my @test_data = (
    "\N{LATIN CAPITAL LETTER A WITH DIAERESIS}",
    "\N{CYRILLIC CAPITAL LETTER ZHE}",
);

# build table
my $dbh = DBI->connect(
    "dbi:PO:f_dir=$PATH;po_charset=utf-8",
    undef,
    undef,
    {
        RaiseError => 1,
        PrintError => 0,
        AutoCommit => 1,
    },
);
isa_ok($dbh, 'DBI::db', 'connect');

if ($TRACE) {
    open my $file, '>', trace_file_name();
    $dbh->trace(4, $file);
}

# create table
sub create_table {
    my $param = {table_number => shift};

    my $dbh = $param->{dbh} = DBI->connect(
        "dbi:PO:f_dir=$PATH;po_charset=utf-8",
        undef,
        undef,
        {
            RaiseError => 1,
            PrintError => 0,
            AutoCommit => 1,
        },
    );
    isa_ok($dbh, 'DBI::db', "connect $param->{table_number}");

    @{$param}{qw(table table_file)} = (
        $TABLE_12,
        $FILE_12,
    );
    for my $name (@{$param}{qw(table table_file)}) {
        $name =~ s{\?}{$param->{table_number}}xms;
    }

    my ($table, $table_file) = @{$param}{qw(table table_file)};

    my $result = $dbh->do(<<"EO_SQL");
        CREATE TABLE $table (
            msgid VARCHAR,
            msgstr VARCHAR
        )
EO_SQL
    is($result, '0E0', "create table ($table)");
    ok(-e $table_file, "table file found ($table_file)");

    return $param;
}

sub create {
    my $param = shift;

    my ($table, $table_file) = @{$param}{qw(table table_file)};

    my $result = $dbh->do(<<"EO_SQL");
        CREATE TABLE $table (
            msgid  VARCHAR,
            msgstr VARCHAR
        )
EO_SQL
    is($result, '0E0', "create table $table");
    ok(-e $table_file, "table $table_file file found");

    return $param;
}

sub insert_header {
    my $param = shift;

    my $table = $param->{table};

    my $msgstr = $dbh->func(undef, 'build_header_msgstr');
    my $result = $dbh->do(<<"EO_SQL", undef, $msgstr);
        INSERT INTO $table (
            msgstr
        ) VALUES (?)
EO_SQL
    is($result, 1, "insert header into table $table");

    return $param;
}

sub insert_line {
    my $param = shift;

    my $table = $param->{table};

    my $result = $dbh->do(<<"EO_SQL", undef, $test_data[0], $test_data[1]);
        INSERT INTO $table (
            msgid,
            msgstr
        ) VALUES (?, ?)
EO_SQL
    is($result, 1, "insert line into table $table");

    return $param;
}

sub prepare {
    my $param = shift;

    my $table = $param->{table};

    my $sth = $param->{sth} = $dbh->prepare(<<"EO_SQL");
        SELECT msgstr
        FROM   $table
        WHERE  msgid=?
EO_SQL
    isa_ok($sth, 'DBI::st', "prepare $table");

    return $param;
}

sub execute {
    my $param = shift;

    my $table = $param->{table};

    my $result = $param->{sth}->execute($test_data[0]);
    is($result, 1, "insert $table");

    return $param;
}

sub fetch {
    my $param = shift;

    my $table = $param->{table};

    my ($result) = $param->{sth}->fetchrow_array();
    is($result, $test_data[1], "fetch $table");

    return $param;
}

sub drop_table {
    my $param = shift;

    SKIP:
    {
        skip('drop table', 2)
            if ! $DROP_TABLE;

        my ($table, $table_file) = @{$param}{qw(table table_file)};

        my $result = $dbh->do(<<"EO_SQL");
            DROP TABLE $table
EO_SQL
        is($result, '-1', "drop table $table");
        ok(! -e $table_file, "table file $table_file deleted");
    }

    return;
}

() = map {
         drop_table($_);
     }
     map {
         fetch($_);
     }
     map {
         execute($_);
     }
     map {
         prepare($_);
     }
     map {
         insert_line($_);
     }
     map {
         insert_header($_);
     }
     map {
         create_table($_);
     } 1 .. 2;
