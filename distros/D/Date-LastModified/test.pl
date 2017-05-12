# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# ------ pragmas + requires
require "ctime.pl";
use Test::More;
use Date::Format;
use Date::LastModified;
use Cwd;
use Date::Parse;
use File::Spec;
use File::stat;
eval {
    use DBI;
};
use strict;
use warnings;


# ------ define variables
my $dbh        = "";    # DBI object
my %dbi        = ();    # DBI databases
my $dbi_params = "";    # DBI database parameters hashref
my $dlm        = "";    # Date::LastModified object
my $file       = "";    # current filename
my $now        = "";    # current time for testing
my $num_dbs    = 0;     # number of database types to test
my $num_tests  = 0;     # number of tests to perform
my $sql        = "";    # SQL to manually accessing DB to check results
my $stat       = "";    # stat() results on $new_file
my $stat_time  = "";    # (printable) last-modified time from $stat
my $sth        = "";    # DBI statement handle
my $tmpdir              # temp dir for test files
 = File::Spec->tmpdir();


# ------ since we can load, prepare test directories
$tmpdir = "$tmpdir/Date-LastModified";
if (!-d $tmpdir) {
    if (-e $tmpdir) {
        unlink($tmpdir)
         || die "can't remove '$tmpdir' because: $!\n";
    }
    mkdir($tmpdir)
     || die "can't make directory '$tmpdir' because: $!\n";
    chmod(0700, $tmpdir)
     || die "can't change mode of '$tmpdir' to 0700 because: $!\n";
}
$now = time();
sub test_make_dir {
    my $name = shift;   # directory name + name of newest file in dir
    my $time = shift;   # modification + access time for dir

    mkdir("$tmpdir/$name")
     || die "can't make $name because: $!\n";
    open(OFH, ">$tmpdir/$name/file-new")
     || die "can't create $name/file-new because: $!\n";
    close(OFH)
     || die "can't close $name/file-new because: $!\n";
    open(OFH, ">$tmpdir/$name/old-file-1")
     || die "can't create $name/old-file-1 because: $!\n";
    close(OFH)
     || die "can't close $name/old-file-1 because: $!\n";
    utime($time - 60, $time - 60, "$tmpdir/$name/old-file-1")
     || die "can't change time on old-file-1 because: $!\n";
    open(OFH, ">$tmpdir/$name/old-file-2")
     || die "can't create $name/old-file-2 because: $!\n";
    close(OFH)
     || die "can't close $name/old-file-2 because: $!\n";
    utime($time - 120, $time - 120, "$tmpdir/$name/old-file-2")
     || die "can't change time on old-file-2 because: $!\n";
    utime($time, $time, "$tmpdir/$name/file-new")
     || die "can't change time on $name/file-new because: $!\n";
    utime($time, $time, "$tmpdir/$name")
     || die "can't change time on $name because: $!\n";
}
if (!-d "$tmpdir/dir-new") {
    test_make_dir("dir-new", $now);
    test_make_dir("dir-mid", $now - 24 * 60 * 60);       # 1 day old
    test_make_dir("dir-old", $now - 24 * 60 * 60 * 365); # 1 year old
}
$stat = stat("$tmpdir/dir-new/file-new")
 or die "can't stat $tmpdir/dir-new/file-new because: $!\n";
$stat_time = ctime($stat->mtime);


