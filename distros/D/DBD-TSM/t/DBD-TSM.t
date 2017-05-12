#!/usr/bin/perl

# %W%

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl DBD-TSM.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More;
use Data::Dumper;

#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $exit;
BEGIN {
    my @os_tested_by_user = qw(aix darwin linux Win32);
    my %os_tested_by_user = map {$_ => 1} @os_tested_by_user;

    unless (exists $os_tested_by_user{$^O}) {
        plan skip_all => "Never tested '$^O' by me or an other user. Change \@os_tested_by_user in '$0' and inform me, if tests run successfully";
        exit(0);
    }

    unless ($ENV{DBI_DSN} && $ENV{DBI_USER} && $ENV{DBI_PASS}) {
        plan tests => 2;
        warn "Skip some tests because DBI_DSN, DBI_USER, DBI_PASS not set.\n";
        $exit++;
    } else {
        plan tests => 15;
    }

    use_ok('DBI');
    use_ok('DBD::TSM'); 
};
no warnings;

if ($exit) {
    exit 0;
}

my $dbh;
eval {
    $dbh = DBI->connect();
};
ok(!$@, "Initialize TSM connection: [$@] [$!] [$dbh]");
unless ($dbh) {
    die "Abort test.\n";
}

#Use standard variable

#Do test
$sth=$dbh->do('query status');
ok($sth ne undef,"Do statement query status");

#Prepare/Execute test
my $sth=$dbh->prepare('query ?');
ok($sth ne undef,"Prepare statement query ?");
exit(0) unless($sth);
$sth->execute('status');
my $raw = $sth->{tsm_raw};
ok($sth->{NAME}->[0] eq 'Server Name', "Execute statement 'query status'");
while (my $row=$sth->fetchrow_hashref()) {
    if (exists $row->{'Server URL'}) {
        ok($row->{'Server Name'} ne '',"Fetch data 'Server Name'");
        last;
    }
}
eval {
    $dbh->do("query node MYJUNKNODE");
};

ok($dbh->err == 11,"Check empty statement return code");
ok($sth->finish() == 1,"Finish statement");
my $select = "select * from domains, nodes where domains.DOMAIN_NAME = nodes.DOMAIN_NAME";
$sth = $dbh->prepare($select);
#print Dumper($sth, $dbh, DBI::errstr);
ok($sth, "Prepare: $select");
eval {
    $sth->execute();
};
ok(!$@, "Execute: $select/$@");
#print Dumper($sth->{tsm_raw});
ok($sth->fetchall_hashref('NODE_NAME'), "Fetchall: $select");
$sth->finish();
my $command = "show threads";

$sth = $dbh->prepare($command);
ok($sth, "Prepare: $command");
ok($sth->execute(), "Execute: $command");
my $raw_data_ref = $sth->{tsm_raw};
#print @{$raw_data_ref};
ok(@{$raw_data_ref}, "Get raw data \$sth->{tsm_raw}");
