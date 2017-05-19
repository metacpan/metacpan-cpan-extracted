package CloudDeploy::DeploymentCollection {
  use Moose;
  use CloudDeploy::Config;
  use CCfnX::Deployment;

  has mongo => (is => 'rw', default => sub { CloudDeploy::Config->new->deploy_mongo }, lazy => 1);
  has mongolog => (is => 'rw', default => sub { CloudDeploy::Config->new->deploylog_mongo }, lazy => 1);
  has account => (is => 'ro', isa => 'Str', required => 1);

  sub customer_deployments {
    my ($self) = @_;
    my $deployments = $self->mongo->query({
       account => $self->account
    });

    my @list = ();

    while (my $deployment = $deployments->next) {
      push @list, $deployment->{ name };
    }

    return @list;
  }

  sub last_log_deployments {
    my ($self, $limit) = @_;

    my $status = { '$nin' => [ 'building', 'updating' ] };

    my $deployments = $self->mongolog->query({
       account => $self->account, status => $status 
    })->sort([ timestamp => -1])->limit($limit);

    my @list = ();

    while (my $deployment = $deployments->next) {
      push @list, [ $deployment->{ timestamp }, $deployment->{ status }, $deployment->{ name } ];
    }

    return @list;
  }

  sub search_log_deployments {
    my ($self, $criteria, $limit) = @_;

    unless (grep { /status/ } keys %{ $criteria }) {
      $criteria->{'status'} = { '$nin' => [ 'building', 'updating' ] };
    }

    unless (grep { /account/ } keys %{ $criteria }) {
      $criteria->{'account'} = $self->account;
    }

    my $deployments = $self->mongolog->query($criteria)->sort([ timestamp => -1])->limit($limit);

    my @list = ();

    while (my $deployment = $deployments->next) {
      push @list, [ $deployment->{ timestamp }, $deployment->{ status }, $deployment->{ name } ];
    }

    return @list;
  }

  sub deployment_exists {
    my ($self, $name) = @_;

    my $deployment = $self->mongo->find_one({
        account => $self->account,
        name => $name,
    });

    return (defined $deployment);
  }

  use CCfn;
  sub get_deployment {
    my ($self, $name) = @_;
    my $deploy = CCfnX::Deployment->new_with_roles(
       { mongo => $self->mongo, account => $self->account, name => $name },
       'CCfnX::PersistentDeployment');

    $deploy->get_from_mongo;
    return $deploy;
  }

  sub get_old_deployment {
    my ($self, $name, $timestamp) = @_;

    my $status = { '$nin' => [ 'building', 'updating' ] };

    my $deployment = $self->mongolog->find_one({
        account => $self->account,
        status => $status,
        name => $name,
        timestamp => $timestamp
    });

    my $deploy;

    if (defined $deployment) {
      my $log_id = $deployment->{_id}->to_string;

      $deploy = CCfnX::Deployment->new_with_roles(
         { mongolog => $self->mongolog, account => $self->account, name => $name, log_id => $log_id },
         'CCfnX::PersistentDeployment');

      $deploy->get_from_mongolog;
    }

    return $deploy;
  }
}

1;
