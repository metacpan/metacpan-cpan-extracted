package App::Git::Workflow::Command::Watch;

# Created on: 2014-03-11 20:58:59
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

our $VERSION  = version->new(1.1.4);
our $workflow = App::Git::Workflow->new;
our ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our %option;
my %actions = (
    show => 1,
    do   => 1,
);

sub run {
    %option = (
        max      => 10,
        sleep    => 60,
        pull_options => '',
    );
    get_options(
        \%option,
        'all|a',
        'branch|b=s',
        'pull|p',
        'pull_options|pull-options|P=s',
        'file|f=s',
        'max|m=i',
        'runs|R=i',
        'once|1',
        'quiet|q',
        'remote|r',
        'sleep|s=i',
    );

    # do stuff here
    my $action = @ARGV && $actions{$ARGV[0]} ? shift @ARGV : @ARGV ? 'do' : 'show';
    my ($last) = git_state();
    my $once
        = $option{once} ? -1
        : $option{runs} ? -$option{runs}
        :                 1;

    while ($once) {
        eval {
            my ($id, @rest) = git_state(1);
            spin() if $option{verbose};

            if ( $last ne $id ) {
                $once++;
                my $changes = changes($last, $id, @rest);

                if ( found($changes) ) {
                    if ( $action eq 'show' ) {
                        my $time = $option{verbose} ? ' @ ' . localtime $changes->{time} : '';
                        print "$id$time\n";

                        if ( !$option{quiet} ) {
                            my $join = $option{verbose} ? "\n    " : '';
                            print "  Branches: ";
                            print $join, join +($join || ', '), sort keys %{ $changes->{branches} };
                            print "\n";
                            print "  Files:    ";
                            print $join, join +($join || ', '), sort keys %{ $changes->{files} };
                            print "\n";
                            print "  Users:    ";
                            print $join, join +($join || ', '), sort keys %{ $changes->{user} };
                            print "\n\n";
                        }
                    }
                    else {
                        $ENV{WATCH_SHA}      = $id;
                        $ENV{WATCH_USERS}    = join ',', keys %{ $changes->{user} };
                        $ENV{WATCH_EMAILS}   = join ',', keys %{ $changes->{email} };
                        $ENV{WATCH_FILES}    = join ',', keys %{ $changes->{files} };
                        $ENV{WATCH_BRANCHES} = join ',', keys %{ $changes->{branches} };
                        system @ARGV;
                    }
                }
            }

            $last = $id;
        };
        sleep $option{sleep};
    }

    return;
}

sub git_state {
    my ($fetch) = @_;
    my @out;

    if ( $option{all} || $option{remote} ) {
        if ($fetch) {
            $workflow->git->fetch;
        }
        @out = $workflow->git->rev_list('--all', "-$option{max}");
    }
    else {
        $workflow->git->pull(split /\s+/, $option{pull_options}) if $fetch && $option{pull};
        @out = $workflow->git->log('--oneline', "-$option{max}");
    }

    return map {/^([0-9a-f]+)\s*/; $1} @out;
}

sub found {
    my ($changes) = @_;

    if ($option{file}) {
        return 1 if grep {/$option{file}/} keys %{ $changes->{files} };
    }

    if ($option{branch}) {
        return 1 if grep {/$option{branch}/} keys %{ $changes->{branches} };
    }

    return !$option{file} && !$option{branch};
}

sub changes {
    my ($last, $newest, @ids) = @_;
    my $changes = $workflow->commit_details($newest, branches => 1, files => 1, user => 1 );

    $changes->{user}  = { $changes->{user} => 1 };
    $changes->{email} = { $changes->{email} => 1 };

    for my $id (@ids) {
        last if $id eq $last;
        my $change  = $workflow->commit_details($id, branches => 1, files => 1, user => 1 );

        $changes->{files}    = { %{$changes->{files}}, %{$change->{files}} };
        $changes->{branches} = { %{$changes->{branches}}, %{$change->{branches}} };
        $changes->{user}     = { %{$changes->{user}}, $change->{user} => 1 };
        $changes->{email}    = { %{$changes->{email}}, $change->{email} => 1 };
    }

    return $changes;
}

{
    my $spinner;
    sub spin {
        if (!defined $spinner) {
            $spinner = 0;
            eval { require Term::Spinner };
            return if $@;
            $spinner = Term::Spinner->new();
        }
        elsif (!$spinner) {
            print {*STDERR} '.';
            return;
        }

        return $spinner->advance;
    }
}

1;

__DATA__

=head1 NAME

git-watch - Watch for changes in repository up-stream

=head1 VERSION

This documentation refers to git-watch version 1.1.4

=head1 SYNOPSIS

   git-watch show [-1|--once] [(-f|--file) file ...]
   git-watch [do] [-1|--once] [(-f|--file) file ...] [--] cmd

 SUB-COMMAND
  show          Simply show when a file
  do            Execute a shell script cmd when a change occurs

 OPTIONS:
  -1 --once     Run once then exit
  -R --runs[=]int
                Run at most this number of times.
  -p --pull     Before checking if anything has changed do a git pull to the
                current branch. (see notes below)
  -P --pull-options[=]flags
                When using --pull add these options to the pull command.
  -f --file[=]regex
                Watch file any files changing that match "regex"
  -b --branch[=]regex
                Watch for any changes to branches matching "regex"
                by default looks only at local branches
  -r --remote   With --branch only look at remote branches
  -a --all      With --branch look at all branches (local and remote)
  -m --max[=]int
                Look only --max changes back in history to see what is
                happening (Default 10)
  -s --sleep[=]int
                Sleep time between fetches (devault 60s)
  -q --quiet    Suppress notifying of what files and branches have changed
  -v --verbose  Show more detailes
     --version  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for git-watch

=head1 DESCRIPTION

The C<git-watch> command allows you to run a command when something changes.
The simple option is C<show> which just shows what has changed when it changes
and nothing else, this is useful for seeing what is happening in the
repository. The the C<do> sub-command actually runs a script every time a
change is detected.

=head2 show

The output of C<show> is changed with the C<--quiet> and C<--verbose> options to
show more or less information.

=head2 do

When the C<do> sub-command runs it sets the environment variables C<$WATCH_SHA>,
C<$WATCH_FILES> and C<$WATCH_BRANCHES> with the latest commit SHA, the files
that have changed and the branches that have changed respectively. The files
and branches are comma separated for your command to inspect.

A simple example:

  git watch 'echo $WATCH_FILES'

This would just echo the files that have changed with each change.

=head2 Notes

If trying to watch a branch that is connected to a remote branch the C<--pull>
isn't currently working as expected. The workaround is to watch the remote
branch and do the pull your self. eg

 $ git watch do -rb origin/master -- 'git pull --ff -r; your-command'

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Executes the git workflow command

=head2 C<git_state ()>

=head2 C<found ()>

=head2 C<changes ()>

=head2 C<spin ()>

Helper providing access to Term::Spinner if installed

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
