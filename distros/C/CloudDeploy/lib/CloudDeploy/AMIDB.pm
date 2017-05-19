package CloudDeploy::AMI {
  use Moose;
  use Data::Dumper;
  has _required_props => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { [ 'Name', 'ImageId' ] },
    traits => [ 'Array' ],
    handles => {
      _number_of_required_props => 'count',
    }
  );

  has props => (
    is => 'ro', 
    isa => 'HashRef[Any]',
    traits => [ 'Hash' ],
    handles => {
      prop => 'get',
    }
  );
 
  sub mongo_id { shift->prop('_id') }

  #fancy way to build props ;)
  around BUILDARGS => sub {
    my ($orig,$class, $hash_ref) = @_;
   
    return $class->$orig(props => $hash_ref);
  };
  
  #props assuring that props have the _required_props.
  sub BUILD {
    my $self = shift;
    my @required = grep {$self->props->{"$_"}}  @{$self->_required_props};
    die "Please provide the required attributes @required\n" if (@required < @{$self->_required_props});
  }
}

package CloudDeploy::AMIDB {
  use Moose;
  use Carp;
  use DateTime;
  use JSON;
  use CloudDeploy::Config;
  use Data::Dumper;
  use Carp;

  has account => (is => 'ro', isa => 'Str', default => sub { CloudDeploy::Config->new->account; });

  has mongo => (is => 'rw', default => sub { CloudDeploy::Config->new->ami_mongo });
#  has mongolog => (is => 'rw', default => sub { CloudDeploy::Config->new->amilog_mongo });

  has log_id => (is => 'rw', isa => 'Str|Undef');
  has mongo_id => (is => 'rw', isa => 'Str|Undef');
  has timestamp => (is => 'rw', isa => 'Str', default => sub { DateTime->now( time_zone => 'UTC' )->iso8601 });
  
  #Todo: Need to review, the $self->stack_info param.
#  sub copy_to_log {
#    my $self = shift;
#    my $id = $self->mongolog->insert($self->stack_info, { safe => 1 });
#    $self->log_id($id->to_string);
#  }

  sub add {
    my ($self, %args) = @_;
    my $ami = CloudDeploy::AMI->new({%args});
    my $id = $self->mongo->insert($ami->props, {safe => 1});
    return $id;
  }

  sub replace {
    my ($self, %args) = @_;
    my $ami = CloudDeploy::AMI->new({%args});
    $self->mongo->replace_one(
      { ImageId => $ami->prop('ImageId') },
      $ami->props,
      { upsert => 1 }
    );
  }

  sub search {
    my ($self, %criterion) = @_;

    my @results = $self->mongo->query({%criterion})->all;
    return map { CloudDeploy::AMI->new($_) } @results;
  }

  sub find {
    my ($self, %criterion) = @_;
    my @result = $self->search(%criterion);
    die "Can't find a UNIQUE result for that criterion" if (@result > 1);
    die "Can't find a ANY result for that criterion" if (@result == 0);
    
    return $result[0];
  }

  sub delete {
    my ($self, $find_criterion) = @_;
    my $doc = $self->find(%$find_criterion);
    my $ret = $self->mongo->remove({ _id => $doc->mongo_id }, { safe => 1 });
  }

  sub _update{
    #update unique document, if it don´t find a unique document, it dies.
    my ($self, $find_criterion,$update_hash) = @_;
    my $doc = $self->find(%$find_criterion);
    $self->mongo->update({_id => $doc->{'_id'}},{'$set' => $update_hash});
  }

  sub unset_tag_from {
    my ($self, $tag, %criterion) = @_;

    my @log = ();
    my @tagged = $self->search(%criterion);

    # There should only be one tagged instance, but if a tagging fails, it
    # may leave the old instance still tagged
    foreach my $row (@tagged) {
      $self->mongo->update(
        { ImageId => $row->prop('ImageId') },
        { '$pull' => { 'Tags' => $tag } }
      );
      push @log, $row->prop('ImageId');
    }
    return \@log;
  }

  sub set_tag_to {
    my ($self, $tag, %criterion) = @_;

    my @log = ();
    my @tagged = $self->search(%criterion);

    foreach my $row (@tagged) {
      $self->mongo->update(
        { ImageId => $row->prop('ImageId') },
        { '$addToSet' => { 'Tags' => $tag } }
      );
      push @log, $row->prop('ImageId');
    }
    return \@log;
  }
}
1;
