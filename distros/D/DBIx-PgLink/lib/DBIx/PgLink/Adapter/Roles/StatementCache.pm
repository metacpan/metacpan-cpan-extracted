package DBIx::PgLink::Adapter::Roles::StatementCache;

use Moose::Role;
use Tie::Cache::LRU;
use DBIx::PgLink::Logger;

has 'statement_cache_size' => (
  is => 'rw',
  isa => 'Int',
  lazy => 1,
  default => sub { 100 },
  trigger => sub {
    my $self = shift;
    my $cache_obj = tied %{$self->dbh->{CachedKids}} or return;
    trace_msg('INFO', "DBI cached statements number now limited to " 
      . $self->statement_cache_size) if trace_level >= 2;
    $cache_obj->max_size($self->statement_cache_size);
  },
);

after 'connect' => sub {
  my $self = shift;
  trace_msg('INFO', "DBI cached statements number now limited to " 
    . $self->statement_cache_size) if trace_level >= 2;
  my $cache = $self->dbh->{CachedKids};
  tie %{$cache}, 'Tie::Cache::LRU', $self->statement_cache_size;
  $self->dbh->{CachedKids} = $cache;
};

1;
