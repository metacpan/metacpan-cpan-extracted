#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use App::Git::Workflow::Command::Committers;
use lib 't/lib';
use Test::Git::Workflow::Command;

our $name = 'test';

run();
done_testing();

sub run {
    my @data = (
        {
            ARGV => [],
            mock => [
                { branch => ['master'] },
                { log    => ['abc123 User Name', '123abc User Name', 'a1b2c3 Other Name'] },
            ],
            STD => {
                OUT => "User Name                       2\nOther Name                      1\nTotal commits = 3\n",
                ERR => '',
            },
            option => { period => 'day' },
            name   => 'Default',
        },
        {
            ARGV => [qw/--period day/],
            mock => [
                { branch => ['master'] },
                { log    => ['abc123 User Name', '123abc User Name', 'a1b2c3 Other Name'] },
            ],
            STD => {
                OUT => "User Name                       2\nOther Name                      1\nTotal commits = 3\n",
                ERR => '',
            },
            option => { period => 'day' },
            name   => 'Explicit day',
        },
        {
            ARGV => [qw/--period week/],
            mock => [
                { branch => ['master'] },
                { log    => ['abc123 User Name', '123abc User Name', 'a1b2c3 Other Name'] },
            ],
            STD => {
                OUT => "User Name                       2\nOther Name                      1\nTotal commits = 3\n",
                ERR => '',
            },
            option => { period => 'week' },
            name   => 'Week',
        },
        {
            ARGV => [qw/--period month/],
            mock => [
                { branch => ['master'] },
                { log    => ['abc123 User Name', '123abc User Name', 'a1b2c3 Other Name'] },
            ],
            STD => {
                OUT => "User Name                       2\nOther Name                      1\nTotal commits = 3\n",
                ERR => '',
            },
            option => { period => 'month' },
            name   => 'Month',
        },
        {
            ARGV => [qw/--period year/],
            mock => [
                { branch => ['master'] },
                { log    => ['abc123 User Name', '123abc User Name', 'a1b2c3 Other Name'] },
            ],
            STD => {
                OUT => "User Name                       2\nOther Name                      1\nTotal commits = 3\n",
                ERR => '',
            },
            option => { period => 'year' },
            name   => 'Year',
        },
        {
            ARGV => [qw/--period date/],
            mock => [],
            STD => {
                OUT => '',
                ERR => '',
            },
            error  => "Unknown period 'date' please choose one of day, week, month or year\n",
            option => { period => 'date' },
            name   => 'Bad date (use day)',
        },
        {
            ARGV => [qw/--since 2014-09-19/],
            mock => [
                { branch => ['master'] },
                { log    => ['abc123 User Name', '123abc User Name', 'a1b2c3 Other Name'] },
            ],
            STD => {
                OUT => "User Name                       2\nOther Name                      1\nTotal commits = 3\n",
                ERR => '',
            },
            option => { period => 'day', since => '2014-09-19' },
            name   => 'Specific since date',
        },
        {
            ARGV => [qw/--all --merges/],
            mock => [
                { branch => ['master', 'remotes/origin/HEAD -> origin/master'] },
                { log    => ['abc123 User Name', '123abc User Name', 'a1b2c3 Other Name'] },
            ],
            STD => {
                OUT => "User Name                       2\nOther Name                      1\nTotal commits = 3\n",
                ERR => '',
            },
            option => { period => 'day', all => 1, merges => 1 },
            name   => 'Day and all branches',
        },
        {
            ARGV => [qw/--remote/],
            mock => [
                { branch => ['origin/master'] },
                { log    => ['abc123 User Name', '123abc User Name', 'a1b2c3 Other Name'] },
            ],
            STD => {
                OUT => "User Name                       2\nOther Name                      1\nTotal commits = 3\n",
                ERR => '',
            },
            option => { period => 'day', remote => 1 },
            name   => 'Day and remote branches',
        },
    );

    for my $data (@data) {
        command_ok('App::Git::Workflow::Command::Committers', $data)
            or return;
    }
}
