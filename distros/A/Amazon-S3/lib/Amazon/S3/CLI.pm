package Amazon::S3::CLI;
# modulino proving CLI access to S3 operations

use strict;
use warnings;

use Amazon::S3;
use CLI::Simple::Constants qw(:booleans :chars);
use CLI::Simple::Utils qw(choose);
use Carp;
use Cwd qw(abs_path);
use Data::Dumper;
use English qw(-no_match_vars);
use File::Basename qw(basename);
use List::Util qw(none);
use locale;  # for proper sorting
use JSON::PP;

__PACKAGE__->use_log4perl( level => 'info' );

use parent qw(CLI::Simple);

caller or exit __PACKAGE__->main;

########################################################################
sub get_bucket {
########################################################################
  my ( $self, $bucket_name ) = @_;

  $bucket_name //= $self->get_bucket_name;

  my $bucket = $self->get_s3->bucket(
    { bucket        => $bucket_name,
      verify_region => $TRUE,
    }
  );

  return $bucket;
}

########################################################################
sub cmd_empty_bucket {
########################################################################
  my ($self) = @_;

  my ($bucket_name) = $self->get_args;
  $bucket_name //= $self->get_bucket_name;

  die "ERROR: usage: empty-bucket bucket-name\n"
    if !$bucket_name;

  if ( !$self->get_force ) {
    return $FAILURE
      if !$self->confirm('This command will remove all objects and versions. Proceed');
  }

  my $rsp = $self->get_s3->empty_bucket($bucket_name);

  if ( $self->get_format eq 'json' ) {
    print {*STDOUT} JSON::PP->new->pretty->encode($rsp);
    return $SUCCESS;
  }
  elsif ( $self->get_format eq 'table' && $self->get_ascii_table ) {
    my $t = Text::ASCIITable->new( { headingText => sprintf "Deletion Report\nBucket: %s", $bucket_name } );

    $t->setCols( 'Versions', 'Delete Markers', 'Multipart Uploads Aborted', 'Total' );

    $t->addRow( @{$rsp}{qw(versions_deleted delete_markers_deleted multipart_uploads_aborted total)} );

    print {*STDOUT} $t;
    return $SUCCESS;
  }

  foreach (qw(versions_deleted delete_markers_deleted multipart_uploads_aborted total)) {
    print {*STDOUT} sprintf "%30s %s\n", $rsp->{$_};
  }

  return $SUCCESS;
}

########################################################################
sub cmd_add_key {
########################################################################
  my ($self) = @_;

  my (@args) = $self->get_args;

  my ( $bucket_name, $filename, $object_name ) = choose {
    # bucket-name filename object-name
    return @args
      if @args == 3;

    # --bucket-name bucket-name filename
    return ( @args, $args[1] )
      if @args == 2 && !$self->get_bucket_name;

    # --bucket-name bucket-name filename object-name
    return ( $self->get_bucket_name, @args )
      if $self->get_bucket_name && @args == 2;

    # --bucket-name bucket-name --key key-name filename
    return ( $self->get_bucket_name, $args[0], $self->get_key )
      if $self->get_bucket_name && $self->get_key && @args == 1;

    return ( $self->get_bucket_name, $args[0], $args[0] )
      if $self->get_bucket_name && @args == 1;

    die "ERROR: usage add-key --bucket-name bucket-name filename object-name\n";
  };

  die sprintf "ERROR: file %s does not exist\n", $filename
    if !-e $filename;

  if ( $object_name =~ m{\A[/.]}xsm ) {
    $object_name =~ s{\A[/.]+(.*)$}{$1}xsm;
  }

  $self->get_logger->debug(
    sub {
      return Dumper(
        [ bucket_name => $bucket_name,
          filename    => $filename,
          object_name => $object_name,
        ]
      );
    }
  );

  my $content_type = $self->get_content_type // guess_content_type($filename);

  my $bucket = $self->get_bucket($bucket_name);

  $self->get_logger->debug( sub { return Dumper( [ $bucket->head_key($object_name) ] ); } );

  $self->get_logger->debug( sub { return Dumper( [ $bucket, $self->get_s3->last_response ] ); } );

  $bucket->add_key_filename( $object_name, $filename, { content_type => $content_type } );

  return $SUCCESS;
}

