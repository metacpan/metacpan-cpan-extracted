package App::git::nuke_forge_fork;
# ABSTRACT: delete forks created by git-clean-forge-fork(1)
#
# Copyright (C) 2020  Sean Whitton <spwhitton@spwhitton.name>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
$App::git::nuke_forge_fork::VERSION = '0.007';
use 5.028;
use strict;
use warnings;

use subs 'main';
use Getopt::Long;
use Git::Wrapper;
use API::GitForge qw(new_from_domain forge_access_token remote_forge_info);
use Try::Tiny;
use Cwd;
use Term::UI;

my $exit_main = 0;

CORE::exit main unless caller;


sub main {
    shift if $_[0] and ref $_[0] eq "";
    local @ARGV = @{ $_[0] } if $_[0] and ref $_[0] ne "";

    my $term     = Term::ReadLine->new("brand");
    my $upstream = "origin";
    my $git      = Git::Wrapper->new(getcwd);
    #<<<
    try {
        $git->rev_parse({ git_dir => 1 });
    } catch {
        die "pwd doesn't look like a git repository ..\n";
    };
    #>>>
    GetOptions "upstream=s" => \$upstream;

    my @fork_branches
      = grep !/\Agitforge\z/,
      map { m#refs/heads/#; $' } $git->ls_remote(qw(--heads fork));
    if (@fork_branches) {
        say "Would delete the following branches:";
        say "  $_" for @fork_branches;
        print "\n";
        exit unless $term->ask_yn(prompt => "Are you sure?");
    }

    my ($forge_domain, $upstream_repo) = remote_forge_info $upstream;
    my $forge = new_from_domain
      domain       => $forge_domain,
      access_token => forge_access_token $forge_domain;
    $forge->nuke_fork($upstream_repo);
    $git->remote(qw(rm fork));

  EXIT_MAIN:
    return $exit_main;
}

sub exit { $exit_main = shift // 0; goto EXIT_MAIN }

__END__

=pod

=encoding UTF-8

=head1 NAME

App::git::nuke_forge_fork - delete forks created by git-clean-forge-fork(1)

=head1 VERSION

version 0.007

=head1 FUNCTIONS

=head2 main

Implementation of git-nuke-forge-fork(1).  Please see documentation
for that command.

Normally takes no arguments and responds to C<@ARGV>.  If you want to
override that you can pass an arrayref of arguments, and those will be
used instead of the contents of C<@ARGV>.

=for Pod::Coverage exit

1;

=head1 AUTHOR

Sean Whitton <spwhitton@spwhitton.name>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017, 2020 by Sean Whitton <spwhitton@spwhitton.name>.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
