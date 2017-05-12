package Brackup::Target::Amazon;
use strict;
use warnings;
use base 'Brackup::Target';
use Net::Amazon::S3 0.42;
use DateTime::Format::ISO8601;

# fields in object:
#   s3  -- Net::Amazon::S3
#   access_key_id
#   sec_access_key_id
#   prefix
#   location
#   chunk_bucket : $self->{prefix} . "-chunks";
#   backup_bucket : $self->{prefix} . "-backups";
#   backup_prefix : added to the front of backup names when stored
#

sub new {
    my ($class, $confsec) = @_;
    my $self = $class->SUPER::new($confsec);

    $self->{access_key_id}     = $confsec->value("aws_access_key_id")
        or die "No 'aws_access_key_id'";
    $self->{sec_access_key_id} = $confsec->value("aws_secret_access_key")
        or die "No 'aws_secret_access_key'";
    $self->{prefix} = $confsec->value("aws_prefix") || $self->{access_key_id};
    $self->{location} = $confsec->value("aws_location") || undef;
    $self->{backup_prefix} = $confsec->value("backup_prefix") || undef;

    $self->_common_s3_init;

    my $s3      = $self->{s3};
    my $buckets = $s3->buckets or die "Failed to get bucket list";

    unless (grep { $_->{bucket} eq $self->{chunk_bucket} } @{ $buckets->{buckets} }) {
        $s3->add_bucket({ bucket => $self->{chunk_bucket}, location_constraint => $self->{location} })
            or die "Chunk bucket creation failed\n";
    }

    unless (grep { $_->{bucket} eq $self->{backup_bucket} } @{ $buckets->{buckets} }) {
        $s3->add_bucket({ bucket => $self->{backup_bucket}, location_constraint => $self->{location} })
            or die "Backup bucket creation failed\n";
    }

    return $self;
}

sub _common_s3_init {
    my $self = shift;
    $self->{chunk_bucket}  = $self->{prefix} . "-chunks";
    $self->{backup_bucket} = $self->{prefix} . "-backups";
    $self->{s3}            = Net::Amazon::S3->new({
        aws_access_key_id     => $self->{access_key_id},
        aws_secret_access_key => $self->{sec_access_key_id},
        retry                 => 1,
    });
}

# ghetto
sub _prompt {
    my ($q) = @_;
    print "$q";
    my $ans = <STDIN>;
    $ans =~ s/^\s+//;
    $ans =~ s/\s+$//;
    return $ans;
}

# Location and backup_prefix aren't required for restores, so they're omitted here
sub backup_header {
    my ($self) = @_;
    return {
        "AWSAccessKeyID"    => $self->{access_key_id},
        "AWSPrefix"         => $self->{prefix},
    };
}

# Location and backup_prefix aren't required for restores, so they're omitted here
sub new_from_backup_header {
    my ($class, $header, $confsec) = @_;

    my $accesskey     = ($ENV{'AWS_KEY'} || 
                         $ENV{'AWS_ACCESS_KEY_ID'} ||
                         $header->{AWSAccessKeyID} || 
                         $confsec->value('aws_access_key_id') || 
                         _prompt("Your Amazon AWS access key? "))
        or die "Need your Amazon access key.\n";
    my $sec_accesskey = ($ENV{'AWS_SEC_KEY'} || 
                         $ENV{'AWS_ACCESS_KEY_SECRET'} ||
                         $confsec->value('aws_secret_access_key') || 
                         _prompt("Your Amazon AWS secret access key? "))
        or die "Need your Amazon secret access key.\n";
    my $prefix        = ($ENV{'AWS_PREFIX'} || 
                         $header->{AWSPrefix} ||
                         $confsec->value('aws_prefix'));

    my $self = bless {}, $class;
    $self->{access_key_id}     = $accesskey;
    $self->{sec_access_key_id} = $sec_accesskey;
    $self->{prefix}            = $prefix || $self->{access_key_id};
    $self->_common_s3_init;
    return $self;
}

sub has_chunk {
    my ($self, $chunk) = @_;
    my $dig = $chunk->backup_digest;   # "sha1:sdfsdf" format scalar

    my $res = eval { $self->{s3}->head_key({ bucket => $self->{chunk_bucket}, key => $dig }); };
    return 0 unless $res;
    return 0 if $@ && $@ =~ /key not found/;
    return 0 unless $res->{content_type} eq "x-danga/brackup-chunk";
    return 1;
}

sub load_chunk {
    my ($self, $dig) = @_;
    my $bucket = $self->{s3}->bucket($self->{chunk_bucket});

    my $val = $bucket->get_key($dig)
        or return 0;
    return \ $val->{value};
}

