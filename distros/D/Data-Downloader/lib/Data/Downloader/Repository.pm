=head1 NAME

Data::Downloader::Repository

=head1 DESCRIPTION

A repository is a collection of files managed by Data::Downloader
which have a common root directory.  Files within a given repository
may come from various RSS feeds and/or url templates.  They may be
stored in multiple top-level subdirectories, which are referred to
as "disks" (since in practice they may be located on different devices).

=head1 METHODS

=over

=cut

package Data::Downloader::Repository;
use Log::Log4perl qw/:easy/;
use Params::Validate qw/validate/;
use File::stat qw/stat/;
use YAML::XS qw/Dump/;
use Number::Format qw/format_number/;
use Data::Downloader::Utils qw/human_size/;
use Fcntl qw(:flock SEEK_END);
use strict;
use warnings;

=item save

Save a repository.  Also rebuild the metadata view (in
case that has changed).

=cut

# TODO handle updating a repository, including doing the
# right thing in different circumstances, e.g. if the
# symlink pattern is changed

sub save {
    my $self = shift;
    my $status = $self->SUPER::save(@_);
    return $status unless $status;
    DEBUG "saved metadata source ".$self->name.", rebuilding pivot view and filemetadata table";
    Data::Downloader::MetadataPivot->rebuild_pivot_view;
    Data::Downloader::MetadataPivot->do_setup;
    Data::Downloader::FileMetadata->rebuild_table;
    Data::Downloader::FileMetadata->do_setup;
    $status;
}

=item download_all

Parameters  :

    fake (boolean) -- fake the download.

Download all known files associated with this repository.

=cut

sub download_all {
    my $self = shift;
    my %args = @_; # TODO validate (fake =>1)
    for my $file (@{ $self->files }) { # TODO only where not downloaded?
        DEBUG "downloading file : ".$file->filename;
        $file->download(%args);
        for my $datum (@{ $file->metadata }) {
            TRACE "    " . $datum->name . " == " . $datum->value;
        }
    }
}

=item cache

Get a cache object for this repository.  See Data::Downloader::Cache.

=cut

sub cache {
    my $self = shift;
    my $strategy = $self->cache_strategy or return;
    my $cache_class = "Data::Downloader::Cache::$strategy";
    eval "use $cache_class";
    LOGDIE "error using $cache_class : $@" if $@;
    return $cache_class->new(repository => $self);
}

sub _initialize_stats {
    my $self = shift;
    return if $self->stat_info;
    unless ($self->stat_info) {
        $self->stat_info({last_stat_update => undef, last_fsck => undef, repository => $self->id});
        $_->save for $self->stat_info;
    }
}

=item update_stats

Update the stats for this repository, e.g. the atimes, and any
aggregate stats.  Won't update the stats before a specified
interval has elapsed.

Parameters :

    interval -- a Datetime::Duration object or "0" to force an update.
    defaults to one hour.

=cut

sub update_stats {
    my $self = shift;
    my $args = validate(@_, { interval => 0 });
    my $duration = $args->{duration};
    if (!defined($duration)) {
        $duration = DateTime::Duration->new(hours => 1);
    }
    $self->_initialize_stats; # only if necessary
    return if $duration &&
        $self->stat_info->last_stat_update &&
        ($self->stat_info->last_stat_update->add_duration($duration)) > DateTime->now();

    # Also set an advisory lock; only one process should do this.
    my ($lockfile,$lock);
    unless ($self->db->database eq ':memory:') {
        $lockfile = $self->db->database.".dado_stats_lock";
    }

    if ($lockfile) {
        open $lock, ">$lockfile" or do {
            ERROR "cannot write to $lockfile";
            return;
        };
        flock($lock, LOCK_EX) or return;
    }
    DEBUG "updating stats ($$)";
    my $files = Data::Downloader::File::Manager->get_files([on_disk => 1 ]);
    for my $file (@$files) {
        $file->load(speculative => 1) or next;
        my $stat = stat($file->storage_path) or next;
        $file->atime( DateTime->from_epoch(epoch => $stat->atime) );
        $file->save(changes_only => 1) or do {
            ERROR $file->error;
            return;
        };
    }
    $self->stat_info->last_stat_update(DateTime->now());
    $self->stat_info->save or do {
        ERROR $self->stat_info->error;
        return;
    };
    if ($lockfile) {
        flock ($lock, LOCK_UN) or LOGWARN "cannot unlock $lockfile";
    }
}

=item dump_stats

Print statistics about this repository to STDOUT.

=cut

sub dump_stats {
    my $self = shift;
    my $args = validate(@_, {yaml => 0});
    my %stats;

    @stats{qw/known_files/} = $self->db->simple->select(
        'file',
        [ 'count(1)', ],
        { repository => $self->id }
    )->list;

    @stats{qw/count size/} = $self->db->simple->select(
        'file',
        [ 'count(1)', 'sum(size)' ],
        { repository => $self->id, on_disk => 1 }
    )->list;

    $stats{size_h} = human_size($stats{size});

    if ($args->{yaml}) {
        print Dump(\%stats);
        return;
    }

    do {$stats{$_} = format_number($stats{$_} || 0)} for grep {$_ !~ /_h$/} keys %stats;


    print <<EOSTATS;
Total known files       : $stats{known_files}
Number of files on disk : $stats{count}
Size of files on disk   : $stats{size} bytes ($stats{size_h})

EOSTATS
}

=back

=head1 SEE ALSO

L<Rose::DB::Object>

L<Data::Downloader/SCHEMA>

=cut

1;

