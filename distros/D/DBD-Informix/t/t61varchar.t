#!/usr/bin/perl
#
#   @(#)$Id: t61varchar.t,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   Test that DBD::Informix handles empty VARCHAR values correctly
#
#   Copyright 2005    Vaclav Ovsik <vaclav.ovsik@i.cz>
#   Copyright 2005-14 Jonathan Leffler

use DBI qw(:sql_types);
use DBD::Informix::TestHarness;
use strict;
use warnings;

my $tbl = "dbd_ix_empty_vc";
my $dbh = connect_to_test_database({ RaiseError => 1 });
if (!$dbh->{ix_InformixOnLine})
{
    stmt_note "1..0 # Skip: Need server with VARCHAR support\n";
    exit 0;
}
if ($dbh->{ix_ServerVersion} < 600)
{
    stmt_note "1..0 # Skip: ESQL/C 5.x does not properly distinguish between empty VARCHAR and NULL\n";
    exit 0;
}
#$dbh->trace(10);
stmt_note("1..2\n");

$dbh->do("CREATE TEMP TABLE $tbl ( id int, vc varchar(20) )");

# Implicit binding
{
my $sth = $dbh->prepare("INSERT INTO $tbl VALUES (?, ?)");
$sth->execute(1, '');
$sth->execute(2, undef);
$sth->execute(3, ' ');
}

# Literal value
$dbh->do("INSERT INTO $tbl VALUES(4,'')");
$dbh->do("INSERT INTO $tbl VALUES(6,' ')");
$dbh->do("INSERT INTO $tbl VALUES(7,'  ')");

# Explicit binding
{
my $sth = $dbh->prepare("INSERT INTO $tbl VALUES (?, ?)");
$sth->bind_param(1, 5, SQL_INTEGER);
$sth->bind_param(2, '', SQL_VARCHAR);
$sth->execute;
#$sth->bind_param(1, 8, SQL_INTEGER);
#$sth->bind_param(2, ' ', SQL_VARCHAR);
#$sth->execute;
#$sth->bind_param(1, 9, SQL_INTEGER);
#$sth->bind_param(2, '  ', SQL_VARCHAR);
#$sth->execute;
}
stmt_ok;

{
my $row1 = { 'id' => 1, 'vc' => ''    };
my $row2 = { 'id' => 2, 'vc' => undef };
my $row3 = { 'id' => 3, 'vc' => ' '   };
my $row4 = { 'id' => 4, 'vc' => ''    };
my $row5 = { 'id' => 5, 'vc' => ''    };
my $row6 = { 'id' => 6, 'vc' => ' '   };
my $row7 = { 'id' => 7, 'vc' => '  '  };
#my $row8 = { 'id' => 8, 'vc' => ' '   };
#my $row9 = { 'id' => 9, 'vc' => '  '  };

my $res1 =
    {   1 => $row1, 2 => $row2, 3 => $row3, 4 => $row4, 5 => $row5,
        6 => $row6, 7 => $row7, #8 => $row8, 9 => $row9
    };

my $sth = $dbh->prepare("SELECT * FROM $tbl");
$sth->execute ? validate_unordered_unique_data($sth, 'id', $res1) : stmt_nok;
}

$dbh->disconnect;

all_ok();

