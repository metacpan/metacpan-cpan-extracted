package App::Git::Workflow::Command::UpToDate;

# Created on: 2014-01-16 04:14:31
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use English qw/ -no_match_vars /;
use App::Git::Workflow;
use App::Git::Workflow::Command qw/get_options/;
use Carp qw/cluck/;

our $VERSION  = version->new(1.1.4);
our $workflow = App::Git::Workflow->new;
our ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our %option;
our %p2u_extra;

sub run {
    my $self = shift;
    %option = (
        format      => 'test',
        max_history => $workflow->config('workflow.max-history') || 1,
        branches    => 0,
    );
    get_options(
        \%option,
        'tag|t=s',
        'branch|b=s',
        'local|l!',
        'remote|r!',
        'format|f=s',
        'quick|q!',
        'include|i=s',
        'exclude|e=s',
        'all',
        'max_history|max-history|m=i',
        'fetch|F',
        'fix|x',
    ) or return;

    my $action = shift @ARGV || 'am_i';
    my $format = 'format_' . $option{format};

    $action =~ s/-/_/g;
    $action = "do_$action";

    if ( !$self->can($action) ) {
        $action =~ s/^do_//;
        $action =~ s/_/-/;
        warn "Unknown action '$action'!\n";
        Pod::Usage::pod2usage( %p2u_extra, -verbose => 1 );
        return 1;
    }
    elsif ( $action eq 'do_show' && !$self->can($format) ) {
        warn "Unknown format '$option{format}'!\n";
        Pod::Usage::pod2usage( %p2u_extra, -verbose => 1 );
        return 1;
    }

    $workflow->{VERBOSE} = $option{verbose};
    $workflow->{TEST   } = $option{test};

    $workflow->git->fetch if $option{fetch};

    # do stuff here
    if ($option{branch_age}) {
        return branch_age();
    }

    if ($action eq 'do_show') {
        $option{branches} = 1;
    }
    my @releases = $workflow->releases(%option);

    if ($option{verbose}) {
        my $local = localtime($releases[-1]{time});
        my $now   = localtime;
        my $time  = time;
        warn <<"DETAILS";
Branch : $releases[-1]{name}
SHA    : $releases[-1]{sha}
Time   : $local ($releases[-1]{time})
Now    : $now ($time)

DETAILS
    }

    $option{all} = 1 if $action eq 'do_show' && $option{format} eq 'test';

    $self->$action(@releases);

    return;
}

sub do_show {
    my ($self, @releases) = @_;
    my $csv = branches_contain(@releases);
    if ($option{verbose}) {
        warn @$csv . " branches found\n";
    }

    my $format = 'format_' . $option{format};
    $self->$format($csv, @releases);

    return;
}

sub do_am_i {
    my (undef, @releases) = @_;

    # work out current branch, check that it contains a release branch
    my $format = q/--format=format:%H %at <%an>%ae/;

    my $bad = 0;
    for my $release (reverse @releases) {
        my ($ans) = grep {/$release->{sha}/} $workflow->git->log($format);
        chomp $ans if $ans;
        next if $ans;
        $bad++;
        warn "Missing release $release->{name}!\n";
    }

    if ($bad) {
        if ( $option{fix} ) {
            $workflow->git->merge($releases[-1]{name});
            return;
        }

        return $bad;
    }
    else {
        print "Up to date\n";
    }

    return;
}

sub do_current {
    my (undef, @releases) = @_;
    print "Current prod \"$releases[0]{name}\"\n";

    return;
}

sub do_update_me {
    my (undef, @releases) = @_;
    print "Merging \"$releases[0]{name}\"\n";
    $workflow->git->merge($releases[0]{name});

    return;
}

