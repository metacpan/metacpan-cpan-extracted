package App::WithSound;

use warnings;
use strict;
our $VERSION = '1.2.1';

use Carp;
use Config::Simple;
use File::Path::Expand;
use File::Which;
use File::Spec::Functions qw/devnull/;
use IPC::Open3;

our $SIGTERM = 15;

sub new {
    my ( $class, $config_file_path, $env ) = @_;
    bless {
        config_file_path   => $config_file_path,
        env                => $env,
        success_sound_path => undef,
        failure_sound_path => undef,
        running_sound_path => undef,
        sound_player       => undef,
    }, $class;
}

sub run {
    my ( $self, @argv ) = @_;
    unless (@argv) {
        croak 'Usage: $ with-sound [command] ([argument(s)])' . "\n";
    }

    $self->_init( $argv[0] );

    my $retval = $self->_execute_command(@argv);
    $retval = 1 if $retval > 255;

    $self->_play_sound($retval);
    return $retval;
}

sub _init {
    my ( $self, $command ) = @_;

    $self->_load_sound_paths($command);
    $self->_detect_sound_play_command;

    return $self;
}

sub _execute_command {
    my ( $self, @argv ) = @_;

    my $pid    = $self->_play_sound;
    my $retval = system(@argv);
    kill( $SIGTERM, $pid ) if $pid;

    return $retval;
}

sub _detect_sound_play_command {
    my ($self) = @_;

    my $player;
    $player ||= which('mpg123');
    $player ||= which('mpg321');
    $player ||= which('afplay');

    $self->{sound_player} = $player;
    return $self;
}

sub _load_sound_paths_from_env {
    my ($self) = @_;

    my %deprecated_envs = (
        WITH_SOUND_SUCCESS => "success_sound_path",
        WITH_SOUND_FAILURE => "failure_sound_path",
        WITH_SOUND_RUNNING => "running_sound_path",
    );
    for my $env_name ( sort keys %deprecated_envs ) {
        if ( my $sound_file_path = $self->{env}->{$env_name} ) {
            carp
qq{[WARNING] "$env_name" is deprecated. Please use "PERL_$env_name"\n};
            $self->{ $deprecated_envs{$env_name} } =
              expand_filename($sound_file_path);
        }
    }

    my %envs = (
        PERL_WITH_SOUND_SUCCESS => "success_sound_path",
        PERL_WITH_SOUND_FAILURE => "failure_sound_path",
        PERL_WITH_SOUND_RUNNING => "running_sound_path",
    );
    for my $env_name ( sort keys %envs ) {
        if ( my $sound_file_path = $self->{env}->{$env_name} ) {
            $self->{ $envs{$env_name} } = expand_filename($sound_file_path);
        }
    }

    $self;
}

sub _load_sound_paths_from_config {
    my ( $self, $command ) = @_;

    $command ||= '';

    # Not exists config file.
    unless ( -f $self->{config_file_path} ) {
        carp
          "[WARNNING] Please put config file in '$self->{config_file_path}'\n";
        return;
    }
    my %config;
    eval { Config::Simple->import_from( $self->{config_file_path}, \%config ) };
    print STDERR "Configuration file has some errors."
      . "Please check your '.withsound-rc' file.\n"
      . "(Didn't you write plural format in configuration file?)\n"
      if $@;

    $self->{success_sound_path} =
      expand_filename( $config{"$command.SUCCESS"}
          || $config{'default.SUCCESS'}
          || $config{'SUCCESS'} );
    $self->{failure_sound_path} =
      expand_filename( $config{"$command.FAILURE"}
          || $config{'default.FAILURE'}
          || $config{'FAILURE'} );
    $self->{running_sound_path} =
      expand_filename( $config{"$command.RUNNING"}
          || $config{'default.RUNNING'}
          || $config{'RUNNING'} );
    $self;
}

sub _load_sound_paths {
    my ( $self, $command ) = @_;
    $self->_load_sound_paths_from_config($command);

    # load from env after config so environment variables are prior to config
    $self->_load_sound_paths_from_env;
    $self;
}

sub _play_mp3_in_child {
    my ( $self, $play_command, $mp3_file_path ) = @_;

    my ( $devnull, $pid );
    unless ( open( $devnull, '>', devnull ) ) {
        carp "[WARNING] Couldn't open devnull : $!";
        return;
    }
    eval {
        my $wtr;
        $pid = open3( $wtr, '>&' . fileno($devnull),
            0, $play_command, $mp3_file_path, );
        close $wtr;
    };
    carp "[WARNING] Couldn't exec $play_command in sound process: $@" if $@;
    return $pid;
}

sub _play_mp3 {
    my ( $self, $mp3_file_path, $status ) = @_;

    return unless $mp3_file_path;

    # not exists mp3 file
    unless ( -f $mp3_file_path ) {
        carp "[WARNING] Sound file not found for $status. : $mp3_file_path";
        return;
    }

    my $play_command = $self->{sound_player};
    unless ($play_command) {
        carp "[WARNING] No sound player is installed."
          . "please install mpg123 or mpg321";
        return;
    }

    $self->_play_mp3_in_child( $play_command, $mp3_file_path );
}

sub _play_sound {
    my ( $self, $command_retval ) = @_;

    my $pid;
    if ( !defined($command_retval) ) {

        # running
        $pid = $self->_play_mp3( $self->{running_sound_path}, 'running' );
    }
    elsif ( $command_retval == 0 ) {

        # success
        $pid = $self->_play_mp3( $self->{success_sound_path}, 'success' );
    }
    else {
        # failure
        $pid = $self->_play_mp3( $self->{failure_sound_path}, 'failure' );
    }
    return $pid;
}

1;
__END__

=encoding utf8

=head1 NAME

App::WithSound - Execute commands with sound


=head1 VERSION

This document describes App::WithSound version 1.2.1


=head1 DESCRIPTION

This module contains utilities for L<<with-sound>>.


=head1 DEPENDENCIES

Config::Simple (version 4.58 or later)

File::Path::Expand (version 1.02 or later)

File::Which (version 1.09 or later)

Test::Warn (version 0.24 or later)

Test::MockObject::Extends (version 1.20120301 or later)


=head1 AUTHOR

moznion  C<< <moznion@gmail.com> >>

Shinpei Maruyama C<< shinpeim[at]gmail.com> >>


=head1 CONTRIBUTOR

Syohei YOSHIDA C<< <syohex[at]gmail.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, moznion C<< <moznion@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
