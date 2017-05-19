package CCfnX::InstanceRoot {
  use Archive::Tar;
  use Moose;
  use CCfnX::Shortcuts;

  has dir => (is => 'rw', isa => 'Str', required => 1);
  has attachment => (is => 'rw', required => 1);
  has params => (is => 'rw', required => 1);
  has version => (is => 'rw', isa => 'Str', lazy => 1, default => sub {
    $ENV{FORCE_WORKINGDIR_VERSION}?$ENV{FORCE_WORKINGDIR_VERSION}:$_[0]->_working_dir_version
  });
  has tar_name => (is => 'ro', isa => 'Str', lazy => 1, default => sub { $_[0]->dir . "-" . $_[0]->version . ".tar.gz" });
  has s3_tar_name => (
    is => 'ro', 
    isa => 'Str', 
    lazy => 1, 
    default => sub { 
      $_[0]->stripped_dir . "-" . $_[0]->version . ".tar.gz" 
    }
  );
  has upload_prefix => (is => 'rw', isa => 'Str', default => "capside");

  sub stripped_dir {
    my $self = shift;
    my $dir = $self->dir;
    # greedy substitution munges up to the last / in the dir
    $dir =~ s/.*\///;
    return $dir;
  }

  sub _have_uploaded_tar {
    my ($self) = @_;

    use AWS::CLIWrapper;

    my $att = $self->params->meta->get_attribute($self->attachment);
    my $att_name = $self->attachment;
    my $region = $att->get_info($self->params->$att_name, 'appbucket/region');
    my $bucket_name = $att->get_info($self->params->$att_name, 'appbucket/name');

    my $cli = AWS::CLIWrapper->new( region => $region );
    my $res = $cli->s3api('head-object', { bucket => $bucket_name, key => $self->upload_prefix . '/' . $self->s3_tar_name });

    return $res;
  }

  sub _working_dir_version {
    my ($self) = @_;
    my $command = 'find ' . $self->dir . ' ! -path "*.svn*" -type f -exec md5sum {} \; | sort | md5sum | cut -d" " -f1';
    my $out = `$command`;
    chomp $out;
    die "CANT CALCULATE working dir VERSION: please set FORCE_WORKINGDIR_VERSION" if (not $out);
    return $out;
  }

  sub build {
    my $self = shift;

    return if ($self->_have_uploaded_tar);

    print "BUILDING TAR " . $self->tar_name . " from " . $self->dir . "\n";

    my $command = "fakeroot tar czf " . $self->tar_name . " --exclude=README --exclude-vcs -C " . $self->dir . " . ";
    print `$command`;
  }

  sub upload {
    my ($self) = @_;

    return if ($self->_have_uploaded_tar);

    print "UPLOAD " . $self->tar_name . " TO S3\n";
    use AWS::CLIWrapper;

    my $att = $self->params->meta->get_attribute($self->attachment);
    my $att_name = $self->attachment;
    my $region = $att->get_info($self->params->$att_name, 'appbucket/region');
    my $bucket_name = $att->get_info($self->params->$att_name, 'appbucket/name');

    my $cli = AWS::CLIWrapper->new( region => $region );
    $cli->s3('cp', [ $self->tar_name, "s3://" . $bucket_name . '/' . $self->upload_prefix . '/' . $self->s3_tar_name ], {});
    unlink $self->tar_name;
  }

  sub install {
    my $self = shift;

    die "Can't find the dir for the root FS" if (not -d $self->dir);

	$self->build;
	$self->upload;
    return 'aws s3 cp s3://', Parameter('AppBucket'), '/' . $self->upload_prefix . '/' . $self->s3_tar_name . ' ' . $self->s3_tar_name . ' --region ', Parameter('BucketRegion'), "\n",
           'tar -xzf ' . $self->s3_tar_name  .  ' --no-overwrite-dir --directory=/', "\n",
           'rm -f ' . $self->s3_tar_name;
  }
}

1;
