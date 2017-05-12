package Brackup::Target::Riak;
use strict;
use warnings;
use base 'Brackup::Target';
use Net::Riak 0.09;

# fields in object:
#   host_url
#   r
#   w
#   dw
#   bucket_prefix
#   client - Net::Riak client object
#   bucket - hashref holding 'chunk' and 'backup' bucket references
#   content_type - hashref holding 'chunk' and 'backup' content types
#

sub new {
    my ($class, $confsec) = @_;
    my $self = $class->SUPER::new($confsec);

    $self->{host_url} = $confsec->value("riak_host_url") || 'http://127.0.0.1:8098';
    $self->{r} = $confsec->value("riak_r");
    $self->{w} = $confsec->value("riak_w");
    $self->{dw} = $confsec->value("riak_dw");
    $self->{bucket_prefix} = $confsec->value("riak_bucket_prefix") || 'brackup';

    $self->_init;

    return $self;
}

sub _init {
    my $self = shift;

    my %quorum_attr = ();
    $quorum_attr{r}  = $self->{r}  if $self->{r};
    $quorum_attr{w}  = $self->{w}  if $self->{w};
    $quorum_attr{dw} = $self->{dw} if $self->{dw};

    # Construct client
    $self->{client} = Net::Riak->new( host => $self->{host_url}, %quorum_attr );

    $self->{bucket} = {
      chunk  => $self->{client}->bucket( $self->{bucket_prefix} . "-chunks"  ),
      backup => $self->{client}->bucket( $self->{bucket_prefix} . "-backups" ),
    };
    $self->{content_type} = {
      chunk  => 'x-danga/brackup-chunk',
      backup => 'x-danga/brackup-meta',
    };
}

# w and dw aren't required for restores, so omitted here
sub backup_header {
    my ($self) = @_;
    return {
        RiakHostUrl  => $self->{host_url},
        RiakBucketPrefix => $self->{bucket_prefix},
        $self->{r} ? ( RiakR => $self->{r} ) : (),
    };
}

# Location and backup_prefix aren't required for restores, so they're omitted here
sub new_from_backup_header {
    my ($class, $header, $confsec) = @_;

    my $host_url =      ($ENV{'RIAK_HOST_URL_LIST'} || 
                         $header->{RiakHostUrl} || 
                         $confsec->value('riak_host_url') || 
                         'http://127.0.0.1:8098');
    my $r =             ($ENV{RIAK_R} ||
                         $header->{RiakR} ||
                         $confsec->value('riak_r'));
    my $bucket_prefix = ($ENV{'RIAK_BUCKET_PREFIX'} || 
                         $header->{RiakBucketPrefix} ||
                         $confsec->value('riak_bucket_prefix') ||
                         'brackup');

    my $self = bless {}, $class;
    $self->{host_url} = $host_url;
    $self->{r} = $r;
    $self->{bucket_prefix} = $bucket_prefix;

    $self->_init;

    return $self;
}

# riak seems to give transient errors with degraded nodes, so retry reads and writes
sub _retry {
    my ($self, $op, $sub, $ok) = @_;
    $ok ||= sub {
        my $obj = shift;
        return $obj && $obj->exists;
    };

    my $obj;
    my $n_fails = 0;
    while ($n_fails < 5) {
        $obj = $sub->();
        last if $ok->($obj);

        $n_fails++;
        warn "Error $op ... will do retry \#$n_fails in 5 seconds ...\n";
        sleep 5;
    }

    return $obj;
}

sub _load {
    my ($self, $type, $key) = @_;

    my $bucket = $self->{bucket}->{$type} or die "Invalid type '$type'";
    my $content_type = $self->{content_type}->{$type};

    my $obj = $self->_retry("loading $type $key", sub { $bucket->get($key) });

    return unless $obj->exists;
    return unless $obj->content_type eq $content_type;

    return $obj;
}

sub has_chunk {
    my ($self, $chunk) = @_;
    my $dig = $chunk->backup_digest;   # "sha1:sdfsdf" format scalar

    eval { $self->_load(chunk => $dig) } or return 0;

    return 1;
}

sub load_chunk {
    my ($self, $dig) = @_;

    my $obj = $self->_load(chunk => $dig) or return;

    return \ $obj->data;
}

