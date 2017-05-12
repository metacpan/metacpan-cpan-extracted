#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use App::Git::Workflow::Command::Feature;
use lib 't/lib';
use Test::Git::Workflow::Command;

our $name = 'test';
$Test::Git::Workflow::Command::workflow = 'App::Git::Workflow::Pom';
run();
done_testing();

sub run {
    my @data = (
        {
            ARGV => [],
            mock => [
                { config => undef },
                { config => undef },
                { config => undef },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => {
                pom => 'pom.xml',
                local => undef,
                fetch => 1,
                url   => undef,
            },
            error => "No JIRA specified!\n",
            name  => 'No branches',
        },
        {
            ARGV => [],
            mock => [
                { config => 'a/pom.xml' },
                { config => undef },
                { config => undef },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => {
                pom => 'a/pom.xml',
                local => undef,
                fetch => 1,
                url   => undef,
            },
            error => "No JIRA specified!\n",
            name  => 'No branches (set pom)',
        },
        {
            ARGV => [qw{feature_1}],
            mock => [
                { config => undef },
                { config => undef },
                { config => undef },
                { config => 'branch=release' },
                { fetch  => undef },
                { branch => [map {"  $_"} qw{origin/master origin/release}] },
                { checkout => undef },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => {
                pom => 'pom.xml',
                local => undef,
                fetch => 1,
                url   => undef,
            },
            name  => 'Simple create feature branch',
        },
        {
            ARGV => [qw{feature_1 -v}],
            mock => [
                { config => undef },
                { config => undef },
                { config => undef },
                { config => 'branch=release' },
                { fetch  => undef },
                { branch => [map {"  $_"} qw{origin/master origin/release}] },
                { checkout => undef },
            ],
            STD => {
                OUT => "Created feature_1\n",
                ERR => '',
            },
            option => {
                pom   => 'pom.xml',
                local => undef,
                fetch => 1,
                url   => undef,
                verbose => 1,
            },
            name  => 'Simple create feature branch (verbose)',
        },
        {
            ARGV => [qw{feature_1 --push}],
            mock => [
                { config => undef },
                { config => undef },
                { config => undef },
                { config => 'branch=release' },
                { fetch  => undef },
                { branch => [map {"  $_"} qw{origin/master origin/release}] },
                { checkout => undef },
                { push   => undef },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => {
                pom => 'pom.xml',
                local => undef,
                fetch => 1,
                url   => undef,
                push  => 1,
            },
            name  => 'Simple create feature branch, pushed',
        },
        {
            ARGV => [qw{feature_1 --no-fetch}],
            mock => [
                { config => undef },
                { config => undef },
                { config => undef },
                { config => 'branch=release' },
                { branch => [map {"  $_"} qw{origin/master origin/release}] },
                { checkout => undef },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => {
                pom => 'pom.xml',
                local => undef,
                fetch => 1,
                url   => undef,
                fetch => 0,
            },
            name  => 'Simple create feature branch, fetching',
        },
        {
            ARGV => [qw{feature_1 --tag release}],
            mock => [
                { config => undef },
                { config => undef },
                { config => undef },
                { fetch  => undef },
                { tag    => [qw{v1 v2 release}] },
                { checkout => undef },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => {
                pom => 'pom.xml',
                local => undef,
                fetch => 1,
                url   => undef,
                tag   => 'release',
            },
            name  => 'Simple create feature branch, fetching',
        },
        {
            ARGV => [qw{feature_1 --branch release}],
            mock => [
                { config => undef },
                { config => undef },
                { config => undef },
                { fetch  => undef },
                { branch => [map {"  $_"} qw{origin/master origin/release}] },
                { checkout => undef },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => {
                pom => 'pom.xml',
                local => undef,
                fetch => 1,
                url   => undef,
                branch => 'release',
            },
            name  => 'Simple create feature branch, pushed',
        },
        {
            ARGV => [qw{feature_1 --local}],
            mock => [
                { config => undef },
                { config => undef },
                { config => undef },
                { config => undef },
                { fetch  => undef },
                { branch => [map {"  $_"} qw{master release}] },
                { checkout => undef },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => {
                pom => 'pom.xml',
                local => undef,
                fetch => 1,
                url   => undef,
                local => 1,
            },
            name  => 'Simple create feature branch',
        },
        {
            ARGV => [qw{feature_1}],
            mock => [
                { config => undef },
                { config => undef },
                { config => undef },
                { config => undef },
                { fetch  => undef },
                { branch => [map {"  $_"} qw{origin/master origin/release}] },
                { checkout => undef },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => {
                pom => 'pom.xml',
                local => undef,
                fetch => 1,
                url   => undef,
            },
            name  => 'Simple create feature branch',
        },
    );

    for my $data (@data) {
        command_ok('App::Git::Workflow::Command::Feature', $data)
            or return;
    }
}
