use strict;
use warnings;

use Test::More;

use DBI;
use Config;
use DBD::Oracle qw(ORA_OCI);

unshift @INC ,'t';
require 'nchar_test_lib.pl';

$| = 1;

my $dsn = oracle_test_dsn();
my $dbuser = $ENV{ORACLE_USERID} || 'scott/tiger';

my $dbh = DBI->connect($dsn, $dbuser, '',
                       {
                           PrintError => 0,
                       });

if ($dbh) {
    plan tests => 28;
} else {
    plan skip_all => "Unable to connect to Oracle";
}

my($sth, $p1, $p2, $tmp);
SKIP: {
    skip "not unix-like", 2 unless $Config{d_semctl};

    my @ora_oci_version = split /\./, ORA_OCI();
    skip 'solaris with OCI>9.x', 2 
        if $^O eq 'solaris' and $ora_oci_version[0] > 9;

    # basic check that we can fork subprocesses and wait for the status
    # after having connected to Oracle

    # at some point, this should become a subtest
    
    my $success = is system("exit 1;"), 1<<8, 'system exit 1 should return 256';
    $success &&= is system("exit 0;"),    0, 'system exit 0 should return 0';

    unless ( $success ) {
        diag <<END_NOTE;
The test might have failed because you are using a
a bequeather to connect to the server.

If you need to continue using a bequeather to connect to a server on the
same host as the client add

    bequeath_detach = yes

to your sqlnet.ora file or you won't be able to safely use fork/system
functions in Perl.

END_NOTE

    }

}

$sth = $dbh->prepare(q{
	/* also test preparse doesn't get confused by ? :1 */
        /* also test placeholder binding is case insensitive */
	select :a, :A from user_tables -- ? :1
});
ok($sth->{ParamValues}, 'preparse, case insensitive, placeholders in comments');
is(keys %{$sth->{ParamValues}}, 1, 'number of parameters');
is($sth->{NUM_OF_PARAMS}, 1, 'expected number of parameters');
ok($sth->bind_param(':a', 'a value'), 'bind_param for select parameter');
ok($sth->execute, 'execute for select parameter');
ok($sth->{NUM_OF_FIELDS}, 'NUM_OF_FIELDS');
eval {
  local $SIG{__WARN__} = sub { die @_ }; # since DBI 1.43
  $p1=$sth->{NUM_OFFIELDS_typo};
};
ok($@ =~ /attribute/, 'unrecognised attribute');
ok($sth->{Active}, 'statement is active');
ok($sth->finish, 'finish');
ok(!$sth->{Active}, 'statement is not active');

$sth = $dbh->prepare("select * from user_tables");
ok($sth->execute, 'execute for user_tables');
ok($sth->{Active}, 'active for user_tables');
1 while ($sth->fetch);	# fetch through to end
ok(!$sth->{Active}, 'user_tables not active after fetch');

# so following test works with other NLS settings/locations
ok($dbh->do("ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,'"),
  'set NLS_NUMERIC_CHARACTERS');

ok($tmp = $dbh->selectall_arrayref(q{
	select 1 * power(10,-130) "smallest?",
	       9.9999999999 * power(10,125) "biggest?"
	from dual
}), 'select all for arithmetic');
my @tmp = @{$tmp->[0]};
#warn "@tmp"; $tmp[0]+=0; $tmp[1]+=0; warn "@tmp";
ok($tmp[0] <= 1.0000000000000000000000000000000001e-130, "tmp0=$tmp[0]");
ok($tmp[1] >= 9.99e+125, "tmp1=$tmp[1]");


my $warn='';
eval {
	local $SIG{__WARN__} = sub { $warn = $_[0] };
	$dbh->{RaiseError} = 1;
	$dbh->{PrintError} = 1;
	$dbh->do("some invalid sql statement");
};
ok($@    =~ /DBD::Oracle::db do failed:/, "eval error: ``$@'' expected 'do failed:'");
#print "''$warn''";
ok($warn =~ /DBD::Oracle::db do failed:/, "warn error: ``$warn'' expected 'do failed:'");
ok($DBI::err, 'err defined');
$dbh->{RaiseError} = 0;
$dbh->{PrintError} = 0;
# ---

ok( $dbh->ping, 'ping - connected');

my $ora_oci = DBD::Oracle::ORA_OCI(); # dualvar
note sprintf "ORA_OCI = %d (%s)\n", $ora_oci, $ora_oci;

ok("$ora_oci", 'ora_oci defined');
ok($ora_oci >= 8, "ora_oci $ora_oci >= 8");
my @ora_oci = split(/\./, $ora_oci,-1);
ok(scalar @ora_oci >= 2, 'version has 2 or more components');
ok((scalar @ora_oci == grep { DBI::looks_like_number($_) } @ora_oci),
  'version looks like numbers');
is($ora_oci[0], int($ora_oci), 'first number is int');
