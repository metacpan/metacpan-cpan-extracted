#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use App::Git::Workflow::Command::Pushb;
use lib 't/lib';
use Test::Git::Workflow::Command;

our $name = 'test';

run();
done_testing();

sub run {
    my @data = (
        {
            ARGV => [""],
            mock => [],
            STD => {
                OUT => '',
                ERR => '',
            },
            error => "git pushb: no other branch\n",
            option => {},
            name   => 'No inputs',
        },
        {
            ARGV => ["test"],
            mock => [
                { 'rev-parse' => 't/data/git-pushb' },
                { 'rev-parse' => 't/data/git-pushb' },
                { checkout    => [qw//] },
                { 'rev-parse' => 't/data/git-pushb' },
            ],
            STD => {
                OUT => "origin/master \n",
                ERR => '',
            },
            option => {},
            name   => 'Push one new directory',
            workflow => {
                GIT_DIR => 'stack-0',
            },
            clean_before => [qw{t/data/git-pushb/stack-0/brs}],
        },
    );

    local $Test::Git::Workflow::Command::workflow = 'App::Git::Workflow::Brs';
    for my $data (@data) {
        for my $file (@{ $data->{clean_before} }) {
            unlink $file;
        }
        command_ok('App::Git::Workflow::Command::Pushb', $data)
            or last;
    }
}
