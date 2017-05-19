package CCfnX::MakeAMI {
  use Moose::Role;
  use CloudDeploy::AMIDB;

  has amidb => (is => 'ro', lazy => 1, default => sub {
    CloudDeploy::AMIDB->new
  });

  before deploy => sub {
    my ($self) = @_;

    return if (not defined $self->origin->params->amitag);

    my @list = $self->amidb->search(
      Name => $self->origin->params->name,
      Region => $self->origin->params->region,
      Tags => $self->origin->params->amitag,
    );
    if (@list > 0) {
      die sprintf "Aborting AMI creation: you already have an image called %s in the region %s with amitag %s", $self->origin->params->name, $self->origin->params->region, $self->origin->params->amitag;
    }
  };

  around deploy => sub {
    my ($orig, $self) = @_;
    if ($self->origin->params->onlysnapshot) {
      print "Loading deployment " . $self->name . "\n";
      $self->get_from_mongo;
      die "Error: previous deployment with same name was not run with --devel option" unless ($self->params->{devel});
    } else {
      $self->$orig();
    }

    if (not $self->origin->params->devel or $self->origin->params->onlysnapshot) {
      use Paws;
      my $ec2 = Paws->service('EC2',
        region => $self->region
      );

      # This won't work until the persistence is functional
      my $instance_id = $self->outputs->{'InstanceID'};

      if ($self->origin->params->os_family eq 'linux') {
        $ec2->StopInstances(InstanceIds => [ $instance_id ]);
      }

      sleep 2;
      my $instance_state = $ec2->DescribeInstances(InstanceIds => [ $instance_id ]);
      while ($instance_state->Reservations->[0]->Instances->[0]->State->Name ne 'stopped') {
        sleep 5;
        $instance_state = $ec2->DescribeInstances(InstanceIds => [ $instance_id ]);
      }

      my $ami = $ec2->CreateImage(
                          InstanceId  => $instance_id,
                          Name        => sprintf("%s %d", $self->name, time()),
                          Description => sprintf("%s %s", $self->name, scalar(localtime)),
      ) || die "An error occurred when creating the AMI of $instance_id\n";
      my $ami_id = $ami->ImageId;

      print "CREATING AMI: $ami_id\n";

      sleep 5;

      my $image = $ec2->DescribeImages(ImageIds => [ $ami_id ])->Images->[0];
      my $image_state = $image->State;

      print "WAITING FOR SNAPSHOT TO FINISH: $ami_id\n";

      while ($image_state eq 'pending') {
        sleep 10;
        $image = $ec2->DescribeImages(ImageIds => [ $ami_id ])->Images->[0];
        $image_state = $image->State;
      }

      print "CREATED AMI: $ami_id\n";

      $self->outputs->{'ImageId'} = $ami_id;

      if ($image_state eq 'available') {
        $self->register_image($image);
        $self->undeploy;
      } else {
        die "Failed creating AMI:" . Dumper($image_state);
      }
    }
  };

  sub register_image {
    my ($self, $image) = @_;
    
    my $type = $image->VirtualizationType;
    $type = 'pv' if ($type eq 'paravirtual');

    $self->amidb->add(
      Account => $self->account,
      Name    => $self->name,
      Arch    => $image->Architecture,
      Root    => $image->RootDeviceType,
      Region  => $self->params->{ region },
      ImageId => $image->ImageId,
      Type    => $type,
      Class   => $self->type,
      Date    => $image->CreationDate,
      OriginImageId => $self->params->{ ami },
      (defined $self->origin->params->amitag)?(Tags => [ $self->origin->params->amitag ]):(),
    );
  }

}

1;