# ------ request database parameters for each known database
sub test_dbi_params {
    my $name     = shift;       # friendly name of database
    my $dbi_name = shift;       # DBI's name for database
    my $db       = "";          # database name
    my $params   = {};          # database parameters

    print "$name database name, or (none) if no $name: ";
    $db = <STDIN>;
    if ($db !~ m/^\s*$/) {
        chomp($db);
        $params->{"dbi"}      = "dbi:$dbi_name:$db";
        print "$name username: ";
        $_ = <STDIN>;
        chomp;
        $params->{"username"} = $_;
        print "$name password: ";
        $_ = <STDIN>;
        chomp;
        $params->{"password"} = $_;
        print "$name table: ";
        $_ = <STDIN>;
        chomp;
        $params->{"table"}    = $_;
        print "$name last-modified date column in $params->{table}: ";
        $_ = <STDIN>;
        chomp;
        $params->{"column"}   = $_;
        return $params;
    }

    return undef;
}
print "\n";
if (-e "$tmpdir/datelastmod-dbi-mysql-1.cfg") {
    $num_dbs++;
    $file = "$tmpdir/dbi-mysql-cache";
    open(IFH, $file) || die "can't open $file because: $!\n";
    $_ = <IFH>;
    chomp;
    $dbi{"mysql"}->{"dbi"}      = $_;
    $_ = <IFH>;
    chomp;
    $dbi{"mysql"}->{"username"} = $_;
    $_ = <IFH>;
    chomp;
    $dbi{"mysql"}->{"password"} = $_;
    $_ = <IFH>;
    chomp;
    $dbi{"mysql"}->{"table"}    = $_;
    $_ = <IFH>;
    chomp;
    $dbi{"mysql"}->{"column"}    = $_;
    close(IFH) || die "can't close $file because: $!\n";
    print "\nUsing cached MySQL parameters...\n";
} else {
    $dbi_params = test_dbi_params("MySQL", "mysql");
    if (defined($dbi_params)) {
    	$num_dbs++;
        $dbi{"mysql"} = $dbi_params;
    }
    print "\n";
}
if (-e "$tmpdir/datelastmod-dbi-Oracle-1.cfg") {
    $num_dbs++;
    $file = "$tmpdir/dbi-Oracle-cache";
    open(IFH, $file) || die "can't open $file because: $!\n";
    $_ = <IFH>;
    chomp;
    $dbi{"Oracle"}->{"dbi"}      = $_;
    $_ = <IFH>;
    chomp;
    $dbi{"Oracle"}->{"username"} = $_;
    $_ = <IFH>;
    chomp;
    $dbi{"Oracle"}->{"password"} = $_;
    $_ = <IFH>;
    chomp;
    $dbi{"Oracle"}->{"table"}    = $_;
    $_ = <IFH>;
    chomp;
    $dbi{"Oracle"}->{"column"}    = $_;
    close(IFH) || die "can't close $file because: $!\n";
    print "\nUsing cached Oracle parameters...\n";
} else {
    $dbi_params = test_dbi_params("Oracle", "Oracle");
    if (defined($dbi_params)) {
    	$num_dbs++;
        $dbi{"Oracle"} = $dbi_params;
    }
    print "\n";
}
if (-e "$tmpdir/datelastmod-dbi-SQLite-1.cfg") {
    $num_dbs++;
    $file = "$tmpdir/dbi-SQLite-cache";
    open(IFH, $file) || die "can't open $file because: $!\n";
    $_ = <IFH>;
    chomp;
    $dbi{"SQLite"}->{"dbi"}      = $_;
    $_ = <IFH>;
    chomp;
    $dbi{"SQLite"}->{"username"} = $_;
    $_ = <IFH>;
    chomp;
    $dbi{"SQLite"}->{"password"} = $_;
    $_ = <IFH>;
    chomp;
    $dbi{"SQLite"}->{"table"}    = $_;
    $_ = <IFH>;
    chomp;
    $dbi{"SQLite"}->{"column"}    = $_;
    close(IFH) || die "can't close $file because: $!\n";
    print "\nUsing cached SQLite parameters...\n";
} else {
    $dbi_params = test_dbi_params("SQLite", "SQLite");
    if (defined($dbi_params)) {

		# make AppConfig in DLM happy by forcing something for
		# username and password -- they'll be ignored anyway
        $dbi_params->{"username"} = "x$dbi_params->{username}";
        $dbi_params->{"password"} = "x$dbi_params->{password}";

    	$num_dbs++;
        $dbi{"SQLite"} = $dbi_params;
    }
    print "\n";
}


