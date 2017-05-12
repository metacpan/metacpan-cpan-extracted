package Datahub::Factory::Importer;

use Datahub::Factory::Sane;

use Catmandu;
use Moose::Role;
use namespace::clean;

has importer => (is  => 'lazy');
has logger   => (is => 'lazy');
has config   => (is => 'lazy');

after _build_importer => sub { };

sub _build_logger {
    my $self = shift;
    return Log::Log4perl->get_logger('datahub');
}

# TODO: ChangeMe
sub _build_config {
    my $self = shift;
    return new Config::Simple('conf/settings.ini');
}

1;
