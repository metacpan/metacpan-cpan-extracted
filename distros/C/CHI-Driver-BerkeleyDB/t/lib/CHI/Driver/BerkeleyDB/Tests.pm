package CHI::Driver::BerkeleyDB::Tests;

use strict;
use warnings;

use parent 'CHI::t::Driver';

use CHI::Test;
use File::Temp 'tempdir';

my $root_dir;

sub testing_driver_class { 'CHI::Driver::BerkeleyDB' }

sub new_cache_options {
    my $self = shift;

    $root_dir ||= tempdir("chi-driver-berkeleydb-XXXX", TMPDIR => 1, CLEANUP => 1);

    return (
        $self->SUPER::new_cache_options(),
        root_dir => "$root_dir/berkeleydb"
    );
}

# Fix for RT #103290
sub noisy_remove :Tests {
    my $self = shift;

    my $cache = $self->new_cleared_cache;

    $cache->remove('foo');
}

1;
