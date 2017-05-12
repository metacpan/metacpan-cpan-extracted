use strict;

eval {require DBI;};
print "DBIx::TableReferences::MSSQL requires DBI" and exit if $@;

use ExtUtils::MakeMaker;
use DBI;
use Data::Dumper;

unless (grep { /^ODBC$/ } DBI->available_drivers) {
    print "DBIx::TableReferences::MSSQL requires ODBC";
    exit 0; # die "DBIx::TableReferences::MSSQL requires ODBC";
}

use lib 'testconfig';
my $Config;
eval q[
    use DBIx::TableReferences::MSSQL::TestConfig;
    $Config = DBIx::TableReferences::MSSQL::TestConfig->Config;
];

if (not $ARGV[0] =~ /^-s(etup)?$/) {

    print qq[
        For the test suite, we use the database connection info specified
        during the previous run. If you want to change the values, run
        perl Makefile.PL -s.
    \n];

} 

unless ($Config->{server}) {

    # defaults
    $Config->{server} = '(local)';
    $Config->{database} = 'pubs';
    $Config->{uid} = 'sa';
    $Config->{pwd} = '';
    
    print qq[
        I need to connect to a MS SQL 2000 database to run the test suite. 
        Please supply the connection information that I can use for testing.

        WARNING: These tests will drop and create tables named 'DBIx_TR_TEMP...'
        
        Enter "NONE" (without the quotes) to indicate an empty string
        for a config value.

        Enter "SKIP" (without the quotes) at the first prompt to skip the 
        test suite completely during the build/install process.
    \n];

    for (qw/server database uid pwd/) {
        $Config->{$_} = prompt "The $_ for tests:", $Config->{$_};
        $Config->{$_} = "" if $Config->{$_} eq "NONE";

        if ($Config->{server} =~ /^skip$/i) {
            print "\nOK - The test suite will be SKIPPED!\n";
	    last;
        }
    }
}


print qq[        
        Current values:
            server   = '$Config->{server}'
            database = '$Config->{database}'
            uid      = '$Config->{uid}'
            pwd      = '$Config->{pwd}'
\n] unless $Config->{server} =~ /^skip$/i;


use File::Path;
mkpath "testconfig/DBIx/TableReferences/MSSQL", 0, 0700;

open OUT, '>testconfig/DBIx/TableReferences/MSSQL/TestConfig.pm'
    or die "Error writing the TestConfig\n";

print OUT
    "package DBIx::TableReferences::MSSQL::TestConfig;\n",
    "sub Config {\n",
        Dumper($Config),
    "};\n1;\n";

close OUT;

WriteMakefile(
    NAME          => 'DBIx::TableReferences::MSSQL',
    VERSION_FROM  => 'lib/DBIx/TableReferences/MSSQL.pm',
    PREREQ_PM     => { DBI => 0,
                       Carp => 0,
                       'Test::More' => 0 },
    clean         => { FILES => "testconfig" },
    AUTHOR        => 'Edward Guiness <EdwardG@cpan.org>',
);
