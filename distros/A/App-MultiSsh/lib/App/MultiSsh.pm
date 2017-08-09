package App::MultiSsh;

# Created on: 2014-09-04 17:12:36
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use feature qw/:5.10/;
use Carp;
use POSIX qw/ceil/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use base qw/Exporter/;
use Path::Tiny;
use IO::Handle;
use POSIX qw/:errno_h/;

our $VERSION     = '0.20';
our @EXPORT_OK   = qw/hosts_from_map is_host multi_run shell_quote tmux/;
our %EXPORT_TAGS = ();

sub hosts_from_map {
    my ($map) = @_;
    my @hosts;

    my $int_re       = qr/ [0-9a-zA-Z] /xms;
    my $range_re     = qr/ ($int_re) (?:[.][.]|-) ($int_re)/xms;
    my $group_re     = qr/ (?: $int_re | $range_re )       /xms;
    my $seperated_re = qr/ $group_re (?: , $group_re )  *  /xms;
    my $num_range_re = qr/ [[{] ( $seperated_re ) [\]}]    /xms;

    while ( my $host_range = shift @{$map} ) {
        my ($num_range) = $host_range =~ /$num_range_re/;

        if (!$num_range) {
            push @hosts, $host_range;
            next;
            #if ( is_host($host_range) ) {
            #    push @hosts, $host_range;
            #    next;
            #}
            #else {
            #    unshift @{$hosts}, $host_range;
            #    last;
            #}
        }

        my @numbs    = map { /$range_re/ ? ($1 .. $2) : ($_) } split /,/, $num_range;
        my @hostmaps = map { $a=$host_range; $a =~ s/$num_range_re/$_/e; $a } @numbs;

        if ( $hostmaps[0] =~ /$num_range_re/ ) {
            push @{$map}, @hostmaps;
        }
        else {
            push @hosts, @hostmaps;
        }
    }

    return @hosts;
}

sub is_host {
    my $full_name = `host $_[0]`;
    return $full_name !~ /not found/;
}

