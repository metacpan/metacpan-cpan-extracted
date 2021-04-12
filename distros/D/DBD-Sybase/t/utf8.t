#!perl
#
# $Id: utf8.t,v 1.5 2011/10/02 15:01:50 mpeppler Exp $

use lib 't';
use _test;

use strict;

use Test::More;

BEGIN {
    plan skip_all => 'This test requires Perl 5.8+'
        unless $] >= 5.008;

}

use DBI;
use DBD::Sybase;
use Encode ();

binmode( $_, 'utf8' )
    for map { Test::Builder->new->$_() }
    qw( output failure_output todo_output );

use vars qw($Pwd $Uid $Srv $Db);

( $Uid, $Pwd, $Srv, $Db ) = _test::get_info();

my $dbh = DBI->connect(
    "dbi:Sybase:$Srv;database=$Db;charset=utf8", $Uid, $Pwd,
    { PrintError => 1 }
);
$dbh->{syb_enable_utf8} = 1;


# Don't run this test on MS-SQL ("Unknown") servers...
unless ($dbh->{syb_server_version} ne 'Unknown' && $dbh->{syb_server_version} ne 'MS-SQL' && $dbh->{syb_server_version} ge '15' && $dbh->{syb_enable_utf8}) {
    plan skip_all => 'This test requires ASE 15 or later, and OpenClient 15.x or later';
}

plan tests => 11;

$dbh->do("create table #utf8test (uv univarchar(510), ut unitext)");


my $ascii = 'Some text';
# This is a byte string rather than a character string - this means that when using this
# to compare with the output from the DB we get a failure, even though the strings appear
# to be the same. So the string needs to be converted to UTF8 characters via Encode::decode()
# for use in the test. To simplify I've commented this out and use the second sample string
# instead.
my $utf8t = 'पट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट्टपट';
#my $utf8 = Encode::decode('UTF-8', $utf8t);
my $utf8 = "\x{263A} - smiley1 - \x{263B} - smiley2" x 15;

{
    my $quoted = $dbh->quote($ascii);
    $dbh->do("insert into #utf8test (uv, ut) values ($quoted, $quoted)");

    my $rows = $dbh->selectall_arrayref(
        "select * from #utf8test",
        { Slice => {} }
    );

    is_deeply(
        $rows,
        [
            {
                uv => $ascii,
                ut => $ascii,
            }
        ],
        "got expected row back from #utf8test"
    );

    ok(
        !Encode::is_utf8( $rows->[0]{uv} ),
        'uv column was returned with utf8 flag off'
    );

    ok(
        !Encode::is_utf8( $rows->[0]{ut} ),
        'ut column was returned with utf8 flag off'
    );
}

{
    $dbh->do("delete from #utf8test");

    my $quoted = $dbh->quote($utf8);
    $dbh->do("insert into #utf8test (uv, ut) values ($quoted, $quoted)");

    my $rows = $dbh->selectall_arrayref(
        "select * from #utf8test",
        { Slice => {} }
    );

    is_deeply(
        $rows,
        [
            {
                uv => $utf8,
                ut => $utf8,
            }
        ],
        "got expected row back from #utf8test"
    );

    ok(
        Encode::is_utf8( $rows->[0]{uv} ),
        'uv column was returned with utf8 flag on'
    );

    ok(
        Encode::is_utf8( $rows->[0]{ut} ),
        'ut column was returned with utf8 flag on'
    );
}

$dbh->{syb_enable_utf8} = 0;

{
    my $rows = $dbh->selectall_arrayref(
        "select * from #utf8test",
        { Slice => {} }
    );

    ok(
        !Encode::is_utf8( $rows->[0]{uv} ),
        'uv column was returned with utf8 flag off (syb_enable_utf8 was false)'
    );

    ok(
        !Encode::is_utf8( $rows->[0]{ut} ),
        'ut column was returned with utf8 flag off (syb_enable_utf8 was false)'
    );
}

{
    my $dbh2 = DBI->connect(
        "dbi:Sybase:$Srv;database=$Db;charset=utf8",
        $Uid, $Pwd, {
            PrintError      => 1,
            syb_enable_utf8 => 1
        }
    );

    $dbh2->do("create table #utf8test (uv univarchar(250), ut unitext)");

    my $quoted = $dbh->quote($utf8);
    $dbh2->do("insert into #utf8test (uv, ut) values ($quoted, $quoted)");

    my $rows = $dbh2->selectall_arrayref(
        "select * from #utf8test",
        { Slice => {} }
    );

    is_deeply(
        $rows,
        [
            {
                uv => substr($utf8, 0, 250),
                ut => $utf8,
            }
        ],
        "got expected row back from #utf8test"
    );

    ok(
        Encode::is_utf8( $rows->[0]{uv} ),
        'uv column was returned with utf8 flag on (syb_enable_utf8 passed to connect)'
    );

    ok(
        Encode::is_utf8( $rows->[0]{ut} ),
        'ut column was returned with utf8 flag on (syb_enable_utf8 passed to connect)'
    );
}

