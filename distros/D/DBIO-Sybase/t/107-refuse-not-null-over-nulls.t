use strict;
use warnings;
use Test::More;

use DBIO::Sybase::Deploy;
use DBIO::Sybase::Diff;

# karr k97 (conformance case diff-not-null-over-nulls). A column that becomes
# NOT NULL in a table holding a NULL in it is Msg 515 half way through the
# batch of apply(). The driver refuses before the first statement is sent,
# naming table and column, and sends nothing; a table without a NULL in the
# column (or without rows) passes.

{
  package K97::Dbh;
  sub new { bless { nulls => $_[1], log => [], queries => [] }, $_[0] }
  sub selectrow_array {
    my ($self, $sql) = @_;
    push @{ $self->{queries} }, $sql;
    return $self->{nulls};
  }
  sub do { my ($self, $sql) = @_; push @{ $self->{log} }, $sql; 1 }
}
{
  package K97::Deploy;
  our @ISA = ('DBIO::Sybase::Deploy');
  sub _dbh { $_[0]{dbh} }
  sub _execute_ddl { my ($self, $dbh, @sql) = @_; push @{ $self->{ran} }, @sql; 1 }
}

sub col { +{ column_name => $_[0], data_type => 'varchar', size => 20, not_null => $_[1],
             default_value => undef, is_pk => 0 } }
sub diff_for {
  my ($from_nn, $to_nn) = @_;
  return DBIO::Sybase::Diff->new(
    source => { tables => { opt => { table_name => 'opt', kind => 'table' } },
                columns => { opt => [ col(id => 1), col(c => $from_nn) ] },
                indexes => {}, foreign_keys => {} },
    target => { tables => { opt => { table_name => 'opt', kind => 'table' } },
                columns => { opt => [ col(id => 1), col(c => $to_nn) ] },
                indexes => {}, foreign_keys => {} },
  );
}

{
  my $dbh    = K97::Dbh->new(1);
  my $deploy = bless { dbh => $dbh }, 'K97::Deploy';
  my $err    = eval { $deploy->apply(diff_for(0, 1)); 1 } ? '' : "$@";
  isa_ok $@, 'DBIO::Exception' if $err;
  like $err, qr/table opt, column c: making the column NOT NULL is refused: table opt holds rows where it is NULL/,
    'NULL -> NOT NULL over a NULL is refused, naming table and column';
  is_deeply $deploy->{ran}, undef, '... and no statement was sent';
  like $dbh->{queries}[0], qr/FROM opt WHERE c IS NULL/, '... the NULLs were looked for in the column';
}
{
  my $deploy = bless { dbh => K97::Dbh->new(0) }, 'K97::Deploy';
  ok eval { $deploy->apply(diff_for(0, 1)); 1 }, 'no NULL in the column: the change goes through' or diag $@;
  like $deploy->{ran}[0], qr/MODIFY c VARCHAR\(20\) NOT NULL/, '... as the MODIFY';
}
{
  my $dbh    = K97::Dbh->new(1);
  my $deploy = bless { dbh => $dbh }, 'K97::Deploy';
  ok eval { $deploy->apply(diff_for(1, 0)); 1 }, 'NOT NULL -> NULL is never looked at' or diag $@;
  is_deeply $dbh->{queries}, [], '... no query';
}

done_testing;
