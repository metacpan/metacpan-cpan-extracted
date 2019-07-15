package App::Git::Workflow::Command::Recent;

# Created on: 2014-03-11 20:58:59
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Getopt::Long;
use Pod::Usage ();
use List::MoreUtils qw/uniq/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use CHI::Memoize qw(:all);
use App::Git::Workflow;
use App::Git::Workflow::Command qw/get_options/;

our $VERSION  = version->new(1.1.4);
our $workflow = App::Git::Workflow->new;
our ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our %option;
our $memoized = 0;

sub run {
    my $self = shift;

    get_options(
        \%option,
        'all|a',
        'branch|b',
        'day|d',
        'depth|D=i',
        'path_depth|path-depth|p=i%',
        'files|f',
        'ignore_files|ignore-files=s@',
        'ignore_user|ignore-users=s@',
        'ignore_branch|ignore-branches=s@',
        'month|m',
        'out|o=s',
        'quiet|q',
        'remote|r',
        'since|s=s',
        'tag|t',
        'users|u',
        'week|w',
    );

    if (!$memoized) {
        my $git_dir = $workflow->git->rev_parse("--show-toplevel");
        chomp $git_dir;
        $git_dir =~ s{[/\\]$}{};
        memoize('App::Git::Workflow::commit_details',
            driver     => 'File',
            root_dir   => "$git_dir/.git/gw-commit-detials",
            expires_in => '1M',
            key        => sub { shift @_; @_ },
        );
        $memoized = 1;
    }

    # get a list of recent commits
    my @commits = $self->recent_commits(\%option);

    # find the files in each commit
    my %changed = $self->changed_from_shas(@commits);

    if ( $option{users} ) {
        my %users;
        for my $file (keys %changed) {
            for my $user (@{ $changed{$file}{users} }) {
                $users{$user} ||= {};
                @{ $users{$user}{files} } = (
                    uniq sort @{ $users{$user}{files} || [] }, @{ $changed{$file}{files} || [] }
                );
                @{ $users{$user}{branches} } = (
                    uniq sort @{ $users{$user}{branches} || [] }, @{ $changed{$file}{branches} || [] }
                );
            }
        }
        %changed = %users;
    }
    elsif ( $option{branches} ) {
        my %branches;
        for my $file (keys %changed) {
            for my $branch (@{ $changed{$file}{branches} }) {
                $branches{$branch} ||= {};
                @{ $branches{$branch}{files} } = (
                    uniq sort @{ $branches{$branch}{files} || [] }, @{ $changed{$file}{files} || [] }
                );
                @{ $branches{$branch}{users} } = (
                    uniq sort @{ $branches{$branch}{users} || [] }, @{ $changed{$file}{users} || [] }
                );
            }
        }
        %changed = %branches;
    }
    else {
        my %files;
        for my $file (keys %changed) {
            delete $changed{$file}{files};
        }
    }

    # display results
    my $out = 'out_' . ($option{out} || 'text');

    if ($self->can($out)) {
        $self->$out(\%changed);
    }

    return;
}

sub out_text {
    my ($self, $changed) = @_;

    for my $file (sort keys %$changed) {
        print "$file\n";
        if ( ! $option{users} ) {
            print "  Changed by : " . ( join ', ', @{ $changed->{$file}{users} || [] } ), "\n";
        }
        if ( ! $option{branches} ) {
            print "  In branches: " . ( join ', ', @{ $changed->{$file}{branches} || [] } ), "\n";
        }
        if ( $option{users} || $option{branches} ) {
            print "  Files: " . ( join ', ', @{ $changed->{$file}{files} || [] } ), "\n";
        }
    }

    return;
}

sub out_perl {
    my ($self, $changed) = @_;

    $Data::Dumper::Sortkeys = 1;
    $Data::Dumper::Indent = 1;
    print Dumper $changed;

    return;
}

sub out_json {
    my ($self, $changed) = @_;

    require JSON;
    print JSON::encode_json($changed), "\n";

    return;
}

sub out_yaml {
    my ($self, $changed) = @_;

    require YAML;
    print YAML::Dump($changed);

    return;
}

sub recent_commits {
    my ($self, $option) = @_;

    my @args = ('--since', $option->{since} );

    if ( !$option->{since} ) {
        my $sec_ago = $option->{month} ? 60 * 60 * 24 * 30
            : $option->{week} ? 60 * 60 * 24 * 7
            :                   60 * 60 * 24;

        my (undef,undef,undef,$day,$month,$year) = localtime( time - $sec_ago );
        $year += 1900;
        $month++;

        @args = ('--since', sprintf "%04d-%02d-%02d", $year, $month, $day );
    }

    unshift @args, $option->{tag} ? '--tags'
        : $option->{all}          ? '--all'
        : $option->{remote}       ? '--remotes'
        :                           '--branches';

    return $workflow->git->rev_list(@args);
}

