package App::CISetup::Role::ConfigFileFinder;

use strict;
use warnings;
use namespace::autoclean;
use autodie qw( :all );

our $VERSION = '0.02';

use File::pushd qw( pushd );
use Git::Sub qw( remote );
use App::CISetup::Travis::ConfigFile;
use App::CISetup::Types qw( Bool CodeRef Dir Str );
use Path::Iterator::Rule;
use Path::Tiny qw( path );

use MooseX::Role::Parameterized;

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

parameter filename => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

role {
    my $p = shift;
    method( _filename => sub { $p->filename } );
};

sub _build_config_file_iterator {
    my $self = shift;

    my $rule = Path::Iterator::Rule->new;
    $rule->file->name( $self->_filename );

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
