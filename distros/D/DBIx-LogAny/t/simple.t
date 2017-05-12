# $Id$
use strict;
use warnings;
use IO::File;
use Test::More;
use Log::Any::Adapter;

$^W = 1;

my $logtmp1;

END {
    foreach my $tmpfile($logtmp1) {
        if (defined($tmpfile)) {
            eval {unlink($tmpfile) or diag("unlink $tmpfile - $!")};
        }
    }
}

push @INC, 't';
require 'lib.pl';
my ($dsn,$user,$password,$table) = get_config();

if (!defined($dsn) || ($dsn eq "")) {
    plan skip_all => "connection orientated test not run because no database connect information supplied";
    exit 0;
} else {
    plan tests => 11;
}

my $out;
#########################

$logtmp1 = config();


Log::Any::Adapter->set ('File', $logtmp1);

#use_ok('DBIx::LogAny');
use DBIx::LogAny;

my $dbh = DBIx::LogAny->connect($dsn, $user, $password);
ok($dbh, 'connect to db');
BAIL_OUT("Failed to connect to database - all other tests abandoned")
	if (!$dbh);
my $size;
ok($size = check_log(\$out, $logtmp1, $size), 'test for log output');

{
    local $dbh->{PrintError} = 0;
    eval {$dbh->do(qq/drop table $table/)};
}
ok($size = check_log(\$out, $logtmp1, $size), 'drop test table');
ok($dbh->do(qq/create table $table (a int primary key, b char(50))/),
   'create test table');
ok($size = check_log(\$out, $logtmp1, $size), 'test for log output');

my $sth;

ok($sth = $dbh->prepare(qq/insert into $table values (?,?)/),
   'prepare insert');
SKIP: {
	skip "prepare failed", 3 unless $sth;

	ok($size = check_log(\$out, $logtmp1, $size), 'test for log output');

	ok($sth->execute(1, 'one'), 'insert one');
	ok($size = check_log(\$out, $logtmp1, $size), 'test for log output');
};

ok ($dbh->disconnect, 'disconnect');
ok($size = check_log(\$out, $logtmp1, $size), 'test for log output');
