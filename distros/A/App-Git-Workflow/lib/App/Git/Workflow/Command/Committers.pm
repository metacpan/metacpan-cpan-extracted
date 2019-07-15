package App::Git::Workflow::Command::Committers;

# Created on: 2014-06-11 10:00:36
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use English qw/ -no_match_vars /;
use Time::Piece;
use App::Git::Workflow;
use App::Git::Workflow::Command qw/get_options/;
use utf8;

our $VERSION  = version->new(1.1.4);
our $workflow = App::Git::Workflow->new;
our ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our %option;

sub run {
    my ($self) = @_;
    %option = (
        period => 'day',
    );
    get_options(
        \%option,
        'remote|r',
        'all|a',
        'fmt|format|f=s',
        'changes|c',
        'commits|C',
        'min|min-commits|M=i',
        'since|s=s',
        'until|u=s',
        'period|p=s',
        'periods|P=i',
        'merges|m!',
    );

    my @stats;
    my $total_commits = 0;
    my $since = $option{since};

    if (!$since) {
        my $now = localtime;
        my $period
            = $option{period} eq 'day'   ? 1
            : $option{period} eq 'week'  ? 7
            : $option{period} eq 'month' ? 30
            : $option{period} eq 'year'  ? 365
            :                              die "Unknown period '$option{period}' please choose one of day, week, month or year\n";
        $since
            = $now->wday == 1 ? localtime(time - 3 * $period * 24 * 60 * 60)->ymd
            : $now->wday == 7 ? localtime(time - 2 * $period * 24 * 60 * 60)->ymd
            :                   localtime(time - 1 * $period * 24 * 60 * 60)->ymd;
    }

    my @options;
    push @options, '-r' if $option{remote};
    push @options, '-a' if $option{all};
    my @log = (
        '--format=format:%h %an',
        ($option{merges} ? () : '--no-merges'),
    );

    my $periods = $option{periods} || 1;
    while ($periods--) {
        my $commits = 0;
        my %users;
        my @dates;
        if ($option{periods}) {
            @dates = $self->dates($option{period}, $option{periods}--);
        }
        else {
            @dates = (
                "--since=$since",
                ($option{until} ? "--until=$option{until}" : ()),
            );
        }

        for my $branch ($workflow->git->branch(@options)) {
            next if $branch =~ / -> /;
            $branch =~ s/^[*]?\s*//;
            for my $log ( $workflow->git->log( @log, @dates, $branch, '--' ) ) {
                my ($hash, $name) = split /\s/, $log, 2;
                $users{$name}{$hash} = 1;
                $commits++;
            }
        }

        for my $user (keys %users) {
            my $commits = $users{$user};
            $users{$user} = {
                commit_count => scalar keys %{ $users{$user} },
                $option{commits} ? (commits => [keys %{ $users{$user} }]) : (),
                $option{changes} ? (changes => $self->changes($commits)) : (),
            };
        }
        my $dates = join ' - ',
            map {/=(.*)$/; $1}
            @dates;
        push @stats, {
            period  => $dates,
            ( %users ? (commits => $commits) : () ),
            ( %users ? (users   => \%users ) : () ),
        };
        $total_commits += $commits;
    }

    my $fmt = 'fmt_' . ($option{fmt} || 'table');
    if ($self->can($fmt)) {
        $self->$fmt(\@stats, $total_commits);
    }

    return;
}

sub dates {
    my ($self, $period, $count) = @_;

    my $now = localtime;
    $period
        = $period eq 'day'   ? 1
        : $period eq 'week'  ? 7  - $now->wdaygg
        : $period eq 'month' ? 30
        : $period eq 'year'  ? 365
        :                      die "Unknown period '$option{period}' please choose one of day, week, month or year\n";

    my $until = localtime(time - ($count - 1) * $period * 24 * 60 * 60);
    my $since
        = $until->wday == 1 ? localtime(time - 3 * $count * $period * 24 * 60 * 60)
        : $until->wday == 7 ? localtime(time - 2 * $count * $period * 24 * 60 * 60)
        :                     localtime(time - 1 * $count * $period * 24 * 60 * 60);

    return (
        "--since=" . $since->ymd,
        "--until=" . $until->ymd,
    );
}

