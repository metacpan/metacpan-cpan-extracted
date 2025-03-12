package DBIx::Migration::Pg;

our $VERSION = $DBIx::Migration::VERSION;

use Moo;
use MooX::StrictConstructor;

use Log::Any qw( $Logger );

use namespace::clean -except => [ qw( new ) ];

extends 'DBIx::Migration';

has managed_schema  => ( is => 'ro', default => 'public' );
has tracking_schema => ( is => 'ro', default => 'public' );

sub adjust_migrate {
  my $self = shift;

  my $tracking_table = $self->quoted_tracking_table;
    $Logger->debugf( "Lock tracking table '%s'", $tracking_table );
  $self->{ _dbh }->do( <<"EOF" );
LOCK TABLE $tracking_table IN EXCLUSIVE MODE;
EOF

  my $managed_schema = $self->managed_schema;
  $Logger->debugf( "Set PostgreSQL specific '%s' attribute to '%s'", 'search_path', $managed_schema );
  $self->{ _dbh }->do( <<"EOF" );
SET search_path TO $managed_schema;
EOF

  return;
}

sub quoted_tracking_table {
  my $self = shift;

  return $self->dbh->quote_identifier( undef, $self->tracking_schema, $self->tracking_table );
}

1;
