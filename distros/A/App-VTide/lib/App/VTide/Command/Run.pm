package App::VTide::Command::Run;

# Created on: 2016-01-30 15:06:40
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use Hash::Merge::Simple qw/ merge /;
use Path::Tiny;
use File::stat;
use File::chdir;
use IO::Prompt qw/prompt/;

extends 'App::VTide::Command';

our $VERSION = version->new('0.1.9');
our $NAME    = 'run';
our $OPTIONS = [
    'name|n=s',
    'test|T!',
    'verbose|v+',
];
sub details_sub { return ( $NAME, $OPTIONS )};

has first => (
    is      => 'rw',
    default => 1,
);

sub run {
    my ($self) = @_;

    my ( $name ) = $self->session_dir($self->defaults->{name});
    my $cmd = $self->options->files->[0] || '';
    print "Running $name - $cmd\n";
    $ENV{VTIDE_TERM} = $cmd;

    my $params = $self->params( $cmd );
    my @cmd    = $self->command( $params );

    @ARGV = ();
    if ( !( $self->first && $params->{watch} && $params->{wait} ) ) {

        if ( $params->{heading} ) {
            # show terminal heading if desired
            print $params->{heading}, "\n";
        }

        if ( ! $self->defaults->{test} && $params->{wait} ) {
            print join ' ', @cmd, "\n";
            print "Press enter to start : ";
            my $ans = <ARGV>;
            if (!$ans || !ord $ans) {
                print "\n";
                return;
            }
        }

        $self->load_env( $params->{env} );
        local $CWD = $CWD;
        if ( $params->{dir} ) {
            $CWD = $params->{dir};
        }

        if ( $self->defaults->{verbose} || $self->defaults->{test} ) {
            warn "Will wait before starting\n" if $params->{wait};
            warn "Will restart on exit\n" if $params->{restart};
        }

        # run any hooks for run_running
        $self->hooks->run('run_running', \@cmd);

        # start the terminal
        $self->runit( @cmd );
    }

    # flag this is no longer the first run
    $self->first(0);

    if ( ! $self->defaults->{test} && $self->restart($cmd) ) {
        return $self->run;
    }

    return;
}

sub restart {
    my ($self, $cmd, $no_watch) = @_;

    my $params = $self->params( $cmd );

    return $self->watch($cmd) if !$no_watch && $params->{watch};

    return if ! $params->{restart};

    my %action = (
        q => {
            msg  => 'quit',
            exec => sub { 0; },
        },
        r => {
            msg  => 'restart',
            exec => sub { 1 },
        },
    );

    if ($params->{restart} ne 1) {
        my ($letter) = $params->{restart} =~ /^(.)/xms;
        $action{$letter} = {
            msg  => $params->{restart},
            exec => sub { exec $params->{restart}; },
        };
    }

    # show restart menu
    my $menu = "Options:\n";
    for my $letter (sort keys %action) {
        $menu .= "$letter - $action{$letter}{msg}\n";
    }
    print $menu;

    # get answer
    my $answer = <ARGV>;

    return if !$answer;

    chomp $answer if $answer;
    $answer ||= $params->{default} || '';

    # ask the question
    while ( ! $action{$answer} ) {
        print $menu;
        print "Please choose one of " . (join ', ', sort keys %action) . "\n";
        $answer = <ARGV>;
        chomp $answer if $answer;
        $answer ||= $params->{default} || '';
    }

    return $action{$answer}{exec}->();
}

sub watch {
    my ($self, $cmd) = @_;

    my $params = $self->params( $cmd );
    my @files  = $self->command(
        {
            editor => { command => undef },
            edit   => $params->{watch},
        },
    );

    my %stats;
    for my $file (@files) {
        next if !$file || !-f $file;
        $stats{$file} = stat $file;
    }

    while (1) {
        my $done = 0;
        local $SIG{INT} = sub { $done = $self->restart($cmd, 1); };

        sleep 1;

        for my $file (@files) {

            # return if interrupted
            return 1 if $done;
            # return if asked to quit
            return if !defined $done;

            next if !$file || !-f $file;
            my $stat = stat $file;
            return 1 if $stats{$file}->mtime ne $stat->mtime;
        }
    }

    return;
}

sub params {
    my ( $self, $cmd ) = @_;

    my $config = $self->config->get;
    my $params = $config->{terminals}{$cmd} || {};

    if ( ref $params eq 'ARRAY' ) {
        $params = { command => @{ $params } ? $params : '' };
    }

    if ( ! $params->{command} && ! $params->{edit} ) {
        $params->{command} = 'bash';
        $params->{wait} = 0;
    }

    return merge $config->{default} || {}, $params;
}

sub command_param {
    my ( $self, $param ) = @_;

    my ($user_param) = $param =~ /^[{]:(\w+):[}]$/;

    return $param if ! $user_param;

    my $value = prompt "$user_param : ";
    chomp $value;

    return $value;
}

