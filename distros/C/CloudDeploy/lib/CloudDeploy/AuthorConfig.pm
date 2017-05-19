package CloudDeploy::AuthorConfig {
  use Moose;
  extends 'CloudDeploy::Config';

  has author_db => (is => 'ro', lazy => 1, default => sub { $ENV{DEPLOY_DB} or 'clouddeploy' });
  has author_collection => (is => 'ro', lazy => 1, default => sub { $ENV{DEPLOY_COLLECTION} or 'definitions' });

  has author_mongo => (is => 'ro', lazy => 1, default => sub {
    my $self   = shift;
    return $self->mongo_client->get_database($self->author_db)->get_collection($self->author_collection);
  });

  sub setup_author_db {
    
  }
}

1;
