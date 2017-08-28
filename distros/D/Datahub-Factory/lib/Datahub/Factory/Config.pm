package Datahub::Factory::Config;

use Datahub::Factory::Sane;

use Config::Simple;

use Moo;
use Catmandu;
use namespace::clean;

with 'Datahub::Factory::Logger';

has config_file => (is => 'ro');
has config => (is => 'lazy');

sub _build_config {
    my $self = shift;
    return new Config::Simple($self->get_config_file());
};

# Loop over a list of predefined locations
# where a config file _might_ be. Take the
# first one that exists and return it.
# Throw exceptions on failure.
sub get_config_file {
    my $self = shift;
    my @config_locations = ('/etc/datahub-factory/settings.ini', 'conf/settings.ini');
    if (defined ($self->config_file)) {
        unshift @config_locations, $self->config_file;
    }
    foreach my $config_file (@config_locations) {
        if (-f $config_file) {
            return $config_file;
        }
    }
    Catmandu::Error->throw({
        message => 'No configuration file found.'
    });
}

1;

__END__

=head1 NAME

Datahub::Factory::Config - A Datahub::Factory configuration file loader

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

