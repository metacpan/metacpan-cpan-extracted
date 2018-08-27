package App::CISetup::AppVeyor::ConfigUpdater;

use strict;
use warnings;
use namespace::autoclean;
use autodie qw( :all );

our $VERSION = '0.14';

use App::CISetup::AppVeyor::ConfigFile;
use App::CISetup::Types qw( Bool Str );
use Try::Tiny;

use Moose;

has email_address => (
    is        => 'ro',
    isa       => Str,                   # todo, better type
    predicate => 'has_email_address',
);

has encrypted_slack_key => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_encrypted_slack_key',
);

with 'App::CISetup::Role::ConfigUpdater';

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _config_filename {'appveyor.yml'}

sub _config_file_class {'App::CISetup::AppVeyor::ConfigFile'}

sub _cli_params {
    my $self = shift;

    return (
        (
            $self->has_email_address
            ? ( email_address => $self->email_address )
            : ()
        ),
        (
            $self->has_encrypted_slack_key
            ? ( encrypted_slack_key => $self->encrypted_slack_key )
            : ()
        ),
    );
}
## use critic

__PACKAGE__->meta->make_immutable;

1;
