package App::VTide::Command::Start;

# Created on: 2016-01-30 15:06:48
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use File::chdir;
use Path::Tiny;
use YAML::Syck;

extends 'App::VTide::Command';

our $VERSION = version->new('0.1.6');
our $NAME    = 'start';
our $OPTIONS = [
    'windows|w=i',
    'test|T!',
    'verbose|v+',
];
sub details_sub { return ( $NAME, $OPTIONS )};

sub run {
    my ($self) = @_;

    my ( $name, $dir ) = $self->session_dir(
        $self->options->files->[0]
    );

    local $CWD = $dir;

    $self->save_session( $name, $dir );

    $self->hooks->run('start_pre', $name, $dir);

    $self->ctags();

    return $self->tmux( $self->vtide->config->data->{title} || $name );
}

sub ctags {
    my ( $self ) = @_;
    my $ctags = path('/usr', 'bin', 'ctags');

    return if !$self->config->get->{start}{ctags} || !-x $ctags;

    my @cmd = ($ctags, $self->config->get->{start}{ctags});

    for my $exclude (@{ $self->config->get->{start}{"ctags-exclude"} }) {
        if ( $self->config->get->{start}{"ctags-excludes"}{$exclude} ) {
            push @cmd, map {"--exclude=$_"} @{ $self->config->get->{start}{"ctags-excludes"}{$exclude} };
        }
        else {
            push @cmd, "--exclude=$exclude";
        }
    }

    system @cmd;
}

sub tmux {
    my ( $self, $name ) = @_;

    eval { require Term::Title; }
        and Term::Title::set_titlebar($name);

    my %session = map {/(^[^:]+)/xms; $1 => 1} `tmux ls`;
    if ( $session{$name} ) {
        # reconnect
        exec 'tmux', 'attach-session', '-t', $name;
    }

    my $v    = $self->defaults->{verbose} ? '--verbose' : '';
    $v .= " --name $name";
    my $tmux = 'tmux -u2 ';
    my $count = $self->defaults->{windows} || $self->config->get->{count};

    for my $window ( 1 .. $count ) {
        $tmux .= $self->tmux_window($window, "vtide run $v", $name);
    }
    $tmux .= "select-window -t 1";

    if ( $self->defaults->{test} ) {
        print "$tmux\n";
        return 1;
    }

    exec $tmux;
}

sub tmux_window {
    my ( $self, $term, $cmd, $name, $split ) = @_;
    my $conf = !$term ? {} : $self->config->get->{terminals}{$term};
    my $out = $split ? ''
        : $term == 1 ? "new-session -s $name '$cmd $term' \\; "
        :              "new-window '$cmd $term' \\; ";
    my $letter = !$term ? '' : 'a';

    if ( ! $conf || ref $conf ne 'HASH' ) {
        $conf = {};
    }

    $term  ||= '';
    $split ||= $conf->{split};

    for my $split ( split //xms, ( $split || '' ) ) {
        next if ! defined $split || $split eq '';

        my $arg = $split eq 'H' ? 'split-window -h'
            : $split eq 'h'     ? 'split-window -dh'
            : $split eq 'V'     ? 'split-window -v'
            : $split eq 'v'     ? 'split-window -dv'
            : $split =~ /^\d$/x ? 'select-pane -t ' . $split
            :                     die "Unknown split for terminal $term $split (split = '$split')!\n";

         $out .= $split =~ /^\d$/xms ? "$arg \\; " : "$arg '$cmd $term$letter' \\; ";
         $letter++ if $letter;
    }

    if ( $conf->{tmux} ) {
        $out .= "$conf->{tmux} \\; ";
    }

    return $out;
}

sub auto_complete {
    my ($self) = @_;

    my $file     = $self->history;
    my $sessions = eval { LoadFile( $file ) } || {};

    my $env = $self->options->files->[-1];
    print join ' ',
        grep { $env ne 'start' ? /^$env/xms : 1 }
        sort keys %{ $sessions->{sessions} };

    return;
}

1;

__END__

=head1 NAME

App::VTide::Command::Start - Start a session

=head1 VERSION

This documentation refers to App::VTide::Command::Start version 0.1.6

=head1 SYNOPSIS

    vtide start
    vtide start name [[-w|--window] num]
    vtide start [--help|--man]

  OPTIONS:
    name
                    The project to start (If not specified the current
                    directory is used to find a .vtide.yml file to start)

    -w --windows[=]int
                    Use a different number of windows from the configured
                    number (i.e. as set is .vtide.yml)
    -T --test       Test a config (show the tmux command)
    -v --verbose    Show more details out put (passed on to run as well)
       --help       Show this help
       --man        Show full documentation

=head1 DESCRIPTION

Starts up an existing VTide project, either by name for by using the
configuration in the current directory.

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Starts the tmux session running a C<vtide run> command in each terminal

=head2 C<ctags ()>

Runs the ctags command if the config option I<ctags> in the I<start> group is set

=head2 C<tmux ( $name )>

Run a tmux session with the name C<$name>

=head2 C<tmux_window ( $name )>

Creates the C<tmux> configuration for a new window.

=head2 C<auto_complete ()>

Auto completes session names

=head2 C<details_sub ()>

Returns the commands details.

=head1 HOOKS

=head2 C<start_pre ( $name, $dir )>

This is run just before the tmux session is started, the C<$name> and the
directory (C<$dir>) of the project are passed.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

 =cut