########################################################################
sub cmd_list_directory_buckets {
########################################################################
  my ($self) = @_;

  my $buckets = $self->get_s3->list_directory_buckets();

  return $self->_list_buckets($buckets);
}

########################################################################
sub cmd_create_bucket {
########################################################################
  my ($self) = @_;

  my ($bucket_name) = $self->get_args;
  $bucket_name //= $self->get_bucket_name;

  if ( $self->get_availability_zone ) {
    $self->get_s3->use_express_one_zone;
  }

  my $response = $self->get_s3->add_bucket(
    { bucket            => $bucket_name,
      availability_zone => $self->get_availability_zone,
      region            => $self->get_region,
    }
  );

  return $SUCCESS;
}

########################################################################
sub cmd_copy_key {
########################################################################
  my ($self) = @_;

  my ( $bucket_name, $key, $new_key ) = $self->get_args;

  if ( $self->get_bucket_name ) {
    if ( $self->get_key ) {
      $key     = $self->get_key;
      $new_key = $bucket_name;
    }
    else {
      $new_key     = $key;
      $key         = $bucket_name;
      $bucket_name = $self->get_bucket_name;
    }
  }

  die "ERROR: usage: copy-key bucket-name key new-key\n"
    if !$key || !$bucket_name || !$new_key;

  my $bucket = $self->get_bucket($bucket_name);

  $bucket->copy_object(
    source => $key,
    key    => $new_key,
  );

  return $SUCCESS;
}

########################################################################
sub cmd_get_key {
########################################################################
  my ($self) = @_;

  my ( $bucket_name, $key ) = $self->get_args;

  if ( !$key && $self->get_bucket_name ) {
    if ( $self->get_key ) {
      $key = $self->get_key;
    }
    else {
      $key         = $bucket_name;
      $bucket_name = $self->get_bucket_name;
    }
  }

  die "ERROR: usage: get-key bucket-name key\n"
    if !$key || !$bucket_name;

  my $bucket = $self->get_s3->bucket($bucket_name);

  my $modified_since = $self->get_modified_since;
  my $range          = $self->get_range;
  my $version_id     = $self->get_version_id;

  my %headers
    = ( $range ? ( Range => 'bytes=' . $range ) : (), $modified_since ? ( 'If-Modified-Since' => $modified_since ) : (), );

  my %uri_params = ( $version_id ? ( versionId => $version_id ) : (), );

  my $object = $bucket->get_key(
    { key        => $key,
      headers    => \%headers,
      uri_params => \%uri_params,
    }
  );

  if ( !$object ) {
    my $version_id = $self->get_version_id;

    die sprintf "ERROR: object %s%s not found\n", $key, $version_id ? " version $version_id" : $EMPTY;
  }

  my $ofh = choose {
    my $output = $self->get_output;

    return *STDOUT
      if $output && $output eq q{-};

    if ( !$output ) {
      if ( $self->get_format ne 'json' ) {
        $output = basename($key);
      }
      else {
        return *STDOUT;
      }
    }

    open my $fh, '>', $output
      or die "ERROR: could not open $output for writing\n$OS_ERROR";

    binmode $fh;

    return $fh;
  };

  my $content = choose {
    return JSON::PP->new->pretty->encode($object)
      if $self->get_format eq 'json';

    return $object->{value};
  };

  print {$ofh} $content;

  close $ofh;

  return $SUCCESS;
}

########################################################################
sub cmd_delete_key {
########################################################################
  my ($self) = @_;

  my ( $bucket_name, $key ) = $self->get_args;

  if ( !$key && $self->get_bucket_name ) {
    if ( $self->get_key ) {
      $key = $self->get_key;
    }
    else {
      $key         = $bucket_name;
      $bucket_name = $self->get_bucket_name;
    }
  }

  die "ERROR: usage: delete-key bucket-name key\n"
    if !$key || !$bucket_name;

  my $bucket = $self->get_bucket($bucket_name);

  $bucket->delete_key( $key, $self->get_version_id );

  return $SUCCESS;
}

