package App::CISetup::Role::ConfigUpdater;

use strict;
use warnings;
use namespace::autoclean;
use autodie qw( :all );

our $VERSION = '0.13';

use App::CISetup::Travis::ConfigFile;
use App::CISetup::Types qw( Bool CodeRef Dir Str );
use File::pushd qw( pushd );
use Git::Sub qw( remote );
use Path::Iterator::Rule;
use Path::Tiny qw( path );
use Try::Tiny;
use YAML qw( Load );

use Moose::Role;

requires qw(
    _config_file_class
    _config_filename
    _cli_params
);

has create => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has dir => (
    is       => 'ro',
    isa      => Dir,
    required => 1,
    coerce   => 1,
);

has _config_file_iterator => (
    is      => 'ro',
    isa     => CodeRef,
    lazy    => 1,
    builder => '_build_config_file_iterator',
);

with 'MooseX::Getopt::Dashes';

sub run {
    my $self = shift;

    return $self->create
        ? $self->_create_file
        : $self->_update_files;
}

sub _create_file {
    my $self = shift;

    my $file = $self->dir->child( $self->_config_filename );
    $self->_config_file_class->new( $self->_cf_params($file) )->create_file;

    print "Created $file\n" or die $!;

    return 0;
}

sub _update_files {
    my $self = shift;

    my $iter = $self->_config_file_iterator;

    my $count = 0;
    while ( my $file = $iter->() ) {
        $file = path($file);

        $count++;
        my $updated = try {
            $self->_config_file_class->new( $self->_cf_params($file) )
                ->update_file;
        }
        catch {
            print "\n\n\n" . $file . "\n" or die $!;
            print $_ or die $!;
        };

        next unless $updated;

        print "Updated $file\n" or die $!;
    }

    warn sprintf( "WARNING: No %s files found\n", $self->_config_filename )
        unless $count;

    return 0;
}

sub _cf_params {
    my $self = shift;
    my $file = shift;

    return (
        file => $file,
        $self->_stored_params_from_file($file),
        $self->_cli_params,
    );
}

sub _stored_params_from_file {
    my $self = shift;
    my $file = shift;

    return unless $file->exists;

    return
        unless my ($yaml)
        = $file->slurp_utf8
        =~ /### __app_cisetup__\r?\n(.+)### __app_cisetup__/s;

    $yaml =~ s/^# //mg;

    return %{ Load($yaml) || {} };
}

sub _build_config_file_iterator {
    my $self = shift;

    my $rule = Path::Iterator::Rule->new;
    $rule->file->name( $self->_config_filename );

    $rule->and(
        sub {
            my $path = path(shift);

            return unless -e $path->parent->child('.git');
            my $pushed = pushd( $path->parent );

## no critic (Modules::RequireExplicitInclusion, Subroutines::ProhibitCallsToUnexportedSubs)
            # XXX - make this configurable?
            # my @origin = git::remote(qw( show -n origin ));
            #            return unless grep {m{Push +URL: .+(:|/)maxmind/}} @origin;

            return 1;
        }
    );

    return $rule->iter( $self->dir );
}

1;