sub shell_quote {
    my ($text) = @_;

    if ($text =~ /[\s$|><;&*?#]/xms) {
        $text =~ s/'/'\\''/gxms;
        $text = "'$text'";
    }

    return $text;
}

sub multi_run {
    my ($hosts, $remote_cmd, $option) = @_;

    if ($option->{tmux}) {
        my @cmds = map {"ssh $_ " . shell_quote($remote_cmd)} @$hosts;
        exec tmux($option, @cmds) if !$option->{test};
        print tmux($option, @cmds) . "\n";
        return;
    }

    # store child processes if forking
    my @children;

    # loop over each host and run the remote command
    for my $host (@$hosts) {
        my $cmd = "ssh $host " . shell_quote($remote_cmd);
        print "$cmd\n" if $option->{verbose} > 1 || $option->{test};
        next if $option->{test};

        if ( $option->{parallel} ) {
            my $child = fork;

            if ( $child ) {
                # parent stuff
                push @children, $child;

                if ( @children == $option->{parallel} ) {
                    warn "Waiting for children to finish\n" if $option->{verbose} > 1;
                    # reap children if reached max fork count
                    while ( my $pid = shift @children ) {
                        waitpid $pid, 0;
                    }
                }
            }
            elsif ( defined $child ) {
                # child code
                if ( $option->{interleave} ) {
                    print "$host -\n" if $option->{verbose};

                    require IPC::Open3::Callback;
                    my ($pid, $in, $out, $err) = IPC::Open3::Callback::safe_open3($cmd);

                    close $in;
                    $out->blocking(0);
                    $err->blocking(0);
                    while ($out && $err) {
                        $out = _read_label_line($out, \*STDOUT, $host);
                        $err = _read_label_line($err, \*STDERR, $host);
                    }
                    waitpid $pid, 0;
                    exit 0;
                }
                else {
                    my $out = `$cmd 2>&1`;

                    print "$host -\n" if $option->{verbose};
                    print $out;
                }
                exit;
            }
            else {
                die "Error: $!\n";
            }
        }
        else {
            print "$host -\n" if $option->{verbose};
            system $cmd;
        }
    }

    # reap any outstanding children
    wait;
}

sub _read_label_line {
    my ($in_fh, $out_fh, $host) = @_;
    state %hosts;
    my @colours = (qw/
        red     on_red     bright_red
        green   on_green   bright_green
        blue    on_blue    bright_blue
        magenta on_magenta bright_magenta
        cyan    on_cyan
        yellow  on_yellow
    /);
    return if !$in_fh;

    my $line = <$in_fh>;

    if ( !defined $line && $! != EAGAIN ) {
        close $in_fh;
        return;
    }

    if (defined $line) {
        $hosts{$host} ||= $colours[rand @colours];
        require Term::ANSIColor;
        print {$out_fh} '[', Term::ANSIColor::colored($host, $hosts{$host}), '] ', $line;
    }

    return $in_fh;
}

sub tmux {
    my ($option, @commands) = @_;

    confess "No commands for tmux to run!\n" if !@commands;

    my $layout  = layout(@commands);
    my $tmux    = '';
    my $final = '';
    my $pct     = int( 100 / scalar @commands );

    for my $ssh (@commands) {
        if ( !$tmux && $option->{tmux_nested} ) {
            $tmux = ' rename-window mssh';
            $final = '; bash -c ' . shell_quote($ssh);
        }
        else {
            my $cmd = !$tmux ? 'new-session' : '\\; split-window -d -p ' . $pct;

            $tmux .= " $cmd " . shell_quote($ssh);
        }
    }

    $tmux .= ' \\; set-window-option synchronize-panes on' if $commands[0] !~ /\s$/xms;

    return "tmux$tmux \\; select-layout tiled \\; setw synchronize-panes$final";
}

sub layout {
    my (@commands) = @_;
    my $rows = int sqrt @commands + 1;
    my $cols = ceil @commands / $rows;
    my $out = [];
    if ( $cols > $rows + 1 ) {
        my $tmp = $rows;
        $rows++;
        $cols--;
    }
    ROW:
    for my $row ( 0 .. $rows - 1 ) {
        for my $col ( 0 .. $cols - 1 ) {
            last ROW if !@commands;
            $out->[$row][$col] = shift @commands;
        }
    }

    return $out;
}

sub config {
    state $config;
    return $config if $config;

    my $config_file = path($ENV{HOME}, '.mssh');
    if (!-f $config_file) {
        $config = {};

        # create a default config file
        $config_file->spew("---\ngroups:\n");

        return $config;
    }

    require YAML;
    $config = YAML::LoadFile($config_file);

    return $config;
}

sub get_groups {
    my ($groups) = @_;
    my $config = config();
    my @hosts;

    for my $group (@$groups) {
        if ($config->{groups} && $config->{groups}{$group}) {
            push @hosts,
                ref $config->{groups}{$group}
                ? @{ $config->{groups}{$group} }
                : $config->{groups}{$group};
        }
        else {
            warn "No host group '$group' defined in the config!\n";
        }
    }

    return @hosts;
}

1;

__END__

=head1 NAME

App::MultiSsh - Multi host ssh executer

=head1 VERSION

This documentation refers to App::MultiSsh version 0.20

=head1 SYNOPSIS

   use App::MultiSsh;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=over 4

=item C<hosts_from_map ($host)>

Splits C<$host> into all hosts that it represents.

e.g.

  host0[012] -> host00, host01, host02
  host0[0-2] -> host00, host01, host02

=item C<is_host ($host)>

Gets the full name of C<$host>

=item C<shell_quote ($text)>

Quotes C<$text> for putting into a shell command

=item C<multi_run ($hosts, $remote_cmd, $option)>

Run the command on all hosts

=item C<tmux (@commands)>

Generate a tmux session with all commands run in separate windows

=item C<layout (@commands)>

Generate a desired tmux layout

=item C<config ()>

Read the ~/.mssh config file and return it's data

=item C<get_groups (@groups)>

Return all hosts represented in C<@groups>

=back

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

Copyright (c) 2014 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