########################################################################
sub get_bucket_v2 {
########################################################################
  my ( $self, $bucket_name ) = @_;

  $bucket_name //= $self->get_bucket_name;

  my $bucket = $self->get_s3->bucketv2(
    { bucket        => $bucket_name,
      verify_region => $TRUE,
    }
  );

  return $bucket;
}

########################################################################
sub cmd_get_bucket_policy {
########################################################################
  my ($self) = @_;

  my ($bucket_name) = $self->get_args;
  $bucket_name //= $self->get_bucket_name;

  die "ERROR: usage: get-bucket-policy bucket-name\n"
    if !$bucket_name;

  my $policy = $self->get_bucket_v2($bucket_name)->GetBucketPolicy();

  return $FAILURE
    if !$policy;

  print {*STDOUT} JSON::PP->new->pretty->canonical->encode($policy);

  return $SUCCESS;
}

########################################################################
sub cmd_get_bucket_policy_status {
########################################################################
  my ($self) = @_;

  my ($bucket_name) = $self->get_args;
  $bucket_name //= $self->get_bucket_name;

  die "ERROR: usage: get-bucket-policy-status bucket-name\n"
    if !$bucket_name;

  my $status = $self->get_bucket_v2($bucket_name)->GetBucketPolicyStatus();

  return $FAILURE
    if !$status;

  print {*STDOUT} JSON::PP->new->pretty->canonical->encode($status);

  return $SUCCESS;
}

########################################################################
sub cmd_get_bucket_acl {
########################################################################
  my ($self) = @_;

  my ($bucket_name) = $self->get_args;
  $bucket_name //= $self->get_bucket_name;

  die "ERROR: usage: get-bucket-acl bucket-name\n"
    if !$bucket_name;

  my $acl = $self->get_bucket_v2($bucket_name)->GetBucketAcl();

  return $FAILURE
    if !$acl;

  print {*STDOUT} JSON::PP->new->pretty->canonical->encode($acl);

  return $SUCCESS;
}

########################################################################
sub cmd_remove_bucket {
########################################################################
  my ($self) = @_;

  my ($bucket_name) = $self->get_args;
  $bucket_name //= $self->get_bucket_name;

  die "ERROR: usage: remove-bucket bucket-name\n"
    if !$bucket_name;

  $self->get_s3->delete_bucket( { bucket => $bucket_name } );

  return $SUCCESS;
}

########################################################################
sub cmd_list_object_versions {
########################################################################
  my ($self) = @_;

  my ( $bucket_name, $prefix ) = $self->get_args;
  $bucket_name //= $self->get_bucket_name;
  $prefix      //= $self->get_prefix;

  if ( defined $prefix ) {
    $prefix =~ s/^\///xsm;
  }

  my $response = $self->get_s3->list_object_versions( { bucket => $bucket_name, prefix => $prefix } );

  if ( $self->get_format eq 'json' ) {
    print {*STDOUT} JSON::PP->new->pretty->encode($response);
    return $SUCCESS;
  }
  elsif ( $self->get_ascii_table && $self->get_format eq 'table' ) {
    my $t = Text::ASCIITable->new( { headingText => sprintf "Bucket: %s", $bucket_name } );

    $t->setCols( 'Key', 'Size', 'Last Modified', 'Latest', 'Version ID' );

    foreach my $k ( @{ $response->{Version} } ) {
      $t->addRow( @{$k}{qw(Key Size LastModified IsLatest VersionId)} );
    }

    print {*STDOUT} $t;
    return $SUCCESS;
  }

  print {*STDOUT} "Key,Size,LastModified,IsLatest,VersionId\n";

  foreach my $k ( @{ $response->{Version} } ) {
    print {*STDOUT} sprintf qq{"%s","%s","%s","%s","%s"\n}, @{$k}{qw(Key Size LastModified IsLatest VersionId)};
  }

  return $SUCCESS;
}

########################################################################
sub cmd_list_bucket_keys {
########################################################################
  my ($self) = @_;

  my ( $bucket_name, $prefix ) = $self->get_args;
  $bucket_name //= $self->get_bucket_name;
  $prefix      //= $self->get_prefix;

  if ( defined $prefix ) {
    $prefix =~ s/^\///xsm;
  }

  die "ERROR: usage: list-bucket-keys bucket-name [prefix]\n"
    if !$bucket_name;

  my $response
    = eval { return $self->get_s3->list_bucket_all_v2( { bucket => $bucket_name, $prefix ? ( prefix => $prefix ) : () } ); };

  return $self->_list_keys( $bucket_name, $prefix, $response );
}

