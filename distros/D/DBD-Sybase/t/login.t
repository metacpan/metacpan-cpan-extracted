#!perl
#
# $Id: login.t,v 1.4 2007/04/12 16:09:36 mpeppler Exp $

use lib 'blib/lib';
use lib 'blib/arch';

use lib 't';
use _test;

use strict;

use Test::More tests => 6;

use vars qw($Pwd $Uid $Srv $Db);

BEGIN { use_ok('DBI');
        use_ok('DBD::Sybase');}

($Uid, $Pwd, $Srv, $Db) = _test::get_info();

#DBI->trace(3);
my $dbh = DBI->connect("dbi:Sybase:server=$Srv;database=$Db", $Uid, $Pwd, {PrintError => 1});
#DBI->trace(0);

ok($dbh, 'Connect');

ok $dbh->ping, "ping should pass after connect";

$dbh->disconnect if $dbh;

ok !$dbh->ping, "ping should fail after disconnect";


$dbh = DBI->connect("dbi:Sybase:server=$Srv;database=$Db", 'ohmygod', 'xzyzzy', {PrintError => 0});

ok(!$dbh, 'Connect fail');

$dbh->disconnect if $dbh;

exit(0);
