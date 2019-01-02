package App::Devmode2;

# Created on: 2014-10-04 20:31:39
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use English qw/ -no_match_vars /;
use Getopt::Long;
use FindBin qw/$Bin/;
use Path::Tiny;
use base qw/Exporter/;

our $VERSION = 0.9;
our ($name)  = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our $tmux_conf    = path("$ENV{HOME}", '.tmux.conf');
our $tmux_layout  = path("$ENV{HOME}", '.tmux', 'layout');
our $tmux_devmode = path("$ENV{HOME}", '.tmux', 'devmode2');
our %option;
our %p2u_extra;

sub run {
    my ($self) = @_;
    Getopt::Long::Configure('bundling');
    my $success = GetOptions(
        \%option,
        'layout|l=s',
        'chdir|cd|c=s',
        'curdir|C',
        'save|s',
        'auto|auto-complete',
        'current=s',
        'test|t!',
        'verbose|v+',
        'man',
        'help',
        'version!',
    );

    if ( !$success && !$option{auto} ) {
        require Pod::Usage;
        Pod::Usage::pod2usage(
            -verbose => 1,
            -input   => __FILE__,
            %p2u_extra,
        );
        return 1;
    }
    elsif ( $option{'VERSION'} ) {
        print "$name Version = $VERSION\n";
        return 0;
    }
    elsif ( $option{'man'} ) {
        require Pod::Usage;
        Pod::Usage::pod2usage(
            -verbose => 2,
            -input   => __FILE__,
            %p2u_extra,
        );
        return 2;
    }
    elsif ( $option{'help'} ) {
        require Pod::Usage;
        Pod::Usage::pod2usage(
            -verbose => 1,
            -input   => __FILE__,
            %p2u_extra,
        );
        return 1;
    }
    elsif ( $option{auto} ) {
        $self->_auto();
        return 0;
    }

    # get the session name
    my $session  = @ARGV ? shift @ARGV : die "No session name passed!";
    my @sessions = $self->sessions();

    # set the terminal title to the session name
    $self->set_title($session);

    if ( grep { $_ eq $session } @sessions ) {
        # connect to session
        $self->_exec('tmux', '-u2', 'attach', '-t', $session);
        return 1;
    }

    # creating a new session should do some extra work
    $self->process_config($session, \%option);

    if ($option{chdir}) {
        die "No directory '$option{chdir}'!\n" if !-d $option{chdir};
        chdir $option{chdir};
    }

    my @actions = ('-u2', 'new-session', '-s', $session, ';', 'source-file', $tmux_conf);
    if ($option{layout}) {
        push @actions, ';', "source-file", $tmux_layout->child($option{layout});
    }

    $self->_exec('tmux', @actions);
    warn "Not found\n";

    return 1;
}

sub set_title {
    my ($self, $session) = @_;
    eval { require Term::Title; } or return;
    Term::Title::set_titlebar($session);
    return;
}

sub sessions {
    my $self = shift;
    return map {
            /^(.+) : \s+ \d+ \s+ window/xms;
            $1;
        }
        $self->_qx('tmux ls');
}

sub process_config {
    my ($self, $session, $option) = @_;
    my $config_file = $tmux_devmode->child($session);

    # return if no config and not saving
    return if !-f $config_file && !$option->{save};

    if ( -f $config_file ) {
        require YAML;
        my ($config) = YAML::LoadFile("$config_file");
        for my $key (keys %{ $config }) {
            $option->{$key} = $config->{$key} if !exists $option->{$key};
        }
    }

    # save the config if requested to
    if ($option->{save} || $option{curdir}) {
        # create the path if missing
        $config_file->parent->mkpath();

        # don't save saving
        delete $option->{save};

        if ($option{curdir}) {
            delete $option->{curdir};
            $option->{chdir} = path('.')->realpath . '';
        }

        # save the config to YAML
        require YAML;
        YAML::DumpFile("$config_file", $option);
    }

    return;
}

sub _qx {
    my $self = shift;
    return qx/@_/;
}

sub _exec {
    my $self = shift;
    print join ' ', @_, "\n" if $option{verbose};
    exec @_ if !$option{test};
    return;
}

sub _auto {
    my ($self) = @_;
    my $current  = $ARGV[$option{current}];
    my $previous = $ARGV[$option{current} - 1];

    if ( defined $current && $current =~ /^-/ ) {
        print join "\n", qw/-l --layout -s --save -c --cd -C --curdir/, '';
    }
    elsif ( $previous =~ /^-c$|^--(?:chdir|cd)$/ ) {
        print join "\n", glob "$current*";
    }
    else {
        my $dir = $previous =~ /^-\w*l$|^--layout$/ ? $tmux_layout : $tmux_devmode;
        my @found = sort {
                lc $a cmp lc $b
            }
            grep {
                !$current || /^$current/i
            }
            map {
                m{/([^/]+)$}; $1
            }
            $dir->children;
        print join "\n", @found, '';
    }
}

1;

__END__

=head1 NAME

App::Devmode2 - A tmux session loading tool

=head1 VERSION

This documentation refers to App::Devmode2 version 0.9

=head1 SYNOPSIS

    devmode2 [options] <session>

  OPTIONS:
   <session>    A tmux session name to create or connect to
   -l --layout[=]str
                A layout to load if creating a new session
   -s --save    Save the current config to the session file
   -c --cd[=]dir
                Change to dir before running tmux
   -C --curdir  Saves the current director as the directory to change to
                when next loaded. (implies --save)

   -t --test    Don't run any external command (eg tmux)
   -v --verbose Show more verbose output
      --man     Show full help documentation
      --help    Show this
      --version Show the version of devmode2

=head1 DESCRIPTION

C<devmode2> is a helper script for L<tmux> to simplify the creation and
management of sessions.

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Manage the logic to load sessions etc.

=head2 C<set_title ()>

Tries to set the terminal title to the session name (requires L<Term::Title>
to work).

=head2 C<sessions ()>

Gets a list of current tmux sessions.

=head2 C<process_config ($session, $option)>

Reads any config for C<$session> (from ~/.tmux/devmode2/$session) and
optionally saves that config.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

Bash auto completion helper (add to your C<~/.bashrc> file:

    _devmode2() {
        COMPREPLY=($(devmode2 --auto --current "${COMP_CWORD}" -- ${COMP_WORDS[@]}))
    }
    complete -F _devmode2 devmode2

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