# ------ extract last-modified date from each known database
sub test_dbi_error {
    my $err = shift;            # error message string

    if (defined($err) && $err !~ m/^\s*$/) {
        die "Internal database error: $err\n";
    }
}
if (exists($dbi{"mysql"})) {
    $sql =<<endSQL;
 SELECT
  UNIX_TIMESTAMP($dbi{mysql}->{column})
 FROM
  $dbi{mysql}->{table}
 ORDER BY
  $dbi{mysql}->{column}
  DESC
endSQL
    $dbh = DBI->connect($dbi{"mysql"}->{"dbi"},
     $dbi{"mysql"}->{"username"}, $dbi{"mysql"}->{"password"});
    test_dbi_error(DBI::errstr);
    $sth = $dbh->prepare($sql);
    test_dbi_error($sth->errstr);
    $sth->execute();
    test_dbi_error($sth->errstr);
    ($dbi{"mysql"}->{"last"}) = $sth->fetchrow_array();
    test_dbi_error($sth->errstr);
    $sth->finish();
}
if (exists($dbi{"Oracle"})) {
    $sql =<<endSQL;
 SELECT
  TO_CHAR($dbi{Oracle}->{column}, 'YYYY-MM-DD HH24:MI:SS')
 FROM
  $dbi{Oracle}->{table}
 ORDER BY
  $dbi{Oracle}->{column}
  DESC
endSQL
    $dbh = DBI->connect($dbi{"Oracle"}->{"dbi"},
     $dbi{"Oracle"}->{"username"}, $dbi{"Oracle"}->{"password"});
    test_dbi_error(DBI::errstr);
    $sth = $dbh->prepare($sql);
    test_dbi_error($sth->errstr);
    $sth->execute();
    test_dbi_error($sth->errstr);
    ($dbi{"Oracle"}->{"last"}) = $sth->fetchrow_array();
    test_dbi_error($sth->errstr);
    $sth->finish();
    ($dbi{"Oracle"}->{"last"}) = str2time($dbi{"Oracle"}->{"last"});
}
if (exists($dbi{"SQLite"})) {
    $sql =<<endSQL;
 SELECT
  $dbi{SQLite}->{column}
 FROM
  $dbi{SQLite}->{table}
 ORDER BY
  $dbi{SQLite}->{column}
  DESC
endSQL
    $dbh = DBI->connect($dbi{"SQLite"}->{"dbi"},
     $dbi{"SQLite"}->{"username"}, $dbi{"SQLite"}->{"password"});
    test_dbi_error(DBI::errstr);
    $sth = $dbh->prepare($sql);
    test_dbi_error($sth->errstr);
    $sth->execute();
    test_dbi_error($sth->errstr);
    ($dbi{"SQLite"}->{"last"}) = $sth->fetchrow_array();
    test_dbi_error($sth->errstr);
    $sth->finish();
    ($dbi{"SQLite"}->{"last"}) = str2time($dbi{"SQLite"}->{"last"});
}


# ------ calculate number of tests needed
$num_tests = 20;
if (exists($dbi{"mysql"})) {
    $num_tests += 4;
}
if (exists($dbi{"Oracle"})) {
    $num_tests += 4;
}
if (exists($dbi{"SQLite"})) {
    $num_tests += 4;
}
if ($num_dbs > 1) {
    $num_tests++;
}
plan(tests => $num_tests);