sub changed_from_shas {
    my ($self, @commits) = @_;
    my %changed;
    my $count = 0;
    print {*STDERR} '.' if $option{verbose};

    for my $sha (@commits) {
        my $changed = $workflow->commit_details($sha, branches => 1, files => 1, user => 1);
        next if $self->ignore($changed);

        for my $type (keys %{ $changed->{files} }) {
            if ( defined $option{depth} ) {
                $type = join '/', grep {defined $_} (split m{/}, $type)[0 .. $option{depth} - 1];
            }
            if ( defined $option{path_depth} ) {
                for my $path (keys %{ $option{path_depth} }) {
                    if ( $type =~ /^$path/ ) {
                        $type = join '/', grep {defined $_} (split m{/}, $type)[0 .. $option{path_depth}{$path} - 1];
                    }
                }
            }
            my %branches;
            if ( $option{remote} ) {
                %branches = map { $_ => 1 } grep {/^origin/} keys %{ $changed->{branches} };
            }
            elsif ( $option{all} ) {
                %branches = %{ $changed->{branches} };
            }
            else {
                %branches = map { $_ => 1 } grep {!/^origin/} keys %{ $changed->{branches} };
            }
            next if !%branches;

            $changed{$type}{users}{$changed->{user}}++;
            $changed{$type}{files} = {
                %{ $changed{$type}{files} || {} },
                %{ $changed->{files} },
            };
            $changed{$type}{branches} = {
                %{ $changed{$type}{branches} || {} },
                %branches,
            };
        }

        print {*STDERR} '.' if $option{verbose} && ++$count % 10 == 0;
    }

    for my $type (keys %changed) {
        $changed{$type}{users   } = [ sort keys %{ $changed{$type}{users   } } ];
        $changed{$type}{files   } = [ sort keys %{ $changed{$type}{files   } } ];
        $changed{$type}{branches} = [ sort keys %{ $changed{$type}{branches} } ];
    }

    return %changed;
}

sub ignore {
    my ($self, $commit) = @_;

    if ($option{ignore_files}) {
        for my $ignore (@{ $option{ignore_files} }) {
            for my $file (keys %{ $commit->{files} }) {
                return 1 if $file =~ /$ignore/;
            }
        }
    }

    if ($option{ignore_user}
        && grep {$commit->{user} =~ /$_/} @{ $option{ignore_user} } ) {
        return 1;
    }

    if ($option{ignore_branch}
        && grep {$commit->{branches} =~ /$_/} @{ $option{ignore_branch} } ) {
        return 1;
    }

    return 0;
}

1;

__DATA__

=head1 NAME

git-recent - Find what files have been changed recently in a repository

=head1 VERSION

This documentation refers to git-recent version 1.1.4

=head1 SYNOPSIS

   git-recent [-since=YYYY-MM-DD|--day|--week|--month] [(-o|--out) [text|json|perl]]
   git-recent --help
   git-recent --man
   git-recent --version

 OPTIONS:
  -s --since[=]iso-date
                Show changed files since this date
  -d --day      Show changed files from the last day (Default action)
  -w --week     Show changed files from the last week
  -m --month    Show changed files from the last month
  -a --all      Show recent based on local and remote branches
  -r --remote   Show recent based on remotes only
  -t --tag      Show recent based on tags only

 OUTPUT:
  -b --branch   Show the output by what's changed in each branch
  -D --depth[=]int
                Truncate files to this number of directories (allows showing
                areas that have changed)
  -u --users    Show the output by who has made the changes
  -f --files    Show the output the files changed (Default)
     --ignore-user[=]regexp
     --ignore-users[=]regexp
                Ignore any user(s) matching regexp (can be specified more than once)
     --ignore-branch[=]regexp
     --ignore-branches[=]regexp
                Ignore any branch(s) matching regexp (can be specified more than once)
  -o --out[=](text|json|perl)
                Specify how to display the results
                    - text : Nice human readable format (Default)
                    - json : as a JSON object
                    - perl : as a Perl object
  -q --quiet    Don't show who has changed the file or where it was changed

  -v --verbose  Show more detailed option
     --version  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for git-recent

=head1 DESCRIPTION

C<git-recent> finds all files that have been changed in all branches in the
repository. This allows collaborators to quickly see who is working on what
even if it's in a different branch.

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Executes the git workflow command

=head2 C<recent_commits ($options)>

Gets a list of recent commits

=head2 C<changed_from_shas (@commits)>

Takes a list of commits and returns a HASH of files changed, by whom and in
what branches.

=head2 C<out_text ($changed)>

Displays changed files in a textural format

=head2 C<out_perl ($changed)>

Displays changed files in a Perl format

=head2 C<out_json ($changed)>

Displays changed files in a JSON format

=head2 C<out_yaml ($changed)>

Displays changed files in a YAML format

=head2 C<ignore ($commit)>

Determine if a commit should be ignored or not

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
