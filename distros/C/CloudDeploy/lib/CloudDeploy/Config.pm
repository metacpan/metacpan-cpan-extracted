package CloudDeploy::Config {
  use Moose;
  use MongoDB;

  has account => (is => 'ro', isa => 'Str', required => 1, default => sub { $ENV{CPSD_AWS_ACCOUNT} });

  has deploy_server => (is => 'ro', lazy => 1, default => sub { $ENV{DEPLOY_SERVER} or 'mongodb://localhost:27017' });
  has mongo_client => (is => 'ro', lazy => 1, default => sub {
    MongoDB::MongoClient->new(host => shift->deploy_server);
  });

  has deploy_mongo => (is => 'ro', lazy => 1, default => sub {
    my $self   = shift;
    return $self->mongo_client->get_database($self->deploy_db)->get_collection($self->deploy_collection);
  });
  has deploylog_mongo => (is => 'ro', lazy => 1, default => sub {
    my $self   = shift;
    return $self->mongo_client->get_database($self->deploy_db)->get_collection($self->deploylog_collection);;
  });

  has deploy_db => (is => 'ro', lazy => 1, default => sub { $ENV{DEPLOY_DB} or 'clouddeploy' });
  has deploy_collection => (is => 'ro', lazy => 1, default => sub { $ENV{DEPLOY_COLLECTION} or 'deployments' });
  has deploylog_collection => (is => 'ro', lazy => 1, default => sub { shift->deploy_collection . "_log" });
  has ami_db => (is => 'ro', lazy => 1, default => sub { $_[0]->deploy_db });
  has ami_collection => (is => 'ro', lazy => 1, default => sub { $ENV{AMI_COLLECTION} or 'amis' });
  has ami_mongo => (is => 'ro', lazy => 1, default => sub {
    my $self   = shift;
    return $self->mongo_client->get_database($self->ami_db)->get_collection($self->ami_collection);
  });
  has amilog_mongo => (is => 'ro', lazy => 1, default => sub {
    my $self   = shift;
    return $self->mongo_client->get_database($self->ami_db)->get_collection($self->ami_collection);
  });
}
1;
