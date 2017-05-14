package Datahub::Factory::Env;

use Datahub::Factory::Sane;

use Datahub::Factory::Util qw(require_package);
use Moo;
use Catmandu;
use namespace::clean;
use Config::Simple;
use Data::Dumper qw(Dumper);

with 'Datahub::Factory::Logger';

sub importer {
    my $self = shift;
    my $name = shift;
    my $ns = "Datahub::Factory::Importer";
    # If the "plugin" in [Importer] is empty, $name is an empty array
    if (!defined($name) || (ref $name eq 'ARRAY' && scalar @{$name} == 0)) {
        die 'Undefined value for plugin at [Importer]';
    }

    return require_package($name, $ns);
}

sub fixer {
    my $self = shift;
    my $name = shift;
    my $ns = "Datahub::Factory::Fixer";
    # If the "plugin" in [Fixer] is empty, $name is an empty array
    if (!defined($name) || (ref $name eq 'ARRAY' && scalar @{$name} == 0)) {
        die 'Undefined value for plugin at [Fixer]';
    }
    
    return require_package($name, $ns);
}

sub exporter {
    my $self = shift;
    my $name = shift;
    my $ns = "Datahub::Factory::Exporter";
    # If the "plugin" in [Exporter] is empty, $name is an empty array
    if (!defined($name) || (ref $name eq 'ARRAY' && scalar @{$name} == 0)) {
        die 'Undefined value for plugin at [Exporter]';
    }
    
    return require_package($name, $ns);
}

sub pipeline {
    my $self = shift;
    require_package('PipelineConfig', 'Datahub::Factory')->new({'conf_object' => @_});
}

sub module {
    my $self = shift;
    my $name = shift;
    my $ns = "Datahub::Factory::Module";
    return require_package($name, $ns);
}

1;

__END__

=head1 NAME

Datahub::Factory::Env - A Datahub::Factory configuration file loader

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

