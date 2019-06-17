# NAME

App::TimeTracker::Command::Git - App::TimeTracker Git plugin

# VERSION

version 3.000

# DESCRIPTION

This plugin makes it easier to set up and manage `git` `topic
branches`. When starting a new task, you can at the same time start a
new `git branch`. Also, when stopping, `tracker` can merge the
`topic branch` back into `master`.

See http://nvie.com/posts/a-successful-git-branching-model/ for a good example on how to work with topic branches (and much more!)

# CONFIGURATION

## plugins

Add `Git` to the list of plugins. 

Of course this plugin will only work if the current project is in fact a git repo...

# NEW COMMANDS

none

# CHANGES TO OTHER COMMANDS

## start, continue

### New Options

#### --branch cool\_new\_feature

    ~/perl/Your-Project$ tracker start --branch cool_new_feature    
    Started working on Your-Project at 13:35:53
    Switched to branch 'cool_new_feature'

If you pass a branch name via `--branch`, `tracker` will create a
new branch (unless it already exists) and then switch into this
branch.

If the branch already existed, it might be out of sync with master. In
this case you should do something like `git merge master` before
starting to work.

#### --nobranch (--no\_branch)

    ~/perl/Your-Project$ tracker start --branch another_featur --no_branch

Do not create a new branch, even if `--branch` is set. This is only useful if another plugin (eg <RT>) automatically sets `--branch`.

## stop

### New Options

#### --merge

    ~/perl/Your-Project$ tracker stop --merge

After, stopping, merge the current branch back into `master` (using `--no-ff`.

TODO: Turn this into a string option, which should be the name of the
branch we want to merge into. Default to `master` (or something set
in config..)

# AUTHOR

Thomas Klausner <domm@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 - 2019 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
