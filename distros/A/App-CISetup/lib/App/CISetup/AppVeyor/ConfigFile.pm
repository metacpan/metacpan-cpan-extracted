package App::CISetup::AppVeyor::ConfigFile;

use strict;
use warnings;
use namespace::autoclean;
use autodie qw( :all );

our $VERSION = '0.14';

use App::CISetup::Types qw( Str );

use Moose;

has email_address => (
    is        => 'ro',
    isa       => Str,                   # todo, better type
    predicate => 'has_email_address',
);

has slack_channel => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_slack_channel',
);

has encrypted_slack_key => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_encrypted_slack_key',
);

with 'App::CISetup::Role::ConfigFile';

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _create_config {
    my $self = shift;

    return $self->_update_config(
        {
            skip_tags => 'true',
            cache     => ['C:\strawberry'],
            install   => [
                'if not exist "C:\strawberry" cinst strawberryperl -y',
                'set PATH=C:\strawberry\perl\bin;C:\strawberry\perl\site\bin;C:\strawberry\c\bin;%PATH%',
                'cd %APPVEYOR_BUILD_FOLDER%',
                'cpanm --installdeps . -n',
            ],
            build_script => ['perl -e 1'],
            test_script  => ['prove -lrvm t/'],
        }
    );
}

sub _update_config {
    my $self     = shift;
    my $appveyor = shift;

    $self->_update_notifications($appveyor);

    return $appveyor;
}
## use critic

sub _update_notifications {
    my $self     = shift;
    my $appveyor = shift;

    my @notifications;
    push @notifications, {
        provider   => 'Slack',
        auth_token => {
            secure => $self->encrypted_slack_key,
        },
        channel                 => $self->slack_channel,
        on_build_failure        => 'true',
        on_build_status_changed => 'true',
        on_build_success        => 'true',
    } if $self->has_encrypted_slack_key && $self->has_slack_channel;

    push @notifications, {
        provider                => 'Email',
        subject                 => 'AppVeyor build {{status}}',
        to                      => [ $self->email_address ],
        on_build_failure        => 'true',
        on_build_status_changed => 'true',
        on_build_success        => 'false',
    } if $self->has_email_address;

    $appveyor->{notifications} = \@notifications
        if @notifications;

    return;
}

my @BlocksOrder = qw(
    version
    skip_tags
    init
    environment
    matrix
    cache
    services
    install
    before_build
    build_script
    after_build
    before_test
    test_script
    after_test
    artifacts
    on_success
    on_failure
    on_finish
    notifications
);

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _fix_up_yaml {
    my $self = shift;
    my $yaml = shift;

    $yaml = $self->_reorder_yaml_blocks( $yaml, \@BlocksOrder );

    return $yaml;
}

sub _cisetup_flags {
    my $self = shift;

    my %flags;
    $flags{email_address} = $self->email_address
        if $self->has_email_address;

    $flags{slack_channel} = $self->slack_channel
        if $self->has_slack_channel;

    return \%flags;
}
## use critic

__PACKAGE__->meta->make_immutable;

1;
