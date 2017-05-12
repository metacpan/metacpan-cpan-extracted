# $Id$
# backup and restore a MS SQL Server database
# needs to loop over odbc_more_results or the procedure does not finish
use DBI;
use strict;
use warnings;
use Data::Dumper;

sub _error_handler {
    print Dumper(\@_);
    0;
}

my $h = DBI->connect;
$h->{RaiseError} = 1;
$h->{HandleError} = \&_error_handler;

eval {$h->do('create database foo');};

$h->do(q{backup database foo to disk='c:\foo.bak'});

my $s = $h->prepare(q{restore database foo from disk='c:\foo.bak'});
$s->execute;

while ($s->{odbc_more_results}) {
    print "More\n";
}