# ------ database test file generators
sub test_db_make_one_file {
    my $file = shift;           # database config file name
    my $code = shift;           # coderef to run on file

    open(OFH, ">$file") || die "can't create $file because: $!\n";
    &$code();
    close(OFH) || die "can't close $file because: $!\n";
    chmod(0600, $file) || die "can't chmod $file because: $!\n";
}
sub test_db_make_files {
    my $db     = shift;         # database info
    my $name   = shift;         # database name
    my $create = "";            # code to create file contents

    # ------ create database info cache file
    $create = sub {
        print OFH<<endPRINT;
$db->{dbi}
$db->{username}
$db->{password}
$db->{table}
$db->{column}
endPRINT
    };
    test_db_make_one_file("$tmpdir/dbi-$name-cache", $create);

    # ------ config for one database resource, user+pass sent directly
    $create = sub {
        print OFH<<endPRINT;
dlm_dbi = $db->{dbi},$db->{username},$db->{password},$db->{table},$db->{column}
endPRINT
    };
    test_db_make_one_file("$tmpdir/datelastmod-dbi-$name-1.cfg", $create);

    # ------ create password file
    $create = sub {
        print OFH <<endPASSFILE;
DbUsername $db->{username}
DbPassword $db->{password}
endPASSFILE
    };
    test_db_make_one_file("$tmpdir/dbi-$name-passwd", $create);

    # ------ config file for one database resource, using password file
    $create = sub {
        print OFH<<endPRINT;
dlm_dbi = $db->{dbi},$tmpdir/dbi-$name-passwd,$db->{table},$db->{column}
endPRINT
    };
    test_db_make_one_file("$tmpdir/datelastmod-dbi-$name-1indir.cfg", $create);

    # ------ config file for database resource newer than other resource
    $create = sub {
        print OFH<<endPRINT;
dlm_dbi = $db->{dbi},$db->{username},$db->{password},$db->{table},$db->{column}
dlm_file = $tmpdir/dir-old/file-new
endPRINT
    };
    test_db_make_one_file("$tmpdir/datelastmod-dbi-$name-newdb.cfg", $create);

    # ------ config file for database resource older than other resource
    $create = sub {
        print OFH<<endPRINT;
dlm_dbi = $db->{dbi},$db->{username},$db->{password},$db->{table},$db->{column}
dlm_file = $tmpdir/dir-new/file-new
endPRINT
    };
    test_db_make_one_file("$tmpdir/datelastmod-dbi-$name-olddb.cfg", $create);
}


# ------ generate non-DB test files from template files
sub test_template_file {
    my $file = shift;           # template file

    open(IFH, "t-extras/$file")
     || die "can't open 't-extras/$file' because: $!\n";
    open(OFH, ">$tmpdir/$file")
     || die "can't create '$tmpdir/$file' because: $!\n";
    while (<IFH>) {
        s/t-extras/$tmpdir/g;
        print OFH $_;
    }
    close(IFH)
     || die "can't close 't-extras/$file' because: $!\n";
    close(OFH)
     || die "can't close '$tmpdir/$file' because: $!\n";
}
for my $file (qw(
    datelastmod-1dir.cfg
    datelastmod-1file.cfg
    datelastmod-2dir-new1.cfg
    datelastmod-2dir-new2.cfg
    datelastmod-2file-new1.cfg
    datelastmod-2file-new2.cfg
    datelastmod-3dir-new1.cfg
    datelastmod-3dir-new3.cfg
    datelastmod-3file-new1.cfg
    datelastmod-3file-new3.cfg
    datelastmod-dir-file-new.cfg
    datelastmod-dir-file-old.cfg
    datelastmod-empty.cfg
)) {
    test_template_file($file);
}


# ------ generate test files for databases
if (exists($dbi{"mysql"}) && !-e "$tmpdir/datelastmod-dbi-mysql-1.cfg") {
    test_db_make_files($dbi{"mysql"}, "mysql");
}
if (exists($dbi{"Oracle"}) && !-e "$tmpdir/datelastmod-dbi-Oracle-1.cfg") {
    test_db_make_files($dbi{"Oracle"}, "Oracle");
}
if (exists($dbi{"SQLite"}) && !-e "$tmpdir/datelastmod-dbi-SQLite-1.cfg") {
    test_db_make_files($dbi{"SQLite"}, "SQLite");
}
if ($num_dbs > 1
 && !-e "$tmpdir/datelastmod-dbi-2dbs.cfg") {
    my $create = sub {
        my $oracle = $dbi{"Oracle"};
        my $mysql  = $dbi{"mysql"};

        print OFH<<endPRINT;
dlm_dbi = $mysql->{dbi},$mysql->{username},$mysql->{password},$mysql->{table},$mysql->{column}
dlm_dbi = $oracle->{dbi},$oracle->{username},$oracle->{password},$oracle->{table},$oracle->{column}
endPRINT
    };
    test_db_make_one_file("$tmpdir/datelastmod-dbi-2dbs.cfg", $create);
}


# ------ load OK without errors
ok(1, "load without errors");


