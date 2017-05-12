#!perl -T

use strict;
use warnings;

use Test::DBD::PO::Defaults qw(
    $PATH $TRACE $DROP_TABLE
    trace_file_name
    $TABLE_11 $FILE_11
);
use Test::More tests => 15 + 1;
use Test::NoWarnings;
use Test::Exception;

BEGIN {
    require_ok('DBI');
}

my $dbh;

# build table
{
    $dbh = DBI->connect(
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

    my $result = $dbh->do(<<"EO_SQL");
        CREATE TABLE $TABLE_11 (
            msgid  VARCHAR,
            msgstr VARCHAR
        )
EO_SQL
    is($result, '0E0', 'create table');
    ok(-e $FILE_11, 'table file found');
}

# write a line and not the header at first
throws_ok
    {
        $dbh->do(<<"EO_SQL", undef, 'id');
            INSERT INTO $TABLE_11 (
                msgid
            ) VALUES (?)
EO_SQL
    }
    qr{\QA header has no msgid}xms,
    'write a line and not the header at first',
;

# write an empty header
throws_ok
    {
        $dbh->do(<<"EO_SQL", undef, undef);
            INSERT INTO $TABLE_11 (
                msgstr
            ) VALUES (?)
EO_SQL
    }
    qr{\QA header has to have a msgstr}xms,
    'write an empty header',
;

# write a false header
throws_ok
    {
        $dbh->do(<<"EO_SQL", undef, 'false');
            INSERT INTO $TABLE_11 (
                msgstr
            ) VALUES (?)
EO_SQL
    }
    qr{\QThis can not be a header}xms,
    'write a false header',
;

# write a true header
{
    my $msgstr = $dbh->func(undef, 'build_header_msgstr');
    my $result = $dbh->do(<<"EO_SQL", undef, $msgstr);
        INSERT INTO $TABLE_11 (
            msgstr
        ) VALUES (?)
EO_SQL
    is($result, 1, 'write a true header');
}

# write a true line
{
    my $result = $dbh->do(<<"EO_SQL", undef, 'id', 'str');
        INSERT INTO $TABLE_11 (
            msgid,
            msgstr
        ) VALUES (?, ?)
EO_SQL
    is($result, 1, 'write a true line');
}

# a line looks like a header
throws_ok
    {
        $dbh->do(<<"EO_SQL", undef, 'translation');
            INSERT INTO $TABLE_11 (
                msgstr
            ) VALUES (?)
EO_SQL
    }
    qr{\Q A line has to have a msgid}xms,
    'a line looks like a header',
;

# change a header to an empty header
throws_ok
    {
        $dbh->do(<<"EO_SQL", undef, q{}, q{});
            UPDATE $TABLE_11
            SET    msgstr=?
            WHERE  msgid=?
EO_SQL
    }
    qr{\QA header has to have a msgstr}xms,
    'change a header to an empty header',
;

# change a header to a false header
throws_ok
    {
        $dbh->do(<<"EO_SQL", undef, 'false', q{});
            UPDATE $TABLE_11
            SET    msgstr=?
            WHERE  msgid=?
EO_SQL
    }
    qr{\QThis can not be a header}xms,
    'change a header to a false header',
;

# change a line to a false line
throws_ok
    {
        $dbh->do(<<"EO_SQL", undef, q{}, 'id');
            UPDATE $TABLE_11
            SET    msgid=?
            WHERE  msgid=?
EO_SQL
    }
    qr{\QA line has to have a msgid}xms,
    'change a line to a false line',
;

# drop table
SKIP: {
    skip('drop table', 2)
        if ! $DROP_TABLE;

    my $result = $dbh->do(<<"EO_SQL");
        DROP TABLE $TABLE_11
EO_SQL
    is($result, '-1', 'drop table');
    ok(! -e $FILE_11, 'table file deleted');
}