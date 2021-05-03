package Tests::Service::Cache;

use strict;
use warnings;

use Beekeeper::Worker ':log';
use base 'Beekeeper::Worker';

use Beekeeper::Worker::Util 'shared_cache';
use Time::HiRes 'sleep';

=pod

=head1 Test worker

Simple worker used to test shared cache.

=cut

sub on_startup {
    my $self = shift;

    $self->{Cache} = $self->shared_cache( id => "test", max_age => 20 );

    $self->accept_jobs(
        'cache.set'  => 'set',
        'cache.get'  => 'get',
        'cache.del'  => 'del',
        'cache.raw'  => 'raw_data',
        'cache.bal'  => 'balance',
        'cache.run'  => 'run_data',
        'cache.clr'  => 'clear',
    );
}

sub authorize_request {
    my ($self, $req) = @_;

    return REQUEST_AUTHORIZED;
}

sub get {
    my ($self, $params) = @_;

    $self->{Cache}->get( $params->{'key'} );
}

sub set {
    my ($self, $params) = @_;

    $self->{Cache}->set( $params->{'key'} => $params->{'val'} );
}

sub del {
    my ($self, $params) = @_;

    $self->{Cache}->delete( $params->{'key'} );
}

sub raw_data {
    my ($self, $params) = @_;

    return $self->{Cache}->raw_data;
}

sub balance {
    my ($self, $params) = @_;

    my $dset = $params->{dset} || '';

    my $pid = $$;
    my $runs = $self->{Cache}->get( "$dset:$pid" ) || 0;

    sleep $params->{sleep} if $params->{sleep};

    $self->{Cache}->set( "$dset:$pid" => $runs + 1 );
}

sub run_data {
    my ($self, $params) = @_;

    my $dset = $params->{dset} || '';

    my $cache = $self->{Cache}->raw_data;
    my $raw = {};

    foreach my $key (keys %$cache) {
        next unless $key =~ m/^$dset:(.*)/;
        $raw->{$1} = $cache->{$key};
    }

    return $raw;
}

sub clear {
    my ($self, $params) = @_;

    my $data = $self->{Cache}->raw_data;

    foreach my $pid (keys %$data) {
        $self->{Cache}->delete( $pid );
    }
}

1;
