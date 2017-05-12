package TestUtils;

use strict;
use warnings;

use File::Spec;
use File::Path;
use BackPAN::Index;

use base "Exporter";
our @EXPORT = qw(new_backpan new_pbp cache_dir clear_cache);


# The local cache directory for testing
sub cache_dir {
    return File::Spec->rel2abs("t/cache");
}


# Delete the local cache directory
sub clear_cache {
    rmtree cache_dir();
}


# Determine if we should download the remote index or
# use the local one that comes with the distribution.
use URI::file;
use File::Spec::Unix;
my $local_index_url  = URI::file->new( File::Spec::Unix->rel2abs("t/backpan.txt.gz") );

sub backpan_index_url {
    use LWP::Simple;

    return $local_index_url if $ENV{BACKPAN_INDEX_TEST_NO_INTERNET};

    my $remote_index_url = BackPAN::Index->default_backpan_index_url;
    return head($remote_index_url) ? $remote_index_url : $local_index_url;
}

sub backpan_index_arg {
    return backpan_index_url => backpan_index_url();
}


# Init a new BackPAN::Index object with the right options for testing
sub new_backpan {
    my %args = @_;

    return BackPAN::Index->new({
        cache_dir               => cache_dir(),
        update                  => 0,
	backpan_index_arg(),
        %args
    });
}

sub new_pbp {
    my %args = @_;

    require Parse::BACKPAN::Packages;
    return Parse::BACKPAN::Packages->new({
        cache_dir               => cache_dir(),
        update                  => 0,
	backpan_index_arg(),
        %args
    });
}

1;
