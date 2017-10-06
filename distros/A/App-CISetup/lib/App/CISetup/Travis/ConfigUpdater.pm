package App::CISetup::Travis::ConfigUpdater;

use strict;
use warnings;
use namespace::autoclean;
use autodie qw( :all );

our $VERSION = '0.10';

use App::CISetup::Travis::ConfigFile;
use App::CISetup::Types qw( Bool Str );
use Try::Tiny;

use Moose;
use MooseX::StrictConstructor;

has email_address => (
    is        => 'ro',
    isa       => Str,                   # todo, better type
    predicate => 'has_email_address',
);

has force_threaded_perls => (
    is        => 'ro',
    isa       => Bool,
    predicate => 'has_force_threaded_perls',
);

has perl_caching => (
    is        => 'ro',
    isa       => Bool,
    predicate => 'has_perl_caching',
);

has github_user => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_github_user',
);

has slack_key => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_slack_key',
);

with 'App::CISetup::Role::ConfigUpdater';

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _config_filename {'.travis.yml'}

sub _config_file_class {'App::CISetup::Travis::ConfigFile'}

sub _cli_params {
    my $self = shift;

    return (
        ## no critic (BuiltinFunctions::ProhibitComplexMappings)
        map { my $p = 'has_' . $_; $self->$p ? ( $_ => $self->$_ ) : () } qw(
            force_threaded_perls
            perl_caching
            email_address
            github_user
            slack_key
            )
    );
}
## use critic

__PACKAGE__->meta->make_immutable;

1;
