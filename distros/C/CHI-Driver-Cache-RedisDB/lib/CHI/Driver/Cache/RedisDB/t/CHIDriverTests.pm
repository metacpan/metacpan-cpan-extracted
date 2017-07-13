package CHI::Driver::Cache::RedisDB::t::CHIDriverTests;
use strict;
use warnings;
use CHI::Test;
use base qw(CHI::t::Driver);

sub testing_driver_class { 'CHI::Driver::Cache::RedisDB' }

sub new_cache_options {
    my $self = shift;

    return (
        $self->SUPER::new_cache_options(),
    );
}

1;
