=head1 NAME

Data::Downloader::Cache::LRU

=head1 DESCRIPTION

Least Recently Used caching algorithm.

This algorithm chooses the files which have been
used least recently (based on the file's atime
as returned by stat(2)).

=cut

package Data::Downloader::Cache::LRU;
use Params::Validate qw/validate/;
use Log::Log4perl qw/:easy/;
use Rose::DateTime::Util qw/parse_date/;
use strict;
use warnings;

use base "Data::Downloader::Cache";

sub find_expired_files {
    my $self = shift;

    my $max_allowed = $self->repository->cache_max_size;

    # first update atimes in db
    $self->repository->update_stats;

    # Just order by atime and id, then pick files until the
    # sum is under $max_allowed;
    $self->_calculate_current_size;
    my $potential_size = $self->_current_size || 0;
    my @expired;
    my $iterator = Data::Downloader::File::Manager->get_files_iterator(
        query => [ repository => $self->repository->id, on_disk => 1 ],
        sort_by => 'atime,id' );
    my $file;
    while ($potential_size > $max_allowed && ($file = $iterator->next)) {
        DEBUG "found file to expire : ".$file->filename;
        push @expired, $file;
        $potential_size -= $file->size;
    }
    return @expired;
}

1;

