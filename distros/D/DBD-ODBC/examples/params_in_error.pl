# $Id$
#
# Code to demonstrate new (experimental) odbc_getdiag* and how you can find
# the bound parameter/column in error
#
use DBI qw(:sql_types);
use strict;
use warnings;
use Data::Dumper;
use DBD::ODBC qw(:diags);

my $h = DBI->connect('dbi:ODBC:baugi','sa','easysoft',
                     {RaiseError => 1, PrintError => 0});

eval {
    local $h->{PrintError} = 0;
    $h->do(q/drop table test/);
    $h->do(q/drop table test2/);
};

$h->do(q/create table test (a int, b int)/);
$h->do(q/create table test2 (a varchar(20), b varchar(20))/);

my $s = $h->prepare(q/insert into test values(?,?)/);
$s->bind_param(1, 'fred');
$s->bind_param(2, 1);
eval {
    $s->execute;
};
if ($@) {
    # NOTE from 1.34_3 calling odbc_getdiag* would clear DBI's errors
    # and so if you wanted them you'd have to call DBI's error methods first.
    # From 1.34_4 calling odbc_getdiag* will not clear DBI's errors.
    my @diags = $s->odbc_getdiagrec(1);
    my $dbierr = $s->errstr;
    print <<"EOT";
DBI error is $dbierr
which was created from the ODBC diagnostics:
  $diags[0]
  $diags[1]
  $diags[2]
EOT
    my $p = $s->odbc_getdiagfield(1, SQL_DIAG_COLUMN_NUMBER);
    print "The parameter in error is $p\n";
}

$h->do(q/insert into test2 values(?,?)/, undef, 1, 'fred');
$s = $h->prepare(q/select a,b from test2/);
$s->execute;
my ($a, $b);
$s->bind_col(1, \$a, {TYPE => SQL_INTEGER});
$s->bind_col(2, \$b, {TYPE => SQL_INTEGER});
eval {
    $s->fetch;
};
if ($@) {
    # NOTE from 1.34_3 calling odbc_getdiag* would clear DBI's errors
    # and so if you wanted them you'd have to call DBI's error methods first.
    # From 1.34_4 calling odbc_getdiag* will not clear DBI's errors.
    my @diags = $s->odbc_getdiagrec(1);
    my $dbierr = $s->errstr;
    print <<"EOT";
DBI error is $dbierr
which was created from the ODBC diagnostics:
  $diags[0]
  $diags[1]
  $diags[2]
EOT
    my $p = $s->odbc_getdiagfield(1, SQL_DIAG_COLUMN_NUMBER);
    print "The column in error is $p\n";
}
