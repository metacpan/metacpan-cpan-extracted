use Moose::Util::TypeConstraints;

enum 'CCfnX::PersistentDeployment::State', [
  'building', # state for a deployment that is being built at the moment
  'active',   # state for deployments are stable (not suffering changes)
  'migrated', # state for deployments that have been updated from one schema version to the next
  'deleted',  # deployments that were unprovisioned
  'updated',  # deployments that were once active, but superceded by a new active deployment
  'updating',
];

package CCfnX::PersistentDeployment {
  use Moose::Role;
  use Carp;
  use DateTime;
  use JSON;
  use CloudDeploy::Config;

  requires 'params';
  has mongo => (is => 'rw', default => sub { CloudDeploy::Config->new->deploy_mongo });
  has mongolog => (is => 'rw', default => sub { CloudDeploy::Config->new->deploylog_mongo });

  has log_id => (is => 'rw', isa => 'Str|Undef');
  has mongo_id => (is => 'rw', isa => 'Str|Undef');
  has status => (is => 'rw', isa => 'CCfnX::PersistentDeployment::State');
  has timestamp => (is => 'rw', isa => 'Str', default => sub { DateTime->now( time_zone => 'UTC' )->iso8601 });
  has comments => (is => 'rw', isa => 'Str|Undef');

  before undeploy => sub {
    my $self = shift;

    # save current comments before loading from database
    my $comments = $self->comments;

    # save output ImageId in case AMI was just created
    my $imageid;
    $imageid = $self->outputs->{ImageId} if (defined $self->outputs && $self->outputs->{ImageId});

    $self->get_from_mongo if (not defined $self->mongo_id);

    # restore lost output / params after load from database
    $self->outputs->{ImageId} = $imageid if (defined $imageid);
    $self->params->{onlysnapshot} = $self->origin->params->onlysnapshot if (defined $self->origin);

    $self->comments($comments);
    $self->status('building');
    $self->change_status_to('building');
    $self->copy_to_log;
  };

  after undeploy => sub {
    my $self = shift;
    $self->mongo->remove({ _id => MongoDB::OID->new( value => $self->mongo_id ) }, { safe => 1 });
    $self->mongo_id(undef);
    $self->status('deleted');
    $self->copy_to_log;
  };

  before deploy => sub {
    my $self = shift;
    my $res = $self->mongo->find_one({ name => $self->name, account => $self->account });

    if (defined $res) {
      $self->mongo_id($res->{_id}->to_string);
    }
    else {
      if ($self->origin->params->meta->has_attribute('onlysnapshot') and $self->origin->params->onlysnapshot) {
        die "Error: param 'onlysnapshot' found but no matching current deployment";
      }
      my $id = $self->mongo->insert($self->stack_info, { safe => 1 });
      $self->mongo_id($id->to_string);
    }

    $self->status('building');
    $self->change_status_to('building');
    $self->copy_to_log;
  };

  after deploy => sub {
    my $self = shift;

    # when we're doing AMI's, an undeploy has been triggered before getting here, and
    # in that case, persist can't persist anything...
    if ($self->status ne 'deleted'){
      $self->status('active');
      $self->copy_to_log;
      $self->persist;
    }
  };

  before redeploy => sub {
    my $self = shift;

    # save current comments before loading from database
    my $comments = $self->comments;

    # save current type to allow "class" option to be persisted
    my $type = $self->type;

    $self->get_from_mongo if (not defined $self->mongo_id);
    $self->status('updating');
    $self->type($type);
    $self->comments($comments);
    $self->persist;
    $self->copy_to_log;

    $self->change_status_to('building');
    # type can be changed because we're deploying a new class, so we clear type
    # so it will be recalculated
    $self->clear_type;
  };

  after redeploy => sub {
    my $self = shift;
    $self->params($self->get_params_from_origin);
    $self->status('active');
    $self->persist;
    $self->copy_to_log;
  };

  sub copy_to_log {
    my $self = shift;
    my $id = $self->mongolog->insert($self->stack_info, { safe => 1 });
    $self->log_id($id->to_string);
  }

  sub change_status_to {
    my ($self, $status) = @_;
    confess "Can't update status if not mongo_id" if (not defined $self->mongo_id);

    my $res = $self->mongo->update({ _id => MongoDB::OID->new(value => $self->mongo_id ) },
                                   { '$set' => { status => $status } },
                                   { safe => 1 });
    die "Change_status updated a strange number of documents in the DB: $res->{n}" if ($res->{n} != 1);
  }

  sub persist {
    my ($self) = @_;

    confess "Can't persist if not mongo_id" if (not defined $self->mongo_id);

    $self->timestamp(DateTime->now( time_zone => 'UTC' )->iso8601);

    my $res = $self->mongo->update(
      { _id => MongoDB::OID->new(value => $self->mongo_id) },
      $self->stack_info,
      { safe => 1 }
    );
    die "Persist updated a strange number of documents in the DB: $res->{n}" if ($res->{n} != 1);
  }

  sub stack_info {
    my $self = shift;
    return { outputs => $self->outputs,
             params => $self->params,
             region => $self->region,
             account => $self->account,
             name => $self->name,
             status => $self->status,
             timestamp => $self->timestamp,
             type   => $self->type,
             comments => $self->comments,
    };
  }

  sub get_from_mongo {
    my ($self) = @_;

    my $query = $self->mongo->query(
      { name => $self->name, account => $self->account },
      { limit => 1 },
    );
    my $res = $query->next;

    die "Didn't find deployment " . $self->name . " in account " . $self->account . "\n" if (not defined $res);

    $self->_result_to_object($res);

    return $self;
  }

  sub get_from_mongolog {
    my ($self) = @_;

    my $res = $self->mongolog->find_one({ _id => MongoDB::OID->new(value => $self->log_id) });

    die "Didn't find deployment " . $self->name . " in log for account " . $self->account . "\n" if (not defined $res);

    $self->_result_to_object($res);

    return $self;
  }

  sub _result_to_object {
    my ($self, $obj) = @_;

    for ('params', 'account', 'region', 'name', 'status', 'timestamp', 'type') {
      $self->$_($obj->{$_}) if ($self->can($_));
    }

    $self->comments($obj->{comments}) if (defined $obj->{comments});
    $self->outputs($obj->{outputs}) if (defined $obj->{outputs});
    $self->mongo_id($obj->{_id}->to_string);
  }
}

1;
