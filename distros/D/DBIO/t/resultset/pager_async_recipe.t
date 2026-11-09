use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;
use DBIO::ResultSet::Pager;

# karr k331: the ASYNC recipe of DBIO::ResultSet::Pager builds a count-only
# resultset by hand. (ref $paged_rs)->new(...) yields an UNBOUND resultset, so
# for a $paged_rs bound with with_context the count left the transaction (or
# pipeline) it was asked for and ran on a pool connection outside it. The
# recipe binds the count resultset to the same context; this file runs the
# recipe as the POD gives it.

{
  package Test::PagerPool;
  sub new { bless { txns => 0 }, shift }
  sub acquire     { DBIO::Test::Future->done('POOL') }
  sub acquire_txn { DBIO::Test::Future->done('TXN' . ++$_[0]->{txns}) }
  sub release     { 1 }
  sub shutdown    { 1 }
}
{
  package Test::PagerBackend;
  use base 'DBIO::Storage::Async';

  sub new {
    my ($class, $schema) = @_;
    my $self = $class->SUPER::new($schema);
    $self->{captured} = [];
    return $self;
  }
  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub pool { $_[0]->{pool} ||= Test::PagerPool->new }

  sub _answer {
    my ($self, $sql, $on) = @_;
    push @{ $self->{captured} }, { sql => $sql, on => $on };
    return $self->future_class->done( $sql =~ /COUNT/ ? [ 7 ] : () );
  }
  sub _query_async        { $_[0]->_answer($_[1], 'the pool') }
  sub _query_async_pinned { $_[0]->_answer($_[2], $_[1]) }
}

DBIO::Storage::DBI->register_async_mode( pager_recipe_backend => 'Test::PagerBackend' );

sub backend_schema {
  my $schema = DBIO::Test->init_schema;
  $schema->storage->_async_mode('pager_recipe_backend');
  delete $schema->storage->{_async_storage_obj};
  return ($schema, $schema->storage->_async_storage);
}

# The POD recipe; $with_ctx selects the line that binds the count resultset.
sub pager_async {
  my ($paged_rs, $ctx, $bind) = @_;

  my $count_attrs = { %{ $paged_rs->{attrs} } };
  delete @{$count_attrs}{qw/rows offset page pager/};
  my $total_rs = (ref $paged_rs)->new($paged_rs->result_source, $count_attrs);
  $total_rs = $total_rs->with_context($ctx) if $bind;

  return $total_rs->count_async->then(sub {
    my ($resolved_count) = @_;
    return DBIO::ResultSet::Pager->new(
      $resolved_count, $paged_rs->{attrs}{rows}, $paged_rs->{attrs}{page},
    );
  });
}

for my $case ([ 'the recipe, count bound to the context', 1, 'TXN1' ],
              [ 'a count resultset left unbound (the old recipe)', 0, 'the pool' ]) {
  my ($name, $bind, $where) = @$case;
  my ($schema, $backend) = backend_schema();
  my $pager;

  my $txn = $schema->storage->txn_do_async(sub {
    my ($ctx) = @_;
    my $paged_rs = $schema->resultset('Artist')
      ->search({ rank => { '>' => 1 } }, { rows => 3, page => 2 })
      ->with_context($ctx);
    return pager_async($paged_rs, $ctx, $bind)->then(sub { $pager = $_[0]; 1 });
  });
  ok eval { $txn->get; 1 }, "$name: the transaction resolves" or diag $@;

  my @counts = grep { $_->{sql} =~ /COUNT/ } @{ $backend->{captured} };
  is scalar(@counts), 1, "$name: one count statement";
  is $counts[0]{on}, $where, "$name: the count ran on '$where'";
  unlike $counts[0]{sql}, qr/LIMIT|OFFSET/i, "$name: the count is not paged";

  is $pager->total_entries, 7, "$name: the pager has the resolved total";
  is $pager->last_page, 3, "$name: 7 entries at 3 a page make 3 pages";
}

done_testing;
