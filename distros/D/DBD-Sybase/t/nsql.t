#!perl
#
# $Id: nsql.t,v 1.5 2005/10/01 13:05:13 mpeppler Exp $

use lib 't';
use _test;

use strict;

use Test::More tests => 7; #qw(no_plan);

use vars qw($Pwd $Uid $Srv $Db);

BEGIN { use_ok('DBI');
        use_ok('DBD::Sybase');}

($Uid, $Pwd, $Srv, $Db) = _test::get_info();

#DBI->trace(3);
my $dbh = DBI->connect("dbi:Sybase:server=$Srv;database=$Db", $Uid, $Pwd, {syb_deadlock_retry=>10, syb_deadlock_verbose=>1});
#exit;
ok($dbh, 'Connect');

if(!$dbh) {
    warn "No connection - did you set the user, password and server name correctly in PWD?\n";
    for (4 .. 7) {
	ok(0);
    }
    exit(0);
}

my @d = $dbh->func("select * from sysusers", 'ARRAY', 'nsql');
ok(@d >= 1, 'array');
foreach (@d) {
    local $^W = 0;
    print "@$_\n";
}
#print "ok 3\n";

@d = $dbh->func("select * from sysusers", 'ARRAY', \&cb, 'nsql');
ok(@d == 1, 'array 2');
foreach (@d) {
    print "$_\n";
}

SKIP: {
    skip 'requires DBI 1.34', 2 unless $DBI::VERSION >= 1.34;
    @d = $dbh->syb_nsql("select * from sysusers", 'ARRAY');
    ok(@d >= 1, 'syb_nsql 1');
    foreach (@d) {
	local $^W = 0;
	print "@$_\n";
    }
#    print "ok 5\n";

    @d = $dbh->syb_nsql("select * from sysusers", 'ARRAY', \&cb);
    ok(@d == 1, 'syb_nsql 2');
    foreach (@d) {
	print "$_\n";
    }
#    print "ok 6\n";
}

sub cb {
    my @data = @_;
    local $^W = 0;
    print "@data\n";

    1;
}
