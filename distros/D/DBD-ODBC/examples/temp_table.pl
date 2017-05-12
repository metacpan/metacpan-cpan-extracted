# $Id$
#
# To access temporary tables in MS SQL Server they need to be created via
# SQLExecDirect
#
use strict;
use warnings;
use DBI;

my $h = DBI->connect();

eval {
    $h->do(q{drop table martin});
};

$h->do(q{create table martin (a int)});

$h->do('insert into martin values(1)');

my $s;
# this long winded way works:
#$s = $h->prepare('select * into #tmp from martin',
#                    { odbc_exec_direct => 1}
#);
#$s->execute;
# and this works too:
$h->do('select * into #tmp from martin');
# but a prepare without odbc_exec_direct would not work

print "NUM_OF_FIELDS: " . DBI::neat($s->{NUM_OF_FIELDS}), "\n";

$s = $h->selectall_arrayref(q{select * from #tmp});
use Data::Dumper;
print Dumper($s), "\n";