sub branches_contain {
    my @releases = @_;
    my @branches = $workflow->branches($option{remote} ? 'remote' : 'both');
    my $format = q/--format=format:%at <%an>%ae/;
    my @csv;

    BRANCH:
    for my $branch (@branches) {
        next BRANCH if $option{include} && $branch !~ /$option{include}/;
        next BRANCH if $option{exclude} && $branch =~ /$option{exclude}/;

        my ($first, $author, $found, $release);

        my ($log) = $workflow->git->log($format, qw/-n 1/, $branch);
        next if !$log;
        my ($time, $user) = split /\s+/, $log, 2;

        $first  = $time;
        $author = $user;
        if ( $time < $releases[-1]{time} ) {
            warn "skipping $branch\n" if $option{verbose} && $option{verbose} > 1;
            next BRANCH;
        }

        my $age = time - $releases[0]{time} + 10 * 60 * 60 * 24;
        my $ago = -1;
        RELEASE:
        for my $released (reverse @releases) {
            $ago++;
            next RELEASE if !$released->{branches}{$branch};

            $release = $released->{name};
            $age = $released == $releases[-1] ? 0 : time - $released->{time};
            last RELEASE;
        }

        next BRANCH if !$option{all} && !$option{verbose} && $found;

        push @csv, [ $release || "Out of date", $branch, $author, int $age / 60 / 60 / 24, $ago];
        warn +( $found ? 'up to date' : "missing $releases[-1]{name}" ) . "\t$branch\t$author\n" if $option{quick};
    }

    return \@csv;
}

sub format_text {
    my (undef, $csv, @releases) = @_;

    my @max = (0,0,0);
    for my $row (@$csv) {
        $max[0] = length $row->[0] if $max[0] < length $row->[0];
        $max[1] = length $row->[1] if $max[1] < length $row->[1];
        $max[2] = length $row->[2] if $max[2] < length $row->[2];
    }
    for my $row (@$csv) {
        printf "%$max[0]s %-$max[1]s %-$max[2]s (%2.0f days old)\n", @$row[0..3];
    }

    return;
}

sub format_csv {
    my (undef, $csv, @releases) = @_;

    my $sepperator = $option{format} eq 'tab' ? "\t" : ',';
    for my $row (@$csv) {
        print +(join $sepperator, @$row), "\n";
    }

    return;
}
{
    no warnings qw/once/;
    *format_tab = *format_csv;
}

sub format_json {
    my (undef, $csv, @releases) = @_;

    require JSON;
    my $repo   = $workflow->config('remote.origin.url');
    my ($name) = $repo =~ m{[/:](.*?)(?:[.]git)?$}xms;

    print JSON::encode_json({
        repository   => $repo,
        name         => $name,
        release      => $releases[-1]{name},
        release_date => '' . localtime($releases[-1]{time}),
        branches     => [
            map {{ status => $_->[0], name => $_->[1], last_author => $_->[2], release_age => $_->[3] }}
            @$csv
        ]
    });

    return;
}

sub format_html {
    my (undef, $csv, @releases) = @_;

    my $sepperator = "</td><td>";
    my $date       = localtime;
    my $repo       = $workflow->config('remote.origin.url');
    print <<"HTML";
<table>
    <caption>Branch statuses for <i>$repo</i> ($date)</caption>
    <thead>
        <tr>
            <th>Production Branch/Tag Status</th>
            <th>Branch Name</th>
            <th>Last commit owner</th>
            <th>Included release age (days)</th>
        </tr>
    </thead>
HTML

    for my $row (@$csv) {
        next if !$row && !$row->[2];
        my ($name, $email) = $row->[2] =~ /^<([^>]+)>(.*)$/;
        $row->[0] = $row->[0] eq $releases[-1]{name} ? $row->[0] : qq{<span class="old">$row->[0]</span>};
        $row->[2] = $row->[0] eq $releases[-1]{name} ? $name : qq{<a href="mailto:$email?subject=$row->[1]%20is%20out%20of%20date">$name</a>};
        print "<tr class=\"age_$row->[4]\"><td>" . (join $sepperator, @$row[0..3]), "</td></tr>\n";
    }

    print "</table>\n";

    return;
}

