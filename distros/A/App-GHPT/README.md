# NAME

App::GHPT - A command line tool to simplify using Github and Pivotal Tracker for an agile workflow

# VERSION

version 1.000012

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

## hub

You should first set up `hub`. It's available at [https://hub.github.com](https://hub.github.com)
and has installation instructions there.

After installation, tell git config about it and check that it's working.

    git config --global --add hub.host github.com
    hub issue

(You'll need your GitHub and/or GHE credentials.)

## pt config

You'll also need to tell git about your PT account:

    git config --global submit-work.pivotaltracker.username thor
    git config --global submit-work.pivotaltracker.token ae158fa0dc6570c8403f04bd35738d81

Your actual username and token can be found at
[https://www.pivotaltracker.com/profile](https://www.pivotaltracker.com/profile).

# CREATING PULL REQUEST QUESTIONS

A question is a class which consumes the
[App::GHPT::WorkSubmitter::Role::Question](https://metacpan.org/pod/App::GHPT::WorkSubmitter::Role::Question) and implements a method named
`ask`. See that role's documentation for details.

By default, this tools looks for modules that have a a package name beginning
with `App::GHPT::WorkSubmitter::Question` to find question classes. However,
you can configure one or more alternative namespaces by setting the git config
key `submit-work.question-namespaces`. This should be a space-separated list
of namespaces under which questions can live.

# REQUESTER NAME IN PULL REQUESTS

By default, the name of the PT story's requester will be included in the pull
request text. This is helpful if you relay your project's PRs to Slack, as the
requester can get alerted when their name is used.

If you want to disable this, set the git config key
`submit-work.include-requester-name-in-pr` to `0`.

# COMMAND LINE OPTIONS

This tool accepts the following options:

## --project Project-Name

The name of the PT project in which to look for stories. By default, all
projects are searched one at a time. If you have a lot of projects you may
want to limit this to just one.

## --base branch

The branch against which the PR should be made. This defaults to the master
branch.

## --dry-run

Doesn't create a PR, just prints out the body of the PR that would have been
created.

# TROUBLESHOOTING

## Bad Credentials

When hub is first used to connect to GitHub/GitHub Enterprise, hub requires a
name and password that it uses to generate an OAuth token and stores it in
`~/.config/hub`. If you have not used hub yet, this script will exit with:

    $ gh-pt.pl
    Error creating pull request: Unauthorized (HTTP 401)
    Bad credentials

The fix is to regenerate the OAuth token. Delete the `~/.config/hub` file if
you've got one, and then run a `hub` command manually, such as
`hub browse`. After authenticating, you should be able to use this script.

## "No started stories found"

If you get this message but you definitely have stories which are in the
"started" or "finished" states, then there's probably an error with your
configuration. Double check your PT username and token as seen on
[https://www.pivotaltracker.com/profile](https://www.pivotaltracker.com/profile) against what you see via `git
config --global --get-regexp '^submit-work'`

# BUGS

This requires 'hub' to be installed and configured.

A fatal error may occur if your branch exists locally, but you haven't pushed it yet.

You may also get a warning like below, but this shouldn't impact the creation of your pull request.

    Content-Length header value was wrong, fixed at /opt/perl5.20.2/lib/site_perl/5.20.2/LWP/Protocol/http.pm line 258, <> line 1.

Bugs may be submitted through [https://github.com/maxmind/App-GHPT/issues](https://github.com/maxmind/App-GHPT/issues).

# AUTHORS

- Mark Fowler <mark@twoshortplanks.com>
- Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Florian Ragwitz <rafl@debian.org>
- Greg Oschwald <goschwald@maxmind.com>
- Kevin Phair <phair.kevin@gmail.com>
- Mark Fowler <mfowler@maxmind.com>
- Narsimham Chelluri <nchelluri@maxmind.com>
- Patrick Cronin <pcronin@maxmind.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by MaxMind, Inc.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
