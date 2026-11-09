use strict;
use warnings;

use Test::More;

# karr k96 -- _create_temp_db and _drop_temp_db do not end a transaction that is
# not theirs. They used to `COMMIT` and switch `local $dbh->{AutoCommit} = 1`
# (which in DBI commits an open transaction as well). CREATE/DROP DATABASE do
# not run in a transaction on ASE, so the methods need a handle with AutoCommit
# and refuse one without, before any statement: no COMMIT, no USE master, no
# size query, no handler swap, and the handle's AutoCommit stays what it was.

use DBIO::Sybase::Deploy;

{
  package K96::Dbh;
  sub new { bless { AutoCommit => $_[1], db => 'testdb', log => [], queries => [] }, $_[0] }
  sub selectrow_array {
    my ($self, $sql) = @_;
    push @{ $self->{queries} }, $sql;
    return $self->{db} if $sql =~ /db_name/i;
    return (16384, 1536, 850) if $sql =~ /^SELECT \@\@maxpagesize/;
    return 1;
  }
  sub do {
    my ($self, $sql) = @_;
    push @{ $self->{log} }, $sql;
    $self->{db} = $1 if $sql =~ /^USE\s+(\S+)$/i;
    1;
  }
  sub err { undef }
}
{ package K96::Schema; sub sources { () } }

my $deploy = bless { schema => bless({}, 'K96::Schema') }, 'DBIO::Sybase::Deploy';

for my $method (qw(_create_temp_db _drop_temp_db)) {
  my $dbh = K96::Dbh->new(0);
  $dbh->{syb_err_handler} = my $own = sub { 1 };

  my $ok  = eval { $deploy->$method($dbh, '_dbio_tmp_1_2_3'); 1 };
  my $err = $@;

  ok(!$ok, "$method: a handle without AutoCommit is refused");
  like($err, qr/\Q$method\E/, "$method: ... the error names the method");
  like($err, qr/AutoCommit/, "$method: ... and the reason");
  is_deeply($dbh->{log}, [], "$method: ... no statement ran (no COMMIT, no USE master)");
  is_deeply($dbh->{queries}, [], "$method: ... no query ran either");
  is($dbh->{AutoCommit}, 0, "$method: ... the transaction is still open (AutoCommit untouched)");
  is($dbh->{syb_err_handler}, $own, "$method: ... the error handler was not touched");
}

{
  my $dbh  = K96::Dbh->new(1);
  my $name = eval { $deploy->_create_temp_db($dbh) };
  ok(defined $name, "AutoCommit on: _create_temp_db runs") or diag $@;
  ok(eval { $deploy->_drop_temp_db($dbh, $name) }, '... and _drop_temp_db') or diag $@;
  is($dbh->{AutoCommit}, 1, '... AutoCommit stays on');
  ok(!(grep { /^COMMIT$/i } @{ $dbh->{log} }), '... and no COMMIT is sent');
  ok((grep { /^CREATE DATABASE \Q$name\E/ } @{ $dbh->{log} }), '... CREATE DATABASE was sent');
  ok((grep { /^DROP DATABASE \Q$name\E$/ } @{ $dbh->{log} }), '... DROP DATABASE was sent');
}

done_testing;