sub _store {
    my ($self, $type, $key, $data) = @_;

    my $bucket = $self->{bucket}->{$type} or die "Invalid type '$type'";
    my $content_type = $self->{content_type}->{$type};

    my $sub = sub {
        my $obj = $bucket->new_object($key, $data,
            content_type  => $content_type,
        );
        $obj->store;
    };

    my $obj = $self->_retry("storing $type $key", $sub);

    unless ($obj->exists) {
        warn "Error uploading chunk again: " . $obj->status . "\n";
        return 0;
    }
    return 1;
}

sub store_chunk {
    my ($self, $chunk) = @_;
    my $dig = $chunk->backup_digest;
    my $fh = $chunk->chunkref;
    my $chunkref = do { local $/; <$fh> };

    return $self->_store(chunk => $dig, $chunkref);
}

sub delete_chunk {
    my ($self, $dig) = @_;

    my $obj = $self->_load(chunk => $dig) or return;

    $obj->delete;
}

# returns a list of names of all chunks
sub chunks {
    my $self = shift;

    my $chunks = $self->_retry("loading chunks", 
        sub { $self->{bucket}->{chunk}->get_keys({stream => 1}) },
        sub { my $chunks = shift; $chunks && ref $chunks eq 'ARRAY' },
    );

    return unless $chunks;
    return @$chunks;
}

sub store_backup_meta {
    my ($self, $name, $fh) = @_;
    my $content = do { local $/; <$fh> };

    return $self->_store(backup => $name, $content);
}

sub backups {
    my $self = shift;

    my $backups = $self->_retry("loading backups", 
        sub { $self->{bucket}->{backup}->get_keys({stream => 1}) },
        sub { my $backups = shift; $backups && ref $backups eq 'ARRAY' },
    );

    my @ret = ();
    foreach my $backup (@$backups) {
        # Riak has no explicit mtime/size metadata
        my @elements = split /-/, $backup;
        push @ret, Brackup::TargetBackupStatInfo->new($self, $backup,
                                                      time => $elements[$#elements],
                                                      size => 0);
    }

    return @ret;
}

sub get_backup {
    my ($self, $name, $output_file) = @_;

    my $obj = $self->_load(backup => $name) or return;

	$output_file ||= "$name.brackup";
    open(my $out, ">$output_file") or die "Failed to open $output_file: $!\n";
    my $outv = syswrite($out, $obj->data);
    die "download/write error" unless $outv == do { use bytes; length $obj->data };
    close $out;
    return 1;
}

sub delete_backup {
    my ($self, $name) = @_;

    my $obj = $self->_load(backup => $name) or return;

    $obj->delete;
}

sub chunkpath {
    my ($self, $dig) = @_;
    return $dig;
}

sub size {
    my ($self, $dig) = @_;

    my $obj = $self->_load(chunk => $dig) or return 0;

    return $obj->_headers->content_length;
}

1;

=head1 NAME

Brackup::Target::Riak - backup to a Riak key-value store

=head1 EXAMPLE

In your ~/.brackup.conf file:

  [TARGET:riak1]
  type = Riak
  riak_host_url = http://192.168.1.1:8098/
  riak_r = 1
  riak_bucket_prefix = brackup-test

=head1 CONFIG OPTIONS

All options may be omitted unless specified.

=over

=item B<type>

I<(Mandatory.)> Must be "B<Riak>".

=item B<riak_host_url>

URL specifying your riak cluster endpoint. Default: http://127.0.0.1:8098/.

=item B<riak_r> 

riak read quorum - how many replicas need to agree when retrieving an object. 
Default: 2.

=item B<riak_w> 

riak write quorum - how many replicas to write to before returning success. 
Default: 2.

=item B<riak_dw> 

riak durable write quorum - how many replicas to write to durable storage 
before returning success. Default: 2.

=item B<riak_bucket_prefix>

Prefix to use on riak buckets. Probably only worth changing if you want to
store (and separate) multiple brackups in a riak cluster. Default: brackup.

=back

=head1 SEE ALSO

L<Brackup::Target>

L<Net::Riak> -- required module to use Brackup::Target::Riak

=head1 AUTHOR

Gavin Carr E<lt>gavin@openfusion.com.auE<gt>.

Copyright (c) 2010 Gavin Carr.

This module is free software. You may use, modify, and/or redistribute 
this software under the same terms as perl itself.

=cut

# vim:sw=4:et

