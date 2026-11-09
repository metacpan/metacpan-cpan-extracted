use strict;
use warnings;
use Test::More;

use DBIO::MSSQL::Deploy;

# karr k80. _create_temp_db / _drop_temp_db used to end the transaction of the
# handle they were given (COMMIT, then a local AutoCommit => 1, which DBI turns
# into a commit too). Now a handle with AutoCommit off is refused, loudly and
# before any statement; the transaction stands. A handle with AutoCommit on
# works as before.

{
  package T115::Dbh;
  sub new { bless { AutoCommit => $_[1], log => [] }, $_[0] }
  sub FETCH { $_[0]{$_[1]} }
  sub STORE { $_[0]{$_[1]} = $_[2] }
  sub do { push @{ $_[0]{log} }, $_[1]; 1 }
  sub selectrow_array { push @{ $_[0]{log} }, 'SELECT collation'; 'SQL_Latin1_General_CP1_CI_AS' }
  sub commit { push @{ $_[0]{log} }, 'commit()'; 1 }
}

my $deploy = bless {}, 'DBIO::MSSQL::Deploy';

for my $m (qw/_create_temp_db _drop_temp_db/) {
  my $dbh = T115::Dbh->new(0);
  my @args = $m eq '_drop_temp_db' ? ('_dbio_tmp_1_2') : ();
  my $ok = eval { $deploy->$m($dbh, @args); 1 };
  my $err = $@;
  ok !$ok, "$m refuses a handle with AutoCommit off";
  isa_ok $err, 'DBIO::Exception';
  like "$err", qr/\Q$m\E/, "$m: the message names the method";
  like "$err", qr/AutoCommit/, "$m: ... and the reason";
  unlike "$err", qr/dbi:|password/i, "$m: no DSN or password in it";
  is_deeply $dbh->{log}, [], "$m: no statement was executed, no COMMIT sent";
  is $dbh->{AutoCommit}, 0, "$m: the transaction stands (AutoCommit still off)";
}

{
  my $dbh = T115::Dbh->new(1);
  my $name = $deploy->_create_temp_db($dbh);
  like $name, qr/^_dbio_tmp_\d+_\d+$/, 'AutoCommit on: a throwaway name';
  is_deeply $dbh->{log},
    [ 'SELECT collation', "CREATE DATABASE $name COLLATE SQL_Latin1_General_CP1_CI_AS" ],
    '... CREATE DATABASE with the collation, nothing else';
  @{ $dbh->{log} } = ();
  $deploy->_drop_temp_db($dbh, $name);
  is_deeply $dbh->{log}, ["DROP DATABASE $name"], '... DROP DATABASE';
  is $dbh->{AutoCommit}, 1, '... AutoCommit untouched';
}

done_testing;
