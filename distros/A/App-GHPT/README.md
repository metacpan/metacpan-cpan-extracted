# NAME

App::GHPT - A command line tool to simplify using Github and Pivotal Tracker for an agile workflow

# VERSION

version 2.000000

# SYNOPSIS

    # configure as per instructions below
    $> gh-pt.pl

# DESCRIPTION

This is a command line tool to help link together
[GitHub](https://github.com/) and [Pivotal
Tracker](https://www.pivotaltracker.com/). It helps enable a workflow combining
PT stories with pull requests.

The basic workflow is as follows:

1. Start a story in Pivotal Tracker.
2. Hack, hack, hack.
3. Run this tool while you are in a git checkout. You should have the branch for
which you want to submit a PR currently checked out.

    Running this tool will do the following things for you:

    - Prompt you to select one of your active Pivotal Tracker stories.
    - (Optional)

        Ask you a set of questions about the work you've done. The answers are
        included in your PR. The question generation can be customized by writing
        plugins.

    - Create a pull request on GitHub for the repo you are currently in, with the PT
    story's title, URL, and description in the PR, a well as the optional
    questions & answers.
    - Add a comment on the PT story linking to the PR that was just created.
    - Change the PT story's status to "Delivered".

# SETUP

## GitHub config

You'll need to tell git about your GitHub account:

    git config --global submit-work.github.token gh_ae158fa0dc6570c8403f04bd35738d81

This is a GitHub personal access token.

You can alternatively provide the token via the `GITHUB_TOKEN` environment variable.

For compatibility with prior versions, the configuration file for `hub` will be
used if the above are not set.

## Pivotal Tracker config

You'll also need to tell git about your Pivotal Tracker account:

    git config --global submit-work.pivotaltracker.username thor
    git config --global submit-work.pivotaltracker.token ae158fa0dc6570c8403f04bd35738d81

Your actual username and token can be found at
[https://www.pivotaltracker.com/profile](https://www.pivotaltracker.com/profile).

You can alternatively provide your username via the `PIVOTALTRACKER_USERNAME`
environment variable and your token via the `PIVOTALTRACKER_TOKEN` environment
variable.

# CREATING PULL REQUEST QUESTIONS

A question is a class which consumes the
[App::GHPT::WorkSubmitter::Role::Question](https://metacpan.org/pod/App%3A%3AGHPT%3A%3AWorkSubmitter%3A%3ARole%3A%3AQuestion) and implements a method named
`ask`. See that role's documentation for details.

By default, this tool looks for modules that have a package name beginning
with `App::GHPT::WorkSubmitter::Question` to find question classes. However,
you can configure one or more alternative namespaces by setting the
`APP_GHPT_QUESTION_NAMESPACES` environment variable or the
`submit-work.question-namespaces` Git config key. This should be a
space-separated list of namespaces under which questions can live.

# REQUESTER NAME IN PULL REQUESTS

By default, the name of the PT story's requester will be included in the pull
request text. This is helpful if you relay your project's PRs to Slack, as the
requester can get alerted when their name is used.

If you want to disable this, set the `APP_GHPT_INCLUDE_REQUESTER_NAME_IN_PR`
environment variable or the `submit-work.include-requester-name-in-pr` Git
config key to `0`.

# COMMAND LINE OPTIONS

This tool accepts the following options:

## --project Project-Name

The name of the PT project in which to look for stories. By default, all
projects are searched one at a time. If you have a lot of projects you may
want to limit this to just one.

## --base branch

The branch against which the PR should be made. This defaults to the main
branch.

## --dry-run

Doesn't create a PR, just prints out the body of the PR that would have been
created.

# TROUBLESHOOTING

## "No started stories found"

If you get this message but you definitely have stories which are in the
"started" or "finished" states, then there's probably an error with your
configuration. Double check your PT username and token as seen on
[https://www.pivotaltracker.com/profile](https://www.pivotaltracker.com/profile) against what you see via `git
config --global --get-regexp '^submit-work'`

# BUGS

A fatal error may occur if your branch exists locally, but you haven't pushed it yet.

You may also get a warning like below, but this shouldn't impact the creation of your pull request.

    Content-Length header value was wrong, fixed at /opt/perl5.20.2/lib/site_perl/5.20.2/LWP/Protocol/http.pm line 258, <> line 1.

Bugs may be submitted through [https://github.com/maxmind/App-GHPT/issues](https://github.com/maxmind/App-GHPT/issues).

# AUTHORS

- Mark Fowler <mark@twoshortplanks.com>
- Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Dave Rolsky <drolsky@maxmind.com>
- Florian Ragwitz <rafl@debian.org>
- gabe <gpacuilla@maxmind.com>
- Greg Oschwald <goschwald@maxmind.com>
- Kevin Phair <phair.kevin@gmail.com>
- Mark Fowler <mfowler@maxmind.com>
- Narsimham Chelluri <nchelluri@maxmind.com>
- Nick Logan <nlogan@gmail.com>
- Patrick Cronin <pcronin@maxmind.com>
- William Storey <wstorey@maxmind.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by MaxMind, Inc.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