sub store_chunk {
    my ($self, $chunk) = @_;
    my $dig = $chunk->backup_digest;
    my $fh = $chunk->chunkref;
    my $chunkref = do { local $/; <$fh> };

    my $try = sub {
        eval {
            $self->{s3}->add_key({
                bucket        => $self->{chunk_bucket},
                key           => $dig,
                value         => $chunkref,
                content_type  => 'x-danga/brackup-chunk',
            });
        };
    };

    my $rv;
    my $n_fails = 0;
    while (!$rv && $n_fails < 5) {
        $rv = $try->();
        last if $rv;

        # transient failure?
        $n_fails++;
        warn "Error uploading chunk $chunk [$@]... will do retry \#$n_fails in 5 seconds ...\n";
        sleep 5;
    }
    unless ($rv) {
        warn "Error uploading chunk again: " . $self->{s3}->errstr . "\n";
        return 0;
    }
    return 1;
}

sub delete_chunk {
    my ($self, $dig) = @_;
    my $bucket = $self->{s3}->bucket($self->{chunk_bucket});
    return $bucket->delete_key($dig);
}

# returns a list of names of all chunks
sub chunks {
    my $self = shift;

    my $chunks = $self->{s3}->list_bucket_all({ bucket => $self->{chunk_bucket} });
    return map { $_->{key} } @{ $chunks->{keys} };
}

sub store_backup_meta {
    my ($self, $name, $fh, $meta) = @_;

    $name = $self->{backup_prefix} . "-" . $name if defined $self->{backup_prefix};

    eval { 
        my $bucket = $self->{s3}->bucket($self->{backup_bucket}); 
        $bucket->add_key_filename(
            $name,
            $meta->{filename},
            { content_type => 'x-danga/brackup-meta' },
        );
    };
}

sub backups {
    my $self = shift;

    my @ret;
    my $backups = $self->{s3}->list_bucket_all({ bucket => $self->{backup_bucket} });
    foreach my $backup (@{ $backups->{keys} }) {
        my $iso8601 = DateTime::Format::ISO8601->parse_datetime( $backup->{last_modified} );
        push @ret, Brackup::TargetBackupStatInfo->new($self, $backup->{key},
                                                      time => $iso8601->epoch,
                                                      size => $backup->{size});
    }
    return @ret;
}

sub get_backup {
    my $self = shift;
    my ($name, $output_file) = @_;

    my $bucket = $self->{s3}->bucket($self->{backup_bucket});
    my $val = $bucket->get_key($name)
        or return 0;

	$output_file ||= "$name.brackup";
    open(my $out, ">$output_file") or die "Failed to open $output_file: $!\n";
    my $outv = syswrite($out, $val->{value});
    die "download/write error" unless $outv == do { use bytes; length $val->{value} };
    close $out;
    return 1;
}

sub delete_backup {
    my $self = shift;
    my $name = shift;

    my $bucket = $self->{s3}->bucket($self->{backup_bucket});
    return $bucket->delete_key($name);
}

sub chunkpath {
    my $self = shift;
    my $dig = shift;

    return $dig;
}

sub size {
    my $self = shift;
    my $dig = shift;

    my $res = eval { $self->{s3}->head_key({ bucket => $self->{chunk_bucket}, key => $dig }); };
    return 0 unless $res;
    return 0 if $@ && $@ =~ /key not found/;
    return 0 unless $res->{content_type} eq "x-danga/brackup-chunk";
    return $res->{content_length};
}

1;

=head1 NAME

Brackup::Target::Amazon - backup to Amazon's S3 service

=head1 EXAMPLE

In your ~/.brackup.conf file:

  [TARGET:amazon]
  type = Amazon
  aws_access_key_id  = ...
  aws_secret_access_key =  ....
  aws_prefix =  ....
  backup_prefix =  ....

=head1 CONFIG OPTIONS

All options may be omitted unless specified.

=over

=item B<type>

I<(Mandatory.)> Must be "B<Amazon>".

=item B<aws_access_key_id>

I<(Mandatory.)> Your Amazon Web Services access key id.

=item B<aws_secret_access_key>

I<(Mandatory.)> Your Amazon Web Services secret password for the above access key.  (not your Amazon password)

=item B<aws_prefix>

If you want to setup multiple backup targets on a single Amazon account you can
use different prefixes. This string is used to name the S3 buckets created by
Brackup. If not specified it defaults to the AWS access key id.

=item B<aws_location>

Sets the location constraint of the new buckets. If left unspecified, the
default S3 datacenter location will be used. Otherwise, you can set it
to 'EU' for an AWS European data center - note that costs are different.
This has only effect when your backup environment is initialized in S3 (i.e.
when buckets are created). If you want to move an existing backup environment
to another datacenter location, you have to delete its buckets before or create
a new one by specifing a different I<aws_prefix>.

=item B<backup_prefix>

When storing the backup metadata file to S3, the string specified here will 
be prefixed onto the backup name. This is useful if you are collecting
backups from several hosts into a single Amazon S3 account but need to
be able to differentiate them; set your prefix to be the hostname
of each system, for example.

=back

=head1 SEE ALSO

L<Brackup::Target>

L<Net::Amazon::S3> -- required module to use Brackup::Target::Amazon

