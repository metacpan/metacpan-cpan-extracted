#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN { use_ok ("DBI") }

my ($schema, $dbh) = ("DBUTIL");
ok ($dbh = DBI->connect ("dbi:Unify:", "", $schema), "Connect");

$dbh or BAIL_OUT ("Unable to connect to Unify ($DBI::errstr)\n");

my $sth;

# also test preparse doesn't get confused by ? :1
ok ($sth = $dbh->prepare (q{
    select * from DIRS -- ? :1
    }), "prepare 1");
ok ($sth->execute,		"execute");
ok ($sth->{NUM_OF_FIELDS},	"NUM_OF_FIELDS");
eval {
    local $SIG{__WARN__} = sub { die @_ }; # since DBI 1.43
    my $x = $sth->{NUM_OFFIELDS_typo};
    };
like ($@, qr/attribute/,	"attr typo");
ok ($sth->{Active},		"Active");
ok ($sth->finish,		"finish");
ok (!$sth->{Active},		"not Active");
undef $sth;		# Force destroy

ok ($sth = $dbh->prepare ("select * from DIRS"), "prepare 2");
ok ($sth->execute,		"execute 2");
ok ($sth->{Active},		"Active 2");
1 while ($sth->fetch);	# fetch through to end
ok (!$sth->{Active},		"auto finish");
undef $sth;

my $warn;
eval {
    local $SIG{__WARN__} = sub { $warn = $_[0] };
    local $dbh->{RaiseError} = 1;
    $dbh->do ("some invalid sql statement");
    };
like ($@,    qr/DBD::Unify::db do failed:/, "expected 'do failed:' from RaiseError");
like ($warn, qr/DBD::Unify::db do failed:/, "expected 'do failed:' from PrintError");
ok ($DBI::err,			"DBI::err is set");
$dbh->{RaiseError} = 0;

# ---

ok ( $dbh->ping,		"ping");
$dbh->disconnect;
$dbh->{PrintError} = 0;
ok (!$dbh->ping,		"!ping");

done_testing;
