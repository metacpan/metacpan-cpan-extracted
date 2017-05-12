#!perl

use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# Write out the makefile
WriteMakefile(
    "NAME"             => "CGI::Session::ODBC",
    "VERSION_FROM"     => "ODBC.pm",
    "PREREQ_PM"        =>
    {
        "CGI::Session" => undef,
        "DBI"          => undef,
        "DBD::ODBC"    => undef,
    },
    "ABSTRACT_FROM"    => "ODBC.pm",
    "AUTHOR"           => "Jason A. Crome <cromedome\@cpan.org>",
);

# Make sure we have database connection information so our testing suite
# runs properly.
print "Warning: environment variable DBI_DSN not set.\n" unless $ENV{DBI_DSN};
print "Warning: DBI_DSN ($ENV{DBI_DSN}) doesn't start with 'DBI:ODBC:'\n"
    if($ENV{DBI_DSN} && $ENV{DBI_DSN} !~ m/^DBI:ODBC:/);
print "Warning: environment variable DBI_USER not set.\n" unless $ENV{DBI_USER};
print "Warning: environment variable DBI_PASS not set.\n" unless $ENV{DBI_PASS};

# Environment not set up correctly?  Tell the user how to remedy.
print qq{
Warning: not all required environment variables are set.  The
CGI::Session::ODBC test suite will be skipped.  If you wish to
run tests, please set the following environment variables:
    DBI_DSN=Your datasource name (i.e. DBI:ODBC:Northwind)
    DBI_USER=Your database login name (i.e. sa)
    DBI_PASS=Your database password (i.e. testpass)
} unless ($ENV{DBI_DSN} && $ENV{DBI_USER} && $ENV{DBI_PASS});

# Looks good.  Show the user what our plans are.
print qq{
The CGI::Session::ODBC tests will use these values for the database connection:
    DBI_DSN=$ENV{DBI_DSN}
    DBI_USER=$ENV{DBI_USER}
    DBI_PASS=$ENV{DBI_PASS}
} if ($ENV{DBI_DSN} && $ENV{DBI_USER} && $ENV{DBI_PASS});

print "\n";

