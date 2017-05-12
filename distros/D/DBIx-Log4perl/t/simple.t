# $Id: simple.t 284 2006-09-07 13:50:57Z martin $
use strict;
use warnings;

$^W = 1;

my ($logtmp1, $logtmp2);

END {
    foreach my $tmpfile($logtmp1, $logtmp2) {
        if (defined($tmpfile)) {
            eval {unlink($tmpfile)};
        }
    }
}

push @INC, 't';
require 'lib.pl';
my ($dsn,$user,$password,$table) = get_config();

use Test::More;

if (!defined($dsn) || ($dsn eq "")) {
    plan tests => 3;
} else {
    plan tests => 17;
}

use_ok('DBIx::Log4perl');
use_ok('File::Spec');
use_ok('Log::Log4perl');

if (!defined($dsn) || ($dsn eq "")) {
    diag("Connection orientated test not run because no database connect information supplied");
    exit 0;
}

my $out;
#########################

my $conf1 = 'example.conf';
my $conf2 = File::Spec->catfile(File::Spec->updir, 'example.conf');

ok ((! -r $conf1) || (! -r $conf2), "Log::Log4perl config exists");
my $conf = $conf1 if (-r $conf1);
$conf = $conf2 if (-r $conf2);

($logtmp1, $logtmp2) = config();

my $dbh = DBIx::Log4perl->connect($dsn, $user, $password);
ok($dbh, 'connect to db');
BAIL_OUT("Failed to connect to database - all other tests abandoned")
	if (!$dbh);
ok(check_log(\$out, $logtmp2), 'test for log output');

{
    local $dbh->{PrintError} = 0;
    eval {$dbh->do(qq/drop table $table/)};
}
ok(check_log(\$out, $logtmp2), 'drop test table');
ok($dbh->do(qq/create table $table (a int primary key, b char(50))/),
   'create test table');
ok(check_log(\$out, $logtmp2), 'test for log output');

my $sth;

ok($sth = $dbh->prepare(qq/insert into $table values (?,?)/),
   'prepare insert');
SKIP: {
	skip "prepare failed", 3 unless $sth;

	ok(check_log(\$out, $logtmp2), 'test for log output');

	ok($sth->execute(1, 'one'), 'insert one');
	ok(check_log(\$out, $logtmp2), 'test for log output');
};

ok ($dbh->disconnect, 'disconnect');
ok(check_log(\$out, $logtmp2), 'test for log output');
