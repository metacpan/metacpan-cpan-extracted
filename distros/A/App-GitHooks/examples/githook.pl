#!perl

use strict;
use warnings;

use App::GitHooks;


=head1 NAME

githook.pl - Script to call App::GitHooks for all the git hooks.


=head1 DESCRIPTION

This is a script that can be used to call C<App::GitHooks> for all the hooks
git supports. Just symlink C<.git/hooks/[the hook name]> to it and
C<App::GitHooks> will be instantiated with the correct inputs for that hook.

=cut

App::GitHooks->run(
    name      => $0,
    arguments => \@ARGV,
);
