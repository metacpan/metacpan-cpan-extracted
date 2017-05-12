package CHI::Driver::Rethinkdb::t::CHIDriverTests;
$CHI::Driver::Rethinkdb::t::CHIDriverTests::VERSION = '0.1.2';
use strict;
use warnings;
use CHI::Test;
use base qw(CHI::t::Driver);

sub testing_driver_class { 'CHI::Driver::Rethinkdb' }
sub supports_get_namespaces { 0 }

sub new_cache_options {
    my $self = shift;

    return (
        $self->SUPER::new_cache_options(),
        port => $ENV{RETHINKDB_PORT} || 28015,
        host => $ENV{RETHINKDB_HOST} || 'localhost'
    );

}

sub test_multiple_processes { }


1;