sub format_test {
    my (undef, $csv, @releases) = @_;

    require Test::More;
    Test::More->import();
    for my $row (@$csv) {
        is( $row->[0], $releases[-1]{name}, $row->[1] . ' is upto date')
            or note("Release is $row->[3] days old");
    }

    return;
}

1;

__DATA__

=head1 NAME

git-up-to-date - Check that git branches include latest production branch/tag

=head1 VERSION

This documentation refers to git-up-to-date version 1.1.4

=head1 SYNOPSIS

   git-up-to-date [am-i] [option]
   git-up-to-date show [option]
   git-up-to-date current [option]
   git-up-to-date update-me [option]

 SUB-COMMANDS
  am-i              (default) determine if the current branch is up-to-date
  show              Show's the status of all active branches (ie branches with
                    commits since last release)
  current           Show the current "production" branch or tag
  update-me         Merges in the latest release

 OPTIONS:
  -t --tab[=]str    Specify a tag that any branch with newer commits must contain
  -b --branch[=]str Similarly a branch that other branches with newer commits must
                    contain (Default origin/master)
  -l --local        Shorthand for --branch '^master$'
  -f --format[=](test|text|html|csv|tab|json)
                    Set the out put format
                      * test - TAP test formatted output (default)
                      * text - Simple formatted text
                      * html - A basic HTML page
                      * csv  - Comma seperated values formatted output
                      * tab  - Tab seperated values formatted output
  -q --quick        Print to STDERR the statuses as they are found (no formatting)
  -i --include[=]regexp
                    Include only "neweer" branches that match this regexp
  -e --exclude[=]regexp
                    Exclude any "neweer" branches that match this regexp
     --all          Show the status of all branches not just current ones.
  -m --max-history[=]int
                    Set the maximum number of release branches/tags to go back
                    (if more than one) to find where a branch was created from.
                    (Default 1)

  -s --branch-status
                    Shows the status (name, last committer, last commit date) of
                    all branches.
  -a --age-limit[=]date
                    With --branch-status limit to only branches created after
                    date (a YYYY-MM-DD formatted date)
  -F --fetch        Do a fetch before anything else.
  -x --fix          With am-i, merges in the current prod/release branch/tag

  -v --verbose      Shows changed branches that are upto date.
     --version      Prints the version information
     --help         Prints this help information
     --man          Prints the full documentation for git-up-to-date

=head1 DESCRIPTION

The C<git up-to-date> command can tell you the status of "active" branches as
compared to a release tag or branch. It does this by finding all tags or
branches that match the regular expression passed to C<--tag> or C<--branch>,
sorts them alpha-numerically assuming that the largest is the most recent.

 eg release_1, release_1_1

The branch release_1_1 would be considered the most recent. With the found
tag/branch the date/time it was created is used to find all branches that
have newer commits (unless C<--all> is used). These branches are then searched
to see if they contain the found release tag or branch (and if C<--max-history>
is specified and the branch doesn't contain the release branch or tag the older
releases are searched for).

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Executes the git workflow command

=head2 C<do_show ()>

=head2 C<do_am_i ()>

=head2 C<do_current ()>

=head2 C<do_update_me ()>

=head2 C<branches_contain ()>

=head2 C<format_text ()>

=head2 C<format_csv ()>

=head2 C<format_json ()>

=head2 C<format_html ()>

=head2 C<format_test ()>

=head2 C<format_tab ()>

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

Defaults for this script can be set through C<git config>

 workflow.prod  Sets how a prod release is determined
                eg the default equivalent is branch=^origin/master$
 workflow.max-history
                Sets the default C<--max-history> value

You can set these values either by editing the repository local C<.git/config>
file or C<~/.gitconfig> or use the C<git config> command

 # eg Setting the global value
    git config --global workflow.max-history 10

 # or set a repository's local value
    git config workflow.prod 'tag=^release_\d{4}_\d{2}\d{2}$'

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
