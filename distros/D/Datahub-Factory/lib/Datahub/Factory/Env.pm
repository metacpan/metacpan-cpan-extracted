package Datahub::Factory::Env;

use Datahub::Factory::Sane;

our $VERSION = '1.72';

use Config::Simple;
use Config::Onion;
use Datahub::Factory::Util qw(require_package);
use File::Spec;
use Moo;
require Datahub::Factory;
use namespace::clean;

sub _search_up {
    my $dir = $_[0];
    my @dirs = grep length, File::Spec->splitdir(Datahub::Factory->default_load_path);
    for (; @dirs; pop @dirs) {
        my $path = File::Spec->catdir(File::Spec->rootdir, @dirs);
        opendir my $dh, $path or last;
        return $path
            if grep {-r File::Spec->catfile($path, $_)}
            grep /^datahubfactory.+(?:yaml|yml|json|pl)$/, readdir $dh;
    }
    Datahub::Factory->default_load_path;
}

has load_paths => (
    is      => 'ro',
    default => sub {[]},
    coerce  => sub {
        [
            map {File::Spec->canonpath($_)}
                map {$_ eq ':up' ? _search_up($_) : $_} split /,/,
            join ',',
            ref $_[0] ? @{$_[0]} : $_[0]
        ];
    },
);

has config => (is => 'rwp', default => sub {+{}});

with 'Datahub::Factory::Logger';

sub BUILD {
    my ($self) = @_;

    my @config_dirs = @{$self->load_paths};

    if (@config_dirs) {
        my @globs = map {
            my $dir = $_;
            map {File::Spec->catfile($dir, "datahubfactory*.$_")}
                qw(yaml yml json pl)
        } reverse @config_dirs;

        my $config = Config::Onion->new(prefix_key => '_prefix');
        $config->load_glob(@globs);

        if ($self->log->is_debug) {
            use Data::Dumper;
            $self->log->debug(Dumper($config->get));
        }
        $self->_set_config($config->get);
    }
}

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

sub indexer {
    my $self = shift;
    my $name = shift;
    my $ns = "Datahub::Factory::Indexer";
    # If the "plugin" in [Indexer] is empty, $name is an empty array
    if (!defined($name) || (ref $name eq 'ARRAY' && scalar @{$name} == 0)) {
        die 'Undefined value for plugin at [Indexer]';
    }

    return require_package($name, $ns);
}

sub pipeline {
    my $self = shift;
    my $file_name = shift;
    my $pipeline = shift;
    # require_package('Pipeline', 'Datahub::Factory')->new({'file_name' => @_});
    require_package($pipeline, 'Datahub::Factory::Pipeline')->new({'file_name' => $file_name});
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

