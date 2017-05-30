package App::CISetup::AppVeyor::ConfigUpdater;

use strict;
use warnings;
use namespace::autoclean;
use autodie qw( :all );

our $VERSION = '0.02';

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

with(
    'App::CISetup::Role::ConfigFileFinder' => {
        filename => 'appveyor.yml',
    },
    'MooseX::Getopt::Dashes',
);

sub run {
    my $self = shift;

    return $self->create
        ? $self->_create_file
        : $self->_update_files;
}

sub _create_file {
    my $self = shift;

    my $file = $self->dir->child('appveyor.yml');
    App::CISetup::AppVeyor::ConfigFile->new( $self->_cf_params($file) )
        ->create_file;

    print "Created $file\n" or die $!;

    return 0;
}

sub _update_files {
    my $self = shift;

    my $iter = $self->_config_file_iterator;

    my $count = 0;
    while ( my $file = $iter->() ) {
        $count++;
        my $updated = try {
            App::CISetup::AppVeyor::ConfigFile->new(
                $self->_cf_params($file) )->update_file;
        }
        catch {
            print "\n\n\n" . $file . "\n" or die $!;
            print $_ or die $!;
        };

        next unless $updated;

        print "Updated $file\n" or die $!;
    }

    warn "WARNING: No appveyor.yml files found\n"
        unless $count;

    return 0;
}

sub _cf_params {
    my $self = shift;
    my $file = shift;

    return (
        file => $file,
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

__PACKAGE__->meta->make_immutable;

1;
