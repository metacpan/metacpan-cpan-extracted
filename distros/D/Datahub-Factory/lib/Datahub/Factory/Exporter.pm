package Datahub::Factory::Exporter;

use strict;
use warnings;

use Catmandu;
use Moose::Role;

use Catmandu::Util qw(:io);

has out => (
    is  => 'lazy'
);

has logger    => (is => 'lazy');
has config    => (is => 'lazy');
has stdout_fh => (is => 'lazy');

sub _build_logger {
    my $self = shift;
    return Log::Log4perl->get_logger('datahub');
}

# TODO: ChangeMe
sub _build_config {
    my $self = shift;
    return new Config::Simple('conf/settings.ini');
}

sub _build_stdout_fh {
    my $self = shift;
    return io(\*STDOUT, mode => 'w');
}

1;