sub changes {
    my ($self, $commits) = @_;
    my %changes = (
        lines_added   => 0,
        lines_removed => 0,
        files         => {},
        files_added   => 0,
        files_removed => 0,
    );

    for my $commit (keys %$commits) {
        # get the stats from each commit
        my @show = $workflow->git->show($commit);
        $changes{lines_added}   += grep {/^[+](?:[^+]|[+][^+]|[+][+]\s|$)/} @show;
        $changes{lines_removed} += grep {/^[-](?:[^-]|[-][^-]|[-][-]\s|$)/} @show;
        $changes{files} = {
            %{ $changes{files} || {} },
            map {/^[+]{3}\s+b\/(.*)$/; ($1 || "" => 1) }
            grep {/^[+]{3}\s/}
            @show
        };
        $changes{total}++;
    }
    $changes{files} = keys %{ $changes{files} || {} };

    return \%changes;
}

sub fmt_table {
    my ($self, $stats) = @_;
    my $fmt = "%-25s % 7d";
    my $max = 1;
    my $users = $stats->[0]{users}   || {};
    my $total = $stats->[0]{commits} || 0;

    if ($option{changes}) {
        $fmt .= " % 9d % 9d % 5d";
        my $fmt2 = $fmt;
        $fmt2 =~ s/d/s/g;
        printf "$fmt2\n", qw/Name Commits Added Removed Files/;
        $max = 4;
    }

    my @users =
        reverse sort {$users->{$a}{commit_count} <=> $users->{$b}{commit_count}}
        grep { $users->{$_}{commit_count} >= ($option{min} || 0) }
        keys %$users;

    for my $user (@users) {
        my @out = (
            $user,
            $users->{$user}{commit_count},
            $users->{$user}{changes}{lines_added},
            $users->{$user}{changes}{lines_removed},
            $users->{$user}{changes}{files},
        );
        printf "$fmt\n", @out[0..$max];
    }
    print "Total commits = $total\n";

    return;
}

sub fmt_json {
    my ($self, $users, $total) = @_;
    require JSON;

    print JSON::encode_json({ total => $total, users => $users });
}

sub fmt_perl {
    my ($self, $users, $total) = @_;
    require Data::Dumper;

    local $Data::Dumper::Indent = 1;
    print Data::Dumper::Dumper({ total => $total, users => $users });
}

1;

__DATA__

=head1 NAME

git-committers - Stats on the number of commits by committer

=head1 VERSION

This documentation refers to git-committers version 1.1.4

=head1 SYNOPSIS

   git-committers [option]

 OPTIONS:
  -r --remote   Committers to remote branches
  -a --all      Committers to any branch (remote or local)
  -c --changes  Add stats for lines added/removed
  -C --commits  Output the individual commits (with --format json)
  -s --since[=]YYYY-MM-DD
                Only commits since this date
  -u --until[=]YYYY-MM-DD
                Only commits up until this date
  -f --format[=](table|json|csv)
                Change how the data is presented
                   - table : shows the data in a simple table
                   - json  : returns the raw data as a json object
                   - perl  : Dump the data structure
  -p --period=[day|week|month|year]
                If --since is not specified this works out the date for the
                last day/week/month/year
  -P --periods[=]int
                Generate stats for more than one period.
  -M --min-commit[=]int
                Only show stats for users with at least this number of commits
  -m --merges   Count merge commits
     --no-merges
                Don't count merge commits

  -v --verbose  Show more detailed option
     --version  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for git-committers

=head1 DESCRIPTION

The C<git-committers> command allows to get statistics on who is committing
to the git repository.

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Executes the git workflow command

=head2 C<dates ($period, $count)>

Returns the C<--since> and C<--until> dates for the C<$period> specified

=head2 C<changes ($commits)>

Calculates the changes for C<$commits>.

=head2 C<fmt_table ()>

Output a table

=head2 C<fmt_json ()>

Output JSON

=head2 C<fmt_perl ()>

Output a Perl object

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
