package App::Git::Workflow::Command::Jira;

# Created on: 2014-03-11 21:06:01
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use English qw/ -no_match_vars /;
use App::Git::Workflow::Pom;
use App::Git::Workflow::Command qw/get_options/;

our $VERSION  = version->new(1.1.4);
our $workflow = App::Git::Workflow::Pom->new;
our ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our %option;

sub run {
    if (!@ARGV) {
        warn "No JIRA specified!\n";
        @ARGV = qw/--help/;
    }
    get_options(
        \%option,
        'all|a',
        'remote|r',
        'list|l',
        'quiet|q!',
        'url|u=s',
        'user|U=s',
        'pass|password|P=s',
    ) or return;

    my $jira_re = my $jira = shift @ARGV;
    $jira_re =~ s/[-_]/[-_]/;
    $jira_re = lc $jira_re;

    # check local branches first
    my $type   = $option{all} ? 'both' : $option{remote} ? 'remote' : 'local';
    my $prefix = $option{all} || $option{remote} ? '(?:\w+/)?' : '';
    my @branch = grep {/^$prefix(?:[a-z]+\/)?(\w+_)?$jira_re(?:\D|$)/i} $workflow->branches($type);

    if (@branch) {
        my $branch = which_branch(@branch);
        return if !defined $branch;
        $workflow->git->checkout($branch);
    }
    else {
        # check if there is a remote branch
        my (@remote_branch) = grep {/^origin\/(\w+_)?$jira_re/} $workflow->branches('remote');
        if (@remote_branch) {
            my $remote_branch = which_branch(@remote_branch);
            return if !defined $remote_branch;
            my $branch = $remote_branch;
            $branch =~ s{^origin/}{};
            $workflow->git->checkout('-b', $branch, '--track', $remote_branch);
            print "Switched to branch '$branch'\n" if !$option{quiet};
        }
        elsif (!$option{quiet}) {
            if ( $option{url} && eval { require JIRA::REST } ) {
                $jira =~ s/_/-/;
                $jira = uc $jira;
                my $jira_rest = JIRA::REST->new($option{url}, $option{user}, $option{pass});
                my $issue     = eval { $jira_rest->GET("/issue/$jira") };
                my $branch    = lc "$jira $issue->{fields}{summary}";
                $branch =~ s/[ !?-]+/_/gxms;

                warn "No branch found for $jira!\n";
                warn "Create with one of the following:\n";
                warn "git feature $branch\n";
            }
            else {
                # suggest how to construct the branch
                warn "No branch for jira $jira exists!\n";
                warn "Create with one of the following:\n";
                warn "git feature $jira\n";
            }
        }
    }

    return;
}

sub which_branch {
    my @branches = map {/(.*)$/} @_;

    if ($option{list}) {
        print +( join "\n", map {label($_)} @branches ), "\n";
        return;
    }
    return $branches[0] if @branches == 1;

    my $count = 0;
    print {*STDERR} "Which branch:\n\t";
    print {*STDERR} join "", map { ++$count . ". $_\n\t" } map {label($_)} @branches;
    print {*STDERR} "\n[1..$count] : ";
    my $ans = <STDIN>;
    chomp $ans;
    $ans--;
    if (!$branches[$ans]) {
        warn "\nUnknown branch!\n";
        return;
    }

    return $branches[$ans];
}

sub label {
    my ($branch) = @_;
    return $branch if $option{quiet};

    my $details = $workflow->commit_details($branch, user => 1);

    return "$branch ($details->{user} at " . localtime($details->{time}) . ')';
}

1;

__DATA__

=head1 NAME

git-jira - Checkout any branch mentioning the passed Jira

=head1 VERSION

This documentation refers to git-jira version 1.1.4

=head1 SYNOPSIS

   git-jira [option] JIRAID

 OPTIONS:
  JIRAID        A Jira format id
  -u --url[=]URL
                Use URL as the JIRA instance for looking up summaries.
  -l --list     Just list found branch(es) don't checkout
  -q --quiet    Don't inform how to create missing branch

  -v --verbose  Show more detailed option
     --version  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for git-Jira

=head1 DESCRIPTION

Finds any branch containing the passed Jira issue id and switches to that
branch. If none is found then it suggests creating the branch using
L<git-feature>. If L<JIRA::REST> is installed the suggestion will use the
JIRA summary as part of the name.

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Executes the git workflow command

=head2 C<which_branch (@branches)>

Ask the user which branch to switch to

=head2 C<label ($branch)>

Adds user and time to a branch unless --quiet used

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

Defaults for this script can be set through C<git config>

 jira.url       Specifies the URL for the JIRA instance being used.

You can set these values either by editing the repository local C<.git/config>
file or C<~/.gitconfig> or use the C<git config> command

 # eg Setting the local value (ie only the current repository)
    git config jira.url https://jira.example.com/

 # eg Setting the global value
    git config --global jira.url https://jira.example.com/

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
