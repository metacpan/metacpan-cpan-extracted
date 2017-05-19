package Imager::CommandLine::DeleteAMI {
  use MooseX::App;
  use CloudDeploy::AMIDB;
  use ARGV::Struct;
  use Paws;
  use v5.10;

  has find_args => (
    is => 'ro',
    isa => 'HashRef[Str]',
    lazy => 1,
    default => sub {
      my $self = shift;
      die "Must specify a criterion to find AMIs" if (scalar(@{ $self->extra_argv }) == 0);
      return ARGV::Struct->new(argv => [ '{', @{ $self->extra_argv }, '}' ])->parse;
    }
  );

  option dryrun => (
    is => 'ro',
    isa => 'Bool',
    default => sub { 0 },
    documentation => 'Do a dry run (don\'t actually delete anything',
  );

  option ami => (
    is => 'ro',
    isa => 'Str',
    documentation => 'This option ignores finding images in the AMI Database. It will just deregister the specified AMI id',
  );

  option region => (
    is => 'ro',
    isa => 'Str|Undef',
    documentation => 'This option is needed if you specify --ami AND the image is not registered in the AMIDB (where the region can be auto-detected)',
  );

  sub run {
    my ($self) = @_;

    if ($self->ami) {
      $self->delete_ami($self->ami);
    } else {
      my $search = CloudDeploy::AMIDB->new;
      my %criterion = %{ $self->find_args };

      if (not defined $criterion{Account}){
        $criterion{Account} = CloudDeploy::Config->new->account;
      }
      my @res = $search->search(%criterion);
	  
	  die "No Image found in the DB" if (@res == 0);
      die "You were going to delete more than one AMI. Aborting" if (@res > 1);
      $self->delete_ami($res[0]->prop('ImageId'));
    }
  }

  sub delete_ami {
    my ($self, $image_id) = @_;
    say "Deleting " . $image_id;

    my $region;
    my $search = CloudDeploy::AMIDB->new;
    my @res = $search->search(ImageId => $image_id);

    if (@res == 0) {
      say "Didn't find the AMI in the AMIDB. Not unregistering";
      # Pick up the region from the command line
      die "Must specify --region where the AMI is because we can't auto-detect it" if (not defined $self->region);
      $region = $self->region;
    } elsif (@res > 1) {
      die "Something went Wildly wrong! I found more than one $image_id in the AMIDB, and I'm aborting";
    } else {
      print "Unregistering from AMIDB\n";
      $region = $res[0]->prop('Region');
      $search->delete({ ImageId => $image_id }) if (not $self->dryrun);
    }

    my $ec2 = Paws->service('EC2', region => $region);
    my $images = $ec2->DescribeImages(Owners => [ 'self' ] , ImageIds => [ $image_id ]);
    die "Found an abnormal (" . scalar(@{ $images->Images }) . ") amount of images with id $image_id" if (@{ $images->Images } != 1);

    my @snap_ids = map { $_->Ebs->SnapshotId } grep { defined $_->Ebs } @{ $images->Images->[0]->BlockDeviceMappings };
    say "Deregistering $image_id";

    if ($self->dryrun){
      map { say "Deleting snapshot $_" } @snap_ids;
      say "WARNING!: Running in dryrun mode. I haven't done anything.";
    } else {
      $ec2->DeregisterImage(ImageId => $image_id);
      sleep(1);
      foreach my $snap_id (@snap_ids) {
        say "Deleting snapshot $snap_id";
        $ec2->DeleteSnapshot(SnapshotId => $snap_id);
      }
    }
  } 

}

1;

