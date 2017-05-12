# $Id$
# Shows how to enable ODBC API tracing for this Perl script.
# NOTE: the ODBC Driver manager does the actual tracing
use strict;
use warnings;
use DBI;

my $h = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS},
                     {odbc_trace_file => 'c:\users\martin\odbc.trc',
                      odbc_trace => 1});
print "trace is ", $h->{odbc_trace}, ", ", $h->{odbc_trace_file}, "\n";
my $s = $h->prepare('select 1');
$s->execute;
$h->{odbc_trace} = 0;
print "trace is ", $h->{odbc_trace}, "\n";
$s->fetch;
$s->fetch;
$h->{odbc_trace} = 1;
print "trace is ", $h->{odbc_trace}, "\n";
$h->disconnect;
