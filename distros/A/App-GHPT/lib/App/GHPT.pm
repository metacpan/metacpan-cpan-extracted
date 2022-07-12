package App::GHPT;

use App::GHPT::Wrapper::Ourperl;

use v5.20;

our $VERSION = '2.000001';

1;

# ABSTRACT: A command line tool to simplify using Github and Pivotal Tracker for an agile workflow

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GHPT - A command line tool to simplify using Github and Pivotal Tracker for an agile workflow

=head1 VERSION

version 2.000001

=head1 SYNOPSIS

    # configure as per instructions below
    $> gh-pt.pl

=head1 DESCRIPTION

This is a command line tool to help link together
L<GitHub|https://github.com/> and L<Pivotal
Tracker|https://www.pivotaltracker.com/>. It helps enable a workflow combining
PT stories with pull requests.

The basic workflow is as follows:

=over 4

=item 1.

Start a story in Pivotal Tracker.

=item 2.

Hack, hack, hack.

=item 3.

Run this tool while you are in a git checkout. You should have the branch for
which you want to submit a PR currently checked out.

Running this tool will do the following things for you:

=over 8

=item *

Prompt you to select one of your active Pivotal Tracker stories.

=item *

(Optional)

Ask you a set of questions about the work you've done. The answers are
included in your PR. The question generation can be customized by writing
plugins.

=item *

Create a pull request on GitHub for the repo you are currently in, with the PT
story's title, URL, and description in the PR, a well as the optional
questions & answers.

=item *

Add a comment on the PT story linking to the PR that was just created.

=item *

Change the PT story's status to "Delivered".

=back

=back

=head1 SETUP

=head2 GitHub config

You'll need to tell git about your GitHub account:

    git config --global submit-work.github.token gh_ae158fa0dc6570c8403f04bd35738d81

This is a GitHub personal access token.

You can alternatively provide the token via the C<GITHUB_TOKEN> environment variable.

For compatibility with prior versions, the configuration file for C<hub> will be
used if the above are not set.

=head2 Pivotal Tracker config

You'll also need to tell git about your Pivotal Tracker account:

    git config --global submit-work.pivotaltracker.username thor
    git config --global submit-work.pivotaltracker.token ae158fa0dc6570c8403f04bd35738d81

Your actual username and token can be found at
L<https://www.pivotaltracker.com/profile>.

You can alternatively provide your username via the C<PIVOTALTRACKER_USERNAME>
environment variable and your token via the C<PIVOTALTRACKER_TOKEN> environment
variable.

=head1 CREATING PULL REQUEST QUESTIONS

A question is a class which consumes the
L<App::GHPT::WorkSubmitter::Role::Question> and implements a method named
C<ask>. See that role's documentation for details.

By default, this tool looks for modules that have a package name beginning
with C<App::GHPT::WorkSubmitter::Question> to find question classes. However,
you can configure one or more alternative namespaces by setting the
C<APP_GHPT_QUESTION_NAMESPACES> environment variable or the
C<submit-work.question-namespaces> Git config key. This should be a
space-separated list of namespaces under which questions can live.

=head1 REQUESTER NAME IN PULL REQUESTS

By default, the name of the PT story's requester will be included in the pull
request text. This is helpful if you relay your project's PRs to Slack, as the
requester can get alerted when their name is used.

If you want to disable this, set the C<APP_GHPT_INCLUDE_REQUESTER_NAME_IN_PR>
environment variable or the C<submit-work.include-requester-name-in-pr> Git
config key to C<0>.

=head1 COMMAND LINE OPTIONS

This tool accepts the following options:

=head2 --project Project-Name

The name of the PT project in which to look for stories. By default, all
projects are searched one at a time. If you have a lot of projects you may
want to limit this to just one.

=head2 --base branch

The branch against which the PR should be made. This defaults to the main
branch.

=head2 --dry-run

Doesn't create a PR, just prints out the body of the PR that would have been
created.

=head1 TROUBLESHOOTING

=head2 "No started stories found"

If you get this message but you definitely have stories which are in the
"started" or "finished" states, then there's probably an error with your
configuration. Double check your PT username and token as seen on
L<https://www.pivotaltracker.com/profile> against what you see via C<git
config --global --get-regexp '^submit-work'>

=head1 BUGS

A fatal error may occur if your branch exists locally, but you haven't pushed it yet.

You may also get a warning like below, but this shouldn't impact the creation of your pull request.

    Content-Length header value was wrong, fixed at /opt/perl5.20.2/lib/site_perl/5.20.2/LWP/Protocol/http.pm line 258, <> line 1.

Bugs may be submitted through L<https://github.com/maxmind/App-GHPT/issues>.

=head1 AUTHORS

=over 4

=item *

Mark Fowler <mark@twoshortplanks.com>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 CONTRIBUTORS

=for stopwords Dave Rolsky faktas2 Florian Ragwitz gabe Greg Oschwald Kevin Phair Mark Fowler Narsimham Chelluri Nick Logan Olaf Alders Patrick Cronin William Storey

=over 4

=item *

Dave Rolsky <drolsky@maxmind.com>

=item *

faktas2 <104642023+faktas2@users.noreply.github.com>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

gabe <gpacuilla@maxmind.com>

=item *

Greg Oschwald <goschwald@maxmind.com>

=item *

Kevin Phair <phair.kevin@gmail.com>

=item *

Mark Fowler <mfowler@maxmind.com>

=item *

Narsimham Chelluri <nchelluri@maxmind.com>

=item *

Nick Logan <nlogan@gmail.com>

=item *

Olaf Alders <oalders@maxmind.com>

=item *

Patrick Cronin <pcronin@maxmind.com>

=item *

William Storey <wstorey@maxmind.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
