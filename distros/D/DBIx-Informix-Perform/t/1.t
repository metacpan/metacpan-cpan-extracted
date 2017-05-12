#   -*-  MODE: PERL -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 3 };
use DBIx::Informix::Perform;
use Config;
use DBI;
use DBIx::Informix::Perform::DButils 'open_db';
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $per_file = "/tmp/test.$$.per";

my $perl = $Config{'perl5'};

my @avail_drivers = DBI->available_drivers();

my ($pg_avail) = grep { /^Pg$/ } @avail_drivers;
my $dbclass_default = $ENV{DB_CLASS} || $pg_avail ||
    $avail_drivers[$#avail_drivers];  # figure last is most recently added

open(TTY, ">/dev/tty");
select TTY;
$| = 1;
select STDOUT;


print TTY "\n\nClass of DBD Database driver (choose from: @avail_drivers) [$dbclass_default]: ";
my $dbclass = <STDIN>;
chomp $dbclass;
$dbclass ||= $dbclass_default;

print TTY "Database host [localhost]: ";
my $dbhost = <STDIN>; chomp $dbhost; # empty string usually means local connection

print TTY "Database name [test]: ";
my $dbname =  <STDIN>;  chomp $dbname;
$dbname ||= 'test';

print TTY "Table name [testac]: ";
my $table = <STDIN>;  chomp $table;
$table ||= 'testac';

print TTY "Database User Name, if required: ";
my $dbuser = <STDIN>; chomp $dbuser;

print TTY "Database Password, if required: ";
my $dbpass = <STDIN>; chomp $dbpass;

local (@ENV{'DB_HOST', 'DB_CLASS', 'DB_USER', 'DB_PASSWORD'}) =
    ($dbhost, $dbclass, $dbuser, $dbpass);

#  Decide whether to skip tests...
{
    my $dbh = open_db($dbname);
    my $skip_reason =
	!$dbh && "Unable to open $dbname on $dbhost";

    if (!$skip_reason) {
	local (*DBD::_::common::_not_impl) = sub {
	    no strict refs;
	    my $version = $ {"DBD::${dbclass}::VERSION"};
	    die "DBD::$dbclass version $version does not implmement column_info"
	    };
	local ($dbh->{'RaiseError'}, $dbh->{'PrintError'}) = (1, 0);
	my $sth = eval {$dbh->column_info('', '%', $table, '%')}  ||
	    eval {$dbh->column_info('', "'%'", $table, "'%'")}; # DBD::Pg bug
	$skip_reason = $dbh->errstr if !$sth;
	if ($sth) {
	    my $rows = $sth->fetchall_arrayref();
	    $skip_reason = "No rows returned for column_info on $table"
		if (@$rows == 0);
	    $sth->finish;
	}
	$skip_reason ||= $@ if $@;
    }
    if ($skip_reason) {
	print STDERR "\n\n SKIPPNG: $skip_reason\n\n";
	foreach (2 .. 3) { skip (1, 0); }
	exit 0;
    }
    $dbh->disconnect() if $dbh;
}


system ("$perl  -I blib/lib  bin/generate '$dbname' '$table' > $per_file");

ok(-e $per_file && ! -z $per_file);


print TTY "\n\nAbout to invoke 'perform' on the screen generated from " ,
    "$dbclass:$dbname:$table...\n";
print TTY '*** Type "e" to exit it. ***   (pausing for read...)', $/, $/;
sleep(3);
print TTY "\nStarting...\n";

system ("$perl -I blib/lib bin/perform $per_file > /dev/tty");

ok(3);

