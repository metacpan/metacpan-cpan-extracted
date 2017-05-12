=head1 NAME

Data::Downloader::Cache::Keep

=head1 DESCRIPTION

Cache algorithm that keeps all files and never expires anything.

=cut

package Data::Downloader::Cache::Keep;
use strict;
use warnings;

use base "Data::Downloader::Cache";

sub find_expired_files {
    return;
}

sub needs_purge {
    0;
}

1;

