package App::Git::Workflow::Command::Feature;

# Created on: 2014-03-11 21:17:31
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
    %option = (
        pom     => $workflow->config('workflow.pom') || 'pom.xml',
        local   => $workflow->config('workflow.pom-local'),
        fetch   => 1,
        url     => $workflow->config('jira.url'),
    );
    get_options(
        \%option,
        'tag|t=s',
        'branch|b=s',
        'local|l!',
        'pom|x=s',
        'url|u=s',
        'user|U=s',
        'pass|password|P=s',
        'jira|j=s',
        'fetch|f!',
        'new_pom|new-pom|n!',
        'push|p',
    ) or return;

    # do stuff here
    $workflow->{VERBOSE} = $option{verbose};
    $workflow->{TEST   } = $option{test};

    my ($feature_branch) = @ARGV ? shift @ARGV : jira();
    my ($type, $regex);
    if ($option{tag}) {
        $type = 'tag';
        $regex = $option{tag};
    }
    elsif ($option{branch}) {
        $type = 'branch';
        $regex = $option{branch};
    }
    else {
        my $default = $workflow->config('workflow.prod');
        my $prod
            = $default       ? $default
            : $option{local} ? 'branch=^master$'
            :                  'branch=^origin/master$';
        ($type, $regex) = split /\s*=\s*/, $prod;
    }

    $workflow->git->fetch() if $option{fetch};
    my $release = $workflow->release($type, $option{local}, $regex);

    # checkout branch
    print "Created $feature_branch\n" if $option{verbose};
    $workflow->git->checkout( '-b', $feature_branch, '--no-track', $release );

    if ($option{new_pom}) {
        my $version = $workflow->next_pom_version($option{pom});

        system(qw/mvn versions:set/, "–DnewVersion=$version");
    }

    # push if requested to
    if ($option{push}) {
        $workflow->git->push( qw/-u origin/, $feature_branch );
    }

    return;
}

sub jira {
    die "No JIRA specified!\n"     if !$option{jira};
    die "No JIRA url specified!\n" if !$option{url};
    require JIRA::REST;

    my $jira_rest = JIRA::REST->new($option{url}, $option{user}, $option{pass});
    my $issue     = $jira_rest->GET("/issue/$option{jira}");
    my $branch    = lc "$option{jira} $issue->{fields}{summary}";

    # remove unsafe characters
    $branch =~ s/[&'" .:!?|\/\\-]+/_/gxms;
    # remove leading and trailing underscores
    $branch =~ s/^_+|_+$//gxms;
    # remove doubled underscores
    $branch =~ s/__+/_/gxms;

    return $branch;
}

1;

__DATA__

=head1 NAME

git-feature - Create a feature branch from the "current release"

=head1 VERSION

This documentation refers to git-feature version 1.1.4

=head1 SYNOPSIS

   git-feature [option] branch-name
   git-feature [option] [--jira|-j] JIRAID

 OPTIONS:
  branch-name       The name of the new branch to create from the current release branch/tag

  -j --jira[=]JIRAID
                    Find the summary for JIRA item JIRAID and make it the
                    branch name for the feature.
  -u --url[=]URL    Use URL as the JIRA instance for looking up summaries.
  -U --user[=]str   JIRA user name to use when querying JIRA
  -P --password[=]str
                    JIRA password for --user
  -t --tag[=]str    Specify a tag that any branch with newer commits must contain
  -b --branch[=]str Similarly a branch that other branches with newer commits must
                    contain (Default origin/master)
  -l --local        Shorthand for --branch '^master$'
  -p --push         Push the new brach upstream
     --no-fetch     Don't fetch before trying to find the remote branch
  -n --new-pom      Set the pom.xml version to the next available version
  -x --pom[=]dir/pom.xml
                    The location of the master pom.xml if it isn't in the
                    current directory.
  -t --test         Test, don't actually run
  -v --verbose      Show more details
     --version      Prints the version information
     --help         Prints this help information
     --man          Prints the full documentation for git-feature

=head1 DESCRIPTION

The C<git feature> command allows a simplified way to create and switch to
feature branches using whatever you define as the I<current release>.

By default I<current release> is defined as the I<origin/master> branch that
can be changed either on the command line using the --tag or --branch
arguments or by setting the C<workflow.prod> git config. Example of commonly
used alternatives include using release version tags where you might use
something like C<--tag ^v\d+[.]\d+'> to match tags like v0.1 or v1.0 etc.
Other examples include different branches containing release versions of
code.

The branch I<origin/master> is used over I<master> to save you from having
to switch to master and pull any new changes. A C<git fetch> is called by
default before branching to further ensure the latest version of code is
available.

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Executes the git workflow command

=head2 C<jira ()>

Create a branch name from the JIRA summary

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

Defaults for this script can be set through C<git config>

 workflow.prod  Sets how a prod release is determined
                eg the default equivalent is branch=^origin/master$
 workflow.pom   The default location for the pom.xml file (used by C<--new-pom>
                when updating pom.xml for the new branch)
 workflow.pom-local
                Can set default value of C<--local>
 jira.url       Specifies the URL for the JIRA instance being used

You can set these values either by editing the repository local C<.git/config>
file or C<~/.gitconfig> or use the C<git config> command

 # eg Setting the global value
    git config --global workflow.prod 'branch=^origin/master$'

 # or set a repository's local value
    git config workflow.prod 'tag=^release_\d{4}_\d{2}\d{2}$'

 # or setting pom.xml location to a sub directory
    git config workflow.pom 'somedir/pom.xml'

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
