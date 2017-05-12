package CHI::Driver::BerkeleyDB::t::CHIDriverTests;
use strict;
use warnings;
use CHI::Test;
use File::Temp qw(tempdir);
use base qw(CHI::t::Driver);

my $root_dir;

sub testing_driver_class { 'CHI::Driver::BerkeleyDB' }

sub new_cache_options {
    my $self = shift;

    $root_dir ||=
      tempdir( "chi-driver-berkeleydb-XXXX", TMPDIR => 1, CLEANUP => 1 );
    return ( $self->SUPER::new_cache_options(),
        root_dir => "$root_dir/berkeleydb" );
}

1;
