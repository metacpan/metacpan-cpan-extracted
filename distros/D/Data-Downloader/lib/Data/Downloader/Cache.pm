
=head1 NAME

Data::Downloader::Cache

=head1 SYNOPSIS

    my $cache = Data::Downloader::Cache::LRU->new(repository => <repository>);
    $cache->purge if $cache->needs_purge;

=head1 DESCRIPTION

This is the base class for caching algorithms.

A Data::Downloader::Cache acts on a repository; a repository
uses a particular cache algorithm.  The cache algorithm is then
responsible for determining which files have expired, and purging
them as necessary.

=head1 METHODS

=over

=cut

package Data::Downloader::Cache;
use Params::Validate qw/validate/;
use Log::Log4perl qw/:easy/;
use strict;
use warnings;

use base "Rose::Object"; # NB: not a db::object

=item repository

Get or set the repository (a DD::Repository object)

=cut

use Rose::Object::MakeMethods::Generic(
    scalar => [qw/repository _current_size/],
);

=item purge

Purge all expired files for a repository.

=cut

sub purge {
    my $self = shift;
    return unless $self->needs_purge;
    for my $file ($self->find_expired_files) {
        DEBUG "Purging file @{[$file->filename]} (@{[$file->id]}), atime: ".$file->atime;
        $file->remove;
    }
}

sub _calculate_current_size {
    my $self = shift;
    my ($current_size) =
    $self->repository->db->simple->select( 'file', 'sum(size)',
        { repository => $self->repository->id, on_disk => 1 } )->list;
    DEBUG "calculated current size : $current_size" if defined($current_size);
    $self->_current_size($current_size);
}

=item needs_purge

Does the cache for this repository need to be purged?

=cut

sub needs_purge {
    my $self = shift;
    $self->_calculate_current_size;
    return unless defined($self->_current_size);
    return ($self->_current_size > $self->repository->cache_max_size);
}

=item find_expired_files

Find all the files which are expired, and may be purged.

Returns a list of DD::File objects.

=cut

sub find_expired_files {
    die "virtual method";
}

=back

=head1 SEE ALSO

L<Data::Downloader::Cache::LRU>

=cut

1;