# ------ empty config - no file or hash
eval {
    $dlm = new Date::LastModified;
};
like($@, qr{no resources to use by Date::LastModified},
 "empty config - no file or hash");


# ------ missing config file
eval {
    $dlm = new Date::LastModified("$tmpdir/datelastmod-never-exist.cfg");
};
like($@, qr{can't read '$tmpdir/datelastmod-never-exist.cfg'},
 "missing config file");


# ------ empty config file
eval {
    $dlm = new Date::LastModified("$tmpdir/datelastmod-empty.cfg");
};
like($@, qr{no resources to use by Date::LastModified},
 "empty config file");


# ------ one file resource (config file OK)
$dlm = new Date::LastModified("$tmpdir/datelastmod-1file.cfg");
is(ref($dlm), "Date::LastModified",
 "one file resource (config file OK)");


# ------ check one file resource
is(ctime($dlm->last), $stat_time,
 "one file resource (date OK)");


# ------ from() OK for one resource
like($dlm->from, qr/file:/, "from() OK for one resource");


# ------ check two file resources, newest first
$dlm = new Date::LastModified("$tmpdir/datelastmod-2file-new1.cfg");
is(ctime($dlm->last), $stat_time,
 "two file resources, newest first");


# ------ check two file resources, newest second
$dlm = new Date::LastModified("$tmpdir/datelastmod-2file-new2.cfg");
is(ctime($dlm->last), $stat_time,
 "two file resources, newest second");


# ------ check many file resources, newest first
$dlm = new Date::LastModified("$tmpdir/datelastmod-3file-new1.cfg");
is(ctime($dlm->last), $stat_time,
 "many file resources, newest first");


# ------ check many file resources, newest last
$dlm = new Date::LastModified("$tmpdir/datelastmod-3file-new3.cfg");
is(ctime($dlm->last), $stat_time,
 "many file resources, newest last");


# ------ check one directory resource
$dlm = new Date::LastModified("$tmpdir/datelastmod-1dir.cfg");
is(ctime($dlm->last), $stat_time,
 "one directory resource");


# ------ check two dir resources, newest first
$dlm = new Date::LastModified("$tmpdir/datelastmod-2dir-new1.cfg");
is(ctime($dlm->last), $stat_time,
 "two dir resources, newest first");


# ------ check two dir resources, newest second
$dlm = new Date::LastModified("$tmpdir/datelastmod-2dir-new2.cfg");
is(ctime($dlm->last), $stat_time,
 "two dir resources, newest second");


# ------ check many dir resources, newest first
$dlm = new Date::LastModified("$tmpdir/datelastmod-3dir-new1.cfg");
is(ctime($dlm->last), $stat_time,
 "many dir resources, newest first");


# ------ check many dir resources, newest last
$dlm = new Date::LastModified("$tmpdir/datelastmod-3dir-new3.cfg");
is(ctime($dlm->last), $stat_time,
 "many dir resources, newest last");


# ------ check dir newer than file
$dlm = new Date::LastModified("$tmpdir/datelastmod-dir-file-old.cfg");
is(ctime($dlm->last), $stat_time,
 "dir newer than file");


# ------ NOTE on from(): checking two different resource types
# ------                 should check multiple resource types


# ------ from(): check dir newer than file
like($dlm->from, qr/^dir:/, "from(): dir newer than file");


# ------ check file newer than dir
$dlm = new Date::LastModified("$tmpdir/datelastmod-dir-file-new.cfg");
is(ctime($dlm->last), $stat_time,
 "file newer than dir");


# ------ from(): check file newer than dir
like($dlm->from, qr/^file:/, "from(): file newer than dir");


# ------ check MySQL database resources upon request
if (exists($dbi{"mysql"})) {

    # ------ check one MySQL database resource
    $dlm = new Date::LastModified( "$tmpdir/datelastmod-dbi-mysql-1.cfg");
    is(ctime($dlm->last), ctime($dbi{"mysql"}->{"last"}),
     "one MySQL database resource");
    
    
    # ------ check one MySQL database resource, using password file
    $dlm = new Date::LastModified( "$tmpdir/datelastmod-dbi-mysql-1indir.cfg");
    is(ctime($dlm->last), ctime($dbi{"mysql"}->{"last"}),
     "one MySQL database resource (using password file)");
    
    
    # ------ check that MySQL is newer than something else
    $dlm = new Date::LastModified( "$tmpdir/datelastmod-dbi-mysql-newdb.cfg");
    is(ctime($dlm->last), ctime($dbi{"mysql"}->{"last"}),
     "MySQL database resource is newer");
    
    
    # ------ check that MySQL is older than something else
    $dlm = new Date::LastModified( "$tmpdir/datelastmod-dbi-mysql-olddb.cfg");
    is(ctime($dlm->last), $stat_time,
     "MySQL database resource is old");
}


# ------ check Oracle database resources upon request
if (exists($dbi{"Oracle"})) {


    # ------ check one Oracle database resource
    $dlm = new Date::LastModified( "$tmpdir/datelastmod-dbi-Oracle-1.cfg");
    is(ctime($dlm->last), ctime($dbi{"Oracle"}->{"last"}),
     "one Oracle database resource");


    # ------ check one Oracle database resource, using password file
    $dlm = new Date::LastModified( "$tmpdir/datelastmod-dbi-Oracle-1indir.cfg");
    is(ctime($dlm->last), ctime($dbi{"Oracle"}->{"last"}),
     "one Oracle database resource (using password file)");


    # ------ check that Oracle is newer than something else
    $dlm = new Date::LastModified( "$tmpdir/datelastmod-dbi-Oracle-newdb.cfg");
    is(ctime($dlm->last), ctime($dbi{"Oracle"}->{"last"}),
     "Oracle database resource is newer");


    # ------ check that Oracle is older than something else
    $dlm = new Date::LastModified( "$tmpdir/datelastmod-dbi-Oracle-olddb.cfg");
    is(ctime($dlm->last), $stat_time,
     "Oracle database resource is old");
}


# ------ check SQLite database resources upon request
if (exists($dbi{"SQLite"})) {


    # ------ check one SQLite database resource
    $dlm = new Date::LastModified( "$tmpdir/datelastmod-dbi-SQLite-1.cfg");
    is(ctime($dlm->last), ctime($dbi{"SQLite"}->{"last"}),
     "one SQLite database resource");


    # ------ check one SQLite database resource, using password file
    $dlm = new Date::LastModified( "$tmpdir/datelastmod-dbi-SQLite-1indir.cfg");
    is(ctime($dlm->last), ctime($dbi{"SQLite"}->{"last"}),
     "one SQLite database resource (using password file)");


    # ------ check that SQLite is newer than something else
    $dlm = new Date::LastModified( "$tmpdir/datelastmod-dbi-SQLite-newdb.cfg");
    is(ctime($dlm->last), ctime($dbi{"SQLite"}->{"last"}),
     "SQLite database resource is newer");


    # ------ check that SQLite is older than something else
    $dlm = new Date::LastModified( "$tmpdir/datelastmod-dbi-SQLite-olddb.cfg");
    is(ctime($dlm->last), $stat_time,
     "SQLite database resource is old");
}


# ------ compare two databases
if ($num_dbs > 1) {
    $dlm = new Date::LastModified( "$tmpdir/datelastmod-dbi-2dbs.cfg");
    if ($dbi{"Oracle"}->{"last"} > $dbi{"mysql"}->{"last"}) {
        is(ctime($dlm->last), ctime($dbi{"Oracle"}->{"last"}),
         "compare two databases");
    } else {
        is(ctime($dlm->last), ctime($dbi{"mysql"}->{"last"}),
         "compare two databases");
    }
}


# ------ test our sample program if module tests ran OK
my @tests = Test::More->builder->summary;
my $all_ok = 1;
foreach (@tests) {
    if (!$_) {
        $all_ok = 0;
        last;
    }
}
if (!$all_ok) {
    print "\nTesting stopped due to module problems...\n";
    exit(1);
}


# ------ Test the sample program "bin/dlmup".
print "\n\nTesting dlmup sample program...\n";
print `perl test-dlmup.pl`;
