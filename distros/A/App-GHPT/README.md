# NAME

App::GHPT - A command line tool to simplify using Github and Pivotal Tracker for an agile workflow

# VERSION

version 1.000002

# DESCRIPTION

This is a command line tool to help link together
[GitHub](https://github.com/) and [Pivotal
Tracker](https://www.pivotaltracker.com/). It helps enable a workflow combining
PT stories with pull requests.

The basic workflow is as follows:

1. Start a story in Pivotal Tracker.
2. Hack, hack, hack.
3. Run this tool, which will do the following things for you:
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

(Your actual token can be found at [https://www.pivotaltracker.com/profile](https://www.pivotaltracker.com/profile))

# TROUBLESHOOTING

## Bad Credentials

When hub is first used to connect to GitHub/GitHub Enterprise, hub requires a
name and password that it uses to generate an OAuth token and stores it in
`~/.config/hub`. If you have not used hub yet, this script will exit with:

    $ gh-pt.pl --project my-project
    Error creating pull request: Unauthorized (HTTP 401)
    Bad credentials

The fix is to regenerate the OAuth token. Delete the `~/.config/hub` file if
you've got one, and then run a `hub` command manually, such as
`hub browse`. After authenticating, you should be able to use this script.

# BUGS

This requires 'hub' to be installed and configured.

A fatal error may occur if your branch exists locally, but you haven't pushed it yet.

You may also get a warning like below, but this shouldn't impact the creation of your pull request.

    Content-Length header value was wrong, fixed at /opt/perl5.20.2/lib/site_perl/5.20.2/LWP/Protocol/http.pm line 258, <> line 1.

Bugs may be submitted through [https://github.com/maxmind/App-GHPT/issues](https://github.com/maxmind/App-GHPT/issues).

# AUTHORS

- Mark Fowler <mark@twoshortplanks.com>
- Dave Rolsky <autarch@urth.org>

# CONTRIBUTOR

Mark Fowler <mfowler@maxmind.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by MaxMind, Inc.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
