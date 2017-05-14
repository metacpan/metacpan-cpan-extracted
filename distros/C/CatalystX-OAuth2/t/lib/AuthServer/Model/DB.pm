package AuthServer::Model::DB;
use Moose;

BEGIN { extends 'Catalyst::Model::DBIC::Schema' }

has user_endpoint =>
  ( isa => 'Str', is => 'ro', default => sub {'http://localhost/auth'} );

__PACKAGE__->config(
  schema_class => 'CatalystX::OAuth2::Schema',
  connect_info => [ 'dbi:SQLite:dbname=:memory:', '', '' ]
);

around COMPONENT => sub {
  my $orig  = shift;
  my $class = shift;
  my $self  = $class->$orig(@_);
  $self->schema->deploy;
  $self->schema->resultset('Client')
    ->create(
    { endpoint => $self->user_endpoint, client_secret => 'foosecret' } );
  return $self;
};

1;