sub command {
    my ( $self, $params ) = @_;

    if ( ! $params->{edit} ) {
        return ref $params->{command}
            ? map {$self->command_param($_)} @{ $params->{command} }
            : ( $params->{command} );
    }

    my $editor = ref $params->{editor}{command}
        ? $params->{editor}{command}
        : $self->config->get->{editor}{command};

    my @globs = ref $params->{edit} ? @{ $params->{edit} } : ( $params->{edit} );

    eval { require Term::Title; }
        and Term::Title::set_titlebar($params->{title} || $globs[0]);

    my $helper = $self->config->get->{editor}{helper};
    eval {
        if ($helper) {
            $helper = eval $helper;  ## no critic
        }
        1;
    } or do { warn $@ };

    my $groups = $self->config->get->{editor}{files};
    my @files = $self->_globs2files($groups, $helper, @globs);

    return ( @$editor, @files );
}

sub _globs2files {
    my ($self, $groups, $helper, @globs) = @_;
    my @files;

    GLOB:
    while ( my $glob = shift @globs ) {
        my ($not_glob) = $glob =~ /^[!](.*)$/;

        if ( $not_glob ) {
            my %not_files = map { $_ => 1 }
                $self->_globs2files($groups, $helper, $not_glob);
            @files = grep { ! $not_files{$_} } @files;
            next GLOB;
        }
        elsif ( $groups->{$glob} ) {
            unshift @globs, @{ $groups->{$glob} };
            next GLOB;
        }
        elsif ( $helper ) {
            my @g;
            eval {
                @g = $helper->($self, $glob);
                1;
            } or do { warn $@ };

            if (@g) {
                unshift @globs, @g;
                next GLOB;
            }
        }

        push @files, $self->_dglob($glob);
    }

    return @files;
}

sub _shell_quote {
    my ($file) = @_;
    $file =~ s/([\s&;*'"])/\\$1/gxms;
    return $file;
}

sub load_env {
    my ($self, $env_extra) = @_;
    if ( $env_extra && ref $env_extra eq 'HASH' ) {
        for my $env ( keys %{ $env_extra } ) {
            my $orig = $ENV{$env};
            $ENV{$env} = $env_extra->{$env};
            $ENV{$env} =~ s/[\$]$env/$orig/xms;
        }
    }

    return;
}

sub runit {
    my ( $self, @cmd ) = @_;

    print +(join " \\\n  ", @cmd), "\n" if $self->defaults->{test} || $self->defaults->{verbose};

    return if $self->defaults->{test};

    if ( @cmd > 1 ) {
        my $found = 0;
        for my $dir ( split /:/xms, $ENV{PATH} ) {
            if ( -d $dir && -x path $dir, $cmd[0] ) {
                $found = 1;
                last;
            }
        }

        if ( ! $found ) {
            @cmd = ( join ' ', @cmd );
        }
    }

    return system @cmd;
}

sub auto_complete {
    my ($self) = @_;

    my $env = $self->options->files->[-1];
    my @files = sort keys %{ $self->config->get->{terminals} };

    print join ' ', grep { $env ne 'run' ? /^$env/xms : 1 } @files;

    return;
}

1;

__END__

=head1 NAME

App::VTide::Command::Run - Run a terminal command

=head1 VERSION

This documentation refers to App::VTide::Command::Run version 0.1.9

=head1 SYNOPSIS

    vtide run [(-n|--name) project] [--test] terminal
    vtide run [--help|--man]

  OPTIONS:
   -n --name[=]str  The name of the terminal to run
   -T --test        Test the running of the terminal (shows the commands
                    that would be executed)
   -v --verbose     Show more verbose output.
      --help        Show this help
      --man         Show full documentation

=head1 DESCRIPTION

The C<run> command runs a terminal with what ever is configured for that
terminal. A full description of the terminal configuration can be found in
L<App::VTide::Configuration/terminals>.

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Runs the terminal command

=head2 C<restart ( $cmd )>

Checks if the terminal command should be restarted on exit (and asks if it should)

=head2 C<params ( $cmd )>

Gets the configuration for the command C<$cmd>

=head2 C<command ( $params )>

Gets the command to execute, either a simple command or an "editor" command
where the files are got from the groups

=head2 C<command_param ( $params )>

Processes any found user parameters

=head2 C<_shell_quote ( $file )>

Quote C<$file> for shell execution

=head2 C<load_env ( %env )>

Put the values of %env into the %ENV variable.

=head2 C<runit ( @cmd )>

Executes a command (with --test skipping)

=head2 C<watch ( $cmd )>

Watches files till they change then returns.

=head2 C<auto_complete ()>

Auto completes terminal names

=head2 C<details_sub ()>

Returns the commands details.

=head1 ATTRIBUTES

=head2 first

Track first run vs later runs (for things like waiting)

=head1 HOOKS

=head2 C<run_running ($cmd)>

Called just before execution, the command that will be executed is
passed and can be modified.

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
