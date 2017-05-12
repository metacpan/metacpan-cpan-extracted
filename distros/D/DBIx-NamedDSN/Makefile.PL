use 5.005;
use ExtUtils::MakeMaker;

print<<END;

Welcome to the configuration process for DBIx::NamedDSN!

We just need to find out where you are going to store the config-
uration file for DBIx::NamedDSN.  This is where you define the
mappings between the short name and the actual data sources.

This is a system-wide default; in future versions, a per-user
default will be available.

END

$location=prompt("Where should we look for the configuration file?\n",'/usr/local/etc');
$conf_name="named_dsn.conf";

if (-e $location) {
    if (-d _) {
	print "$location found...great!\n";
    }
    else {
	print "$location exists but does not appear to be a directory.  You're not trying to fool me, are you...?\n";
    }
}
else {
    eval {
	print "Attempting to create $location...";
	mkdir($location) or die;
    };
    if ($@) {
	print "Failed directory creation.  Continuing anyway.\n";
    }
    else {
	print "success!\n";
    }
}

$location.="/$conf_name";

if (-f $location) {
    "Configuration file found at $location!\n";
}
else {
    print "$location not found...we'll create a stub now.\n";
    
    eval {
	open FH, ">$location" or die ("Could not open $location for writing");
	print FH<<STUB;
# named_dsn.conf

# This is the stub configuration file for DBIx::NamedDSN (version
# 0.01).  Use this file to define your data source names and
# connection strings and optional login credentials.

# This file consists of up to four tab-separated columns.  The first
# column is the unique name given to this configuration.  This should
# be a single word which matches the perl regexp /^\w+\$/.  This name
# is what you refer to in your programs when you want to connect to
# the given data source.

# The second column is the dsn passed to the DBI's connect method.
# Currently the only criterion for this string is that it begins with
# the characters "dbi" and contains no tabs.  DBIx::NamedDSN currently
# does no validation on the contents of this string, merely passing it
# onto the DBI, so you should test carefully.

# The third and fourth columns are the optional user and password to
# pass to connect to the given database.  If you require
# authentication, these fields can be provided here or used in the
# DBIx::NamedDSN->connect(...) method.

# Examples:
# 
# testdb1	dbi:Pg:dbname=test	test	test
# testdb2	dbi:SQLite:file=testdb2
# testdb3	dbi:ObscureDriver:very=long;and_specific=options;dont_forget=these
# testdb4	dbi:Multiplex:dbi:Pg:dbname=db1|dbi:Pg:dbname=db2|dbi:Pg:dbname=db3

# In code, just replace your DBI->connect(long_dsn_string_and_auth)
# calls with DBIx::NamedDSN->connect(shortname).

# See `perldoc DBIx::NamedDSN' for more details.

STUB
    };
    
    if ($@) {
	print "hmm...stub file couldn't be created.  This is the error I got:\n$@\n";
	print "We'll proceed anyway...just create this file yourself at some future time.\n";
    }
}

WriteMakefile(
    NAME              => 'DBIx::NamedDSN',
    VERSION_FROM      => 'lib/DBIx/NamedDSN.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    clean             => {FILES=>"*~"},
    PM_FILTER         => qq{perl -pe "s{\\\@NAMED_DSN_CONFIG\@}{$location}"},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DBIx/NamedDSN.pm', # retrieve abstract from module
       AUTHOR         => 'David Christensen <dwc@dwci.net>') : ()),
);
