#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Path::Tiny;
use App::Git::Workflow::Command::Take;
use lib 't/lib';
use Test::Git::Workflow::Command;

our $name = 'test';

my $git_dir = "t/data/git-take/";
path($git_dir)->remove_tree if -d $git_dir;
system "tree -a $git_dir";

run();
done_testing();

sub run {
    my @data = (
        {
            ARGV => [],
            mock => [
                {
                    'status' => [
                        'On branch b',
                        'You have unmerged paths.',
                        '  (fix conflicts and run "git commit")',
                        '  (use "git merge --abort" to abort the merge)',
                        '',
                        'Unmerged paths:',
                        '  (use "git add <file>..." to mark resolution)',
                        '',
                        '        both modified:   README.pod',
                        '',
                        'no changes added to commit (use "git add" and/or "git commit -a")',
                    ],
                }

            ],
            STD => {
                OUT => "Resolving README.pod\n",
                ERR => '',
            },
            option => {},
            name   => 'Default',
        },
        {
            ARGV => ['README.pod'],
            mock => [
                {
                    'status' => [
                        'On branch b',
                        'You have unmerged paths.',
                        '  (fix conflicts and run "git commit")',
                        '  (use "git merge --abort" to abort the merge)',
                        '',
                        'Unmerged paths:',
                        '  (use "git add <file>..." to mark resolution)',
                        '',
                        '        both modified:   README.pod',
                        '',
                        'no changes added to commit (use "git add" and/or "git commit -a")',
                    ],
                }

            ],
            STD => {
                OUT => "Resolving README.pod\n",
                ERR => '',
            },
            option => {},
            name   => 'Default',
        },
    );

    for my $data (@data) {
        command_ok('App::Git::Workflow::Command::Take', $data)
            or last;
    }
}
