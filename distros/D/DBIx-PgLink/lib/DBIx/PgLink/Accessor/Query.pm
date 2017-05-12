package DBIx::PgLink::Accessor::Query;

use Moose;
use MooseX::Method;
use DBIx::PgLink::Local;
use DBIx::PgLink::Types;
use DBIx::PgLink::Logger;
use Data::Dumper;

our $VERSION = '0.01';

extends 'Moose::Object';

has 'parent' => (is=>'ro', isa=>'DBIx::PgLink::Accessor::BaseAccessor', required=>1 );

has 'action' => (is=>'ro', isa=>'Action', required=>1 );

has 'query_text' => (is=>'ro', isa=>'Str', required=>1 );

has 'params' => (
  is  => 'rw',
  isa => 'ArrayRef',
  lazy => 1,
  default => sub { (shift)->load_params },
);



has 'save_param_sth' => (
  is => 'ro',
  isa => 'Object',
  lazy => 1,
  default => sub {
    pg_dbh->prepare_cached(<<'END_OF_SQL', 
INSERT INTO dbix_pglink.query_params(
  object_id,       --1
  action,          --2
  param_position,  --3
  column_name,     --4
  local_type,      --5
  remote_type,     --6
  conv_to_remote   --7
) VALUES ($1,$2,$3,$4,$5,$6,$7)
END_OF_SQL
      {no_cursor=>1, types=>[qw/INT4 TEXT INT4 TEXT TEXT TEXT TEXT/] }
      #                         1    2    3    4    5    6    7
    );
  },
);

has 'load_params_sth' => (
  is => 'ro',
  isa => 'Object',
  lazy => 1,
  default => sub {
    pg_dbh->prepare_cached(<<'END_OF_SQL', 
SELECT
  param_position,
  column_name,
  local_type,
  remote_type,
  conv_to_remote
FROM dbix_pglink.query_params
WHERE object_id = $1
  and action = $2
ORDER BY param_position
END_OF_SQL
      {no_cursor=>1, types=>[qw/INT4 TEXT/] }
    );
  },
);


sub save {
  my $self = shift;

  # delete old query (cascade to query_params)
  pg_dbh->do(<<'END_OF_SQL', 
DELETE
FROM dbix_pglink.queries
WHERE object_id = $1
  and action = $2
END_OF_SQL
    {no_cursor=>1, types=>[qw/INT4 TEXT/]},
    $self->parent->object_id,
    $self->action,
  );

  pg_dbh->do(<<'END_OF_SQL',
INSERT INTO dbix_pglink.queries(
  object_id,
  action,
  query_text
) VALUES ($1,$2,$3)
END_OF_SQL
    {no_cursor=>1, types=>[qw/INT4 TEXT TEXT/]},
    $self->parent->object_id,
    $self->action,
    $self->query_text,
  );

  $self->save_params;
};


sub save_params {
  my $self = shift;

  my $sth = $self->save_param_sth;

  my $index = 1;
  for my $param (@{$self->params}) {
    $sth->execute(
      $self->parent->object_id,         # 1
      $self->action,                    # 2
      $index++,                         # 3
      $param->{column_name},            # 4
      $param->{meta}->{local_type},     # 5
      $param->{meta}->{remote_type},    # 6
      $param->{meta}->{conv_to_remote}, # 7
    );
  }
  $sth->finish;
}


method load => named ( # constructor
  parent    => {isa=>'DBIx::PgLink::Accessor::BaseAccessor', required=>1},
  action    => {isa=>'Str', required=>1},
) => sub {
  my ($class, $p) = @_;

  my $data = pg_dbh->selectrow_hashref(<<'END_OF_SQL',
SELECT *
FROM dbix_pglink.queries
WHERE object_id = $1
  and action    = $2
END_OF_SQL
    {no_cursor=>1, Slice => {}, types=>[qw/INT4 TEXT/] },
    $p->{parent}->object_id,
    $p->{action},
  );
  confess "Cannot load accessor query for id " . $p->{parent}->object_id unless %{$data};

  my $self = $class->new(%{$data}, parent => $p->{parent} );
  return $self;
};


sub load_params {
  my $self = shift;

  $self->params( [] );

  my $sth = $self->load_params_sth;
  $sth->execute(
    $self->parent->object_id,
    $self->action,
  );
  $self->params( $sth->fetchall_arrayref({}) );
  $sth->finish;

  return $self->params;
};



__PACKAGE__->meta->make_immutable;

1;