########################################################################
sub _list_keys {
########################################################################
  my ( $self, $bucket_name, $prefix, $response ) = @_;

  if ( !$response ) {
    return $SUCCESS
      if $self->get_format ne 'json';

    print {*STDOUT} "{}\n";
    return $SUCCESS;
  }

  if ( $self->get_format eq 'json' ) {
    my $result = { map { $_->{key} => $_ } @{ $response->{keys} // [] } };
    print JSON::PP->new->pretty->encode($result);
    return $SUCCESS;
  }

  my $data = [ reverse sort { $a->{key} cmp $b->{key} } @{ $response->{keys} } ];

  my $cols = [qw(key size last_modified etag)];

  my $heading = $response->{bucket};

  if ( $self->get_prefix ) {
    $heading = sprintf '%s/%s', $heading, $self->get_prefix;
  }

  if ( $self->get_ascii_table && $self->get_format eq 'table' ) {
    my $t = Text::ASCIITable->new( { headingText => sprintf "Bucket: %s\nPrefix: %s\n", $bucket_name, $prefix // q{/} } );

    $t->setCols( 'Key', 'Size', 'Last Modified', 'ETag' );

    foreach my $k ( @{$data} ) {
      $t->addRow( @{$k}{qw(key size last_modified etag)} );
    }

    print {*STDOUT} $t;

    return $SUCCESS;
  }

  print {*STDOUT} "Key,Size,LastModified,ETag\n";

  foreach my $k ( @{$data} ) {
    print {*STDOUT} sprintf qq{"%s","%s","%s","%s"\n}, @{$k}{qw(key size last_modified etag)};
  }

  return $SUCCESS;
}

########################################################################
sub cmd_list_buckets {
########################################################################
  my ($self) = @_;

  my $buckets = $self->get_s3->buckets();

  if ( !$buckets || !@{ $buckets->{buckets} // [] } ) {
    print {*STDOUT} "no buckets\n";

    return $SUCCESS;
  }

  return $self->_list_buckets($buckets);
}

########################################################################
sub _list_buckets {
########################################################################
  my ( $self, $buckets ) = @_;

  if ( $self->get_format eq 'json' ) {
    my $data = {
      owner_id => $buckets->{owner_id},
      buckets  =>
        { map { $_->bucket => { region => $_->region, creation_date => $_->creation_date, } } @{ $buckets->{buckets} } },
    };

    print {*STDOUT} JSON::PP->new->pretty->allow_blessed->convert_blessed->encode($data);

    return $SUCCESS;
  }

  my $data = [ sort { $a->bucket cmp $b->bucket } @{ $buckets->{buckets} } ];

  if ( $self->get_ascii_table && $self->get_format eq 'table' ) {
    my $t = Text::ASCIITable->new( { headingText => 'Bucket Listing', } );

    $t->setCols( qw(Bucket Region), 'Creation Date' );

    foreach my $b ( @{$data} ) {
      $t->addRow( $b->bucket, $b->region, $b->creation_date, );
    }

    print {*STDOUT} $t;

    return $SUCCESS;
  }

  print {*STDOUT} "Bucket,Region,CreationDate\n";

  foreach my $b ( @{$data} ) {
    print {*STDOUT} sprintf qq{"%s","%s","%s"\n}, $b->bucket, $b->region, $b->creation_date;
  }

  return $SUCCESS;
}

########################################################################
sub init {
########################################################################
  my ($self) = @_;

  my %endpoint = choose {
    return ( host => $self->get_host )
      if defined $self->get_host;

    return ( endpoint_url => $self->get_endpoint_url )
      if $self->get_endpoint_url;

    return ();
  };

  $self->set_ascii_table(
    eval {
      require Text::ASCIITable;
      1;
    }
  );

  die "ERROR: --format must be one of json, text or table\n"
    if none { $self->get_format eq $_ } qw(json text table);

  my %credentials;

  my $has_amazon_credentials = eval {
    require Amazon::Credentials;
    1;
  };

  if ($has_amazon_credentials) {
    $credentials{credentials} = Amazon::Credentials->new(
      { $self->get_profile
        ? ( profile => $self->get_profile )
        : (),
      }
    );
  }
  else {
    die "ERROR: --profile requires Amazon::Credentials\n"
      if $self->get_profile;

    $credentials{aws_access_key_id}     = $ENV{AWS_ACCESS_KEY_ID};
    $credentials{aws_secret_access_key} = $ENV{AWS_SECRET_ACCESS_KEY};
    $credentials{token}                 = $ENV{AWS_SESSION_TOKEN};
  }

  my $s3 = Amazon::S3->new(
    { %credentials,
      debug            => $ENV{DEBUG},
      raise_error      => $TRUE,
      region           => $self->get_region,
      logger           => $self->get_logger,
      dns_bucket_names => $self->get_dns_bucket_names // $FALSE,
      %endpoint,
      defined $self->get_secure ? ( secure => $self->get_secure ) : (),
    }
  );

  $self->set_s3($s3);

  return;
}

########################################################################
sub confirm {
########################################################################
  my ( $self, $prompt ) = @_;

  print "$prompt [y/N] ";

  my $answer = <STDIN>;
  return $FALSE
    if !defined $answer;

  chomp $answer;

  return $answer =~ /\Ay(?:es)?\z/i ? $TRUE : $FALSE;
}

########################################################################
sub guess_content_type {
########################################################################
  my ($filename) = @_;

  my $has_mmagic = eval { require File::MimeInfo::Magic; 1; };

  return 'application/octet-stream'
    if !$has_mmagic || !$filename || !-f $filename;

  my $content_type = eval { return File::MimeInfo::Magic::mimetype($filename); };

  return $content_type
    if !$EVAL_ERROR && $content_type;

  return 'application/octet-stream';
}

########################################################################
sub main {
########################################################################

  my %default_options = (
    output => $EMPTY,
    region => 'us-east-1',
    format => 'text',
  );

  my @option_specs = qw(
    availability-zone=s
    bucket-name|b=s
    content-type=s
    debug
    dns-bucket-names
    endpoint-url|u=s
    force|f
    format|F=s
    help|h
    host|H=s
    key|k=s
    modified-since|m=s
    output|o=s
    prefix=s
    profile|p=s
    range|R=s
    region|r=s
    secure|s
    version-id=s
  );

  my %commands = (
    'add-key'                  => \&cmd_add_key,
    'copy-key'                 => \&cmd_copy_key,
    'create-bucket'            => \&cmd_create_bucket,
    'delete-key'               => \&cmd_delete_key,
    'empty-bucket'             => \&cmd_empty_bucket,
    'get-key'                  => \&cmd_get_key,
    'get-bucket-policy'        => \&cmd_get_bucket_policy,
    'get-bucket-acl'           => \&cmd_get_bucket_acl,
    'get-bucket-policy-status' => \&cmd_get_bucket_policy_status,
    'list-bucket-keys'         => \&cmd_list_bucket_keys,
    'list-directory-buckets'   => \&cmd_list_directory_buckets,
    'list-keys'                => 'list-bucket-keys',
    'list-object-versions'     => \&cmd_list_object_versions,
    'remove-bucket'            => \&cmd_remove_bucket,
    'list-buckets'             => \&cmd_list_buckets,
  );

  return __PACKAGE__->new(
    commands        => \%commands,
    option_specs    => \@option_specs,
    default_options => \%default_options,
    abbreviations   => $TRUE,
    extra_options   => [qw(s3 secure ascii_table)],
  )->run;
}

1;

__END__

## no critic

=pod

=encoding utf8

=head1 NAME

Amazon::S3::CLI - command line interface for common S3 operations

=head1 SYNOPSIS

  # list buckets in tabular format
  amzn-s3-cli list-buckets --profile sandbox --format table

  # list keys in JSON format
  amzn-s3-cli list-keys test-bucket --format json

  # create a new bucket on LocalStack
  amzn-s3-cli create-bucket my-bucket --endpoint-url http://localhost:4566 --profile localstack

  # add a key using the filename as the object name
  amzn-s3-cli add-key --bucket-name my-bucket some-file

  # add a key with a different object name
  amzn-s3-cli add-key --bucket-name my-bucket some-file project-alpha/some-file

  # retrieve an object
  amzn-s3-cli get-key my-bucket project-alpha/some-file

  # delete an object
  amzn-s3-cli delete-key --bucket-name my-bucket some-file

  # inspect bucket configuration
  amzn-s3-cli get-bucket-policy --bucket-name my-bucket
  amzn-s3-cli get-bucket-policy-status --bucket-name my-bucket
  amzn-s3-cli get-bucket-acl --bucket-name my-bucket

=head1 USAGE

  usage: amzn-s3-cli [options] command [arguments]

Common commands:

  add-key                  Add an object
  copy-key                 Copy an object
  create-bucket            Create a bucket
  delete-key               Delete an object
  empty-bucket             Empty a bucket
  get-bucket-acl           Retrieve a bucket ACL
  get-bucket-policy        Retrieve a bucket policy
  get-bucket-policy-status Retrieve bucket policy status
  get-key                  Retrieve an object
  list-bucket-keys         List objects
  list-buckets             List buckets
  list-directory-buckets   List directory buckets
  list-object-versions     List object versions
  remove-bucket            Remove a bucket

Use:

  amzn-s3-cli --help

for command and option documentation.

=head1 DESCRIPTION

C<Amazon::S3::CLI> provides the C<amzn-s3-cli> command for performing
common Amazon S3 operations using L<Amazon::S3>.

It is intended as a convenient command-line companion to the library,
not as a replacement for the complete AWS CLI or C<aws s3api> command
surface.

The CLI supports common bucket and object operations and can also be
used with S3-compatible services by specifying an alternate endpoint.

=head2 Commands

=over

=item B<add-key>

  amzn-s3-cli add-key bucket-name filename [object-name]

Adds a file to a bucket.

The bucket may alternatively be supplied with C<--bucket-name>. If
C<object-name> is omitted, the filename is used as the object key.

The content type may be supplied with C<--content-type>. Otherwise the
CLI attempts to determine the MIME type with L<File::MimeInfo::Magic>,
when installed, and falls back to C<application/octet-stream>.

=item B<copy-key>

  amzn-s3-cli copy-key bucket-name key new-key

Copies an object to another key in the same bucket.

=item B<create-bucket>

  amzn-s3-cli create-bucket bucket-name

Creates a bucket.

Use C<--region> to select a region other than C<us-east-1>.

C<--availability-zone> may be used to create an S3 Express One Zone
directory bucket.

=item B<delete-key>

  amzn-s3-cli delete-key bucket-name key

Deletes an object.

Use C<--version-id> to delete a specific version from a versioned
bucket.

=item B<empty-bucket>

  amzn-s3-cli empty-bucket bucket-name

Removes all object versions, delete markers, and incomplete multipart
uploads from a bucket.

The command prompts for confirmation before deleting data. Use
C<--force> to suppress the prompt.

=item B<get-bucket-acl>

  amzn-s3-cli get-bucket-acl bucket-name

Retrieves the bucket ACL and emits the decoded result as JSON.

=item B<get-bucket-policy>

  amzn-s3-cli get-bucket-policy bucket-name

Retrieves the bucket policy and emits it as formatted JSON.

=item B<get-bucket-policy-status>

  amzn-s3-cli get-bucket-policy-status bucket-name

Retrieves the public-access status calculated from the bucket policy
and emits the decoded result as JSON.

=item B<get-key>

  amzn-s3-cli get-key bucket-name key

Retrieves an object.

By default the object is written to a file using the basename of the
object key.

Use C<--output> to specify another filename or C<--output -> to write
the object to standard output.

Use C<--version-id> to retrieve a specific object version.

Use C<--range> to request a byte range and C<--modified-since> to add an
C<If-Modified-Since> condition.

=item B<list-bucket-keys>

  amzn-s3-cli list-bucket-keys bucket-name [prefix]

Lists all objects in a bucket using the ListObjectsV2 API.

A prefix may alternatively be supplied with C<--prefix>.

C<list-keys> is an alias for C<list-bucket-keys>.

=item B<list-buckets>

  amzn-s3-cli list-buckets

Lists general-purpose S3 buckets available to the current credentials.

=item B<list-directory-buckets>

  amzn-s3-cli list-directory-buckets

Lists S3 Express One Zone directory buckets.

=item B<list-object-versions>

  amzn-s3-cli list-object-versions bucket-name [prefix]

Lists object versions in a bucket.

The listing includes the object key, size, last-modified timestamp,
latest-version indicator, and version ID.

=item B<remove-bucket>

  amzn-s3-cli remove-bucket bucket-name

Removes a bucket.

The bucket must satisfy normal S3 deletion requirements. Use
C<empty-bucket> first when necessary.

=back

=head2 Options

Most commands accept the bucket name positionally or through
C<--bucket-name>.

Output-producing commands generally support C<text>, C<json>, and
C<table> formats. Table output requires L<Text::ASCIITable>.

Credentials are discovered through L<Amazon::Credentials> when that
module is installed. Otherwise the CLI uses the standard AWS credential
environment variables.

Use C<--endpoint-url> when working with an alternate S3-compatible
service such as LocalStack.

=head1 OPTIONS

=over

=item B<--availability-zone>

Specifies an Availability Zone when creating an S3 Express One Zone
directory bucket.

=item B<--bucket-name>, B<-b>

Specifies the bucket name.

=item B<--content-type>

Specifies the content type used when adding an object.

=item B<--debug>

Enables debug logging.

=item B<--dns-bucket-names>

Enables DNS-style bucket addressing.

=item B<--endpoint-url>, B<-u>

Specifies the complete S3 service endpoint URL.

For example:

  --endpoint-url http://localhost:4566

The URL scheme determines whether HTTP or HTTPS is used.

=item B<--force>, B<-f>

Suppresses confirmation prompts for destructive operations.

=item B<--format>, B<-F>

Selects the output format.

 text
 json
 table

The default is C<text>.

Table output requires L<Text::ASCIITable>.

=item B<--help>, B<-h>

Displays command help.

=item B<--host>, B<-H>

Specifies the S3 service host using the legacy host configuration
mechanism.

C<--endpoint-url> is preferred for alternate endpoints.

=item B<--key>, B<-k>

Specifies an object key.

=item B<--modified-since>, B<-m>

Supplies an C<If-Modified-Since> condition to C<get-key>.

=item B<--output>, B<-o>

Specifies where C<get-key> writes its result.

Use C<-> to write object data to standard output.

=item B<--prefix>

Limits object listing commands to keys beginning with the specified
prefix.

=item B<--profile>, B<-p>

Selects an AWS credential profile.

This option requires L<Amazon::Credentials>.

=item B<--range>, B<-R>

Requests a byte range with C<get-key>.

Specify only the range:

  --range 0-1023

=item B<--region>, B<-r>

Specifies the AWS region.

The default is C<us-east-1>.

=item B<--secure>, B<-s>

Controls secure transport when host-based endpoint configuration is
used.

When C<--endpoint-url> is supplied, the URL scheme determines the
transport.

=item B<--version-id>

Specifies an object version ID for C<get-key> or C<delete-key>.

=back

=head1 AUTHENTICATION

If L<Amazon::Credentials> is installed, C<amzn-s3-cli> uses it for
credential discovery and supports named profiles:

  amzn-s3-cli list-buckets --profile sandbox

Without L<Amazon::Credentials>, credentials are read from:

  AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY
  AWS_SESSION_TOKEN

=head1 S3-COMPATIBLE SERVICES

An alternate S3 endpoint may be selected with C<--endpoint-url>:

  amzn-s3-cli list-buckets --endpoint-url http://localhost:4566 --profile localstack

This is useful for LocalStack and other S3-compatible services.

=head1 OPTIONAL DEPENDENCIES

=over

=item L<Amazon::Credentials>

Provides credential discovery and named profile support.

=item L<File::MimeInfo::Magic>

Provides MIME type detection for C<add-key>.

=item L<Text::ASCIITable>

Provides C<--format table> output.

=back

=head1 SEE ALSO

L<Amazon::S3>

L<Amazon::S3::Bucket>

L<Amazon::S3::BucketV2>

L<Amazon::Credentials>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Rob Lauer - E<lt>rlauer@treasurersbriefcase.comE<gt>

=cut
