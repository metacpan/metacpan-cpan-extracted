#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use App::Git::Workflow::Command::BranchGrep;
use lib 't/lib';
use Test::Git::Workflow::Command;

our $name = 'test';

run();
done_testing();

sub run {
    my @data = (
        {
            ARGV => ["1"],
            mock => [
                { branch => [qw/0.1 1.0 2.0/] },
            ],
            STD => {
                OUT => "0.1\n1.0\n",
                ERR => '',
            },
            option => {},
            name   => 'Default',
        },
        {
            ARGV => ["3"],
            mock => [
                { branch => [qw/1.0 2.0/] },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => {},
            name   => 'Default',
        },
        {
            ARGV => [qw/-i a/],
            mock => [
                { branch => [qw/A b c/] },
            ],
            STD => {
                OUT => "A\n",
                ERR => '',
            },
            option => { insensitive => 1 },
            name   => 'Default',
        },
        {
            ARGV => [],
            mock => [
                { branch => [qw/A b c/] },
            ],
            STD => {
                OUT => "A\nb\nc\n",
                ERR => '',
            },
            option => {},
            name   => 'Default',
        },
        {
            ARGV => ['-a', 'h'],
            mock => [
                { branch => [qw{master origin/master hamster origin/hamster}] },
            ],
            STD => {
                OUT => "hamster\norigin/hamster\n",
                ERR => '',
            },
            option => { all => 1 },
            name   => 'Default',
        },
        {
            ARGV => ['-r', 'h'],
            mock => [
                { branch => [qw{origin/master origin/hamster}] },
            ],
            STD => {
                OUT => "origin/hamster\n",
                ERR => '',
            },
            option => { remote => 1 },
            name   => 'Default',
        },
    );

    for my $data (@data) {
        command_ok('App::Git::Workflow::Command::BranchGrep', $data)
            or return;
    }
}
