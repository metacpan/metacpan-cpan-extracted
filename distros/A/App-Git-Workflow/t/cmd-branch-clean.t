#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use App::Git::Workflow::Command::BranchClean;
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
                { config => undef },
                { branch => [map {"  $_"} qw{master feature1 feature2}] },
                { log    => time . "\x{1}1111111111111111111111111111111111111111" },
                { branch => [map {"  $_"} qw{master feature1}] },
                { branch => undef },
                { log    => time . "\x{1}2222222222222222222222222222222222222222" },
                { branch => [map {"  $_"} qw{feature2}] },
            ],
            STD => {
                OUT => qr//,
                ERR => qr/deleting \s merged \s branch \s feature1/xms,
            },
            option => {
                exclude => [],
                max_age => 120,
                tag_prefix => '',
                tag_suffix => '',
            },
            name   => 'default',
        },
        {
            ARGV => [qw{--unknown}],
            mock => [
                { config => undef },
            ],
            STD => {
                OUT => qr//,
                ERR => qr/^Unknown \s option: \s unknown$/xms,
            },
            option => {
                exclude => [],
                max_age => 120,
                tag_prefix => '',
                tag_suffix => '',
            },
            name   => 'unknown argument',
        },
        {
            ARGV => [qw{--remote}],
            mock => [
                { config => 200 },
                { branch => [map {"  $_"} qw{origin/master origin/feature1 origin/feature2}] },
                { log    => time . "\x{1}1111111111111111111111111111111111111111" },
                { branch => [map {"  $_"} qw{origin/feature1}] },
                { log    => time . "\x{1}2222222222222222222222222222222222222222" },
                { branch => [map {"  $_"} qw{origin/master origin/feature2}] },
                { push   => undef },
            ],
            STD => {
                OUT => qr//,
                ERR => qr/deleting \s merged \s branch \s origin\/feature2/xms,
            },
            option => {
                exclude => [],
                max_age => 200,
                tag_prefix => '',
                tag_suffix => '',
                remote     => 1,
            },
            name   => 'delete remote branches',
        },
        {
            ARGV => [qw{--all --min-age 10 --max-age 30}],
            ENV  => {
                GIT_WORKFLOW_MAX_AGE => 90,
            },
            mock => [
                { branch => [map {"  $_"} qw{master origin/master young origin/old}] },
                { log    => (time - 60*60*24*50) . "\x{1}1111111111111111111111111111111111111111" },
                { push    => undef },
                { log    => (time - 60*60*24*5) . "\x{1}2222222222222222222222222222222222222222" },
            ],
            STD => {
                OUT => qr//,
                ERR => qr/deleting \s old \s branch \s origin\/old/xms,
            },
            option => {
                exclude => [],
                min_age => 10,
                max_age => 30,
                tag_prefix => '',
                tag_suffix => '',
                all        => 1,
            },
            name   => 'delete only very old or old merged branches',
        },
        {
            ARGV => [qw{--all --min-age 10 --max-age 0}],
            ENV  => {
                GIT_WORKFLOW_MAX_AGE => 90,
            },
            mock => [
                { branch => [map {"  $_"} qw{master origin/master young origin/old}] },
                { log    => (time - 60*60*24*50) . "\x{1}1111111111111111111111111111111111111111" },
                { branch => [map {"  $_"} qw{origin/feature1}] },
                { log    => (time - 60*60*24*5) . "\x{1}2222222222222222222222222222222222222222" },
            ],
            STD => {
                OUT => qr//,
                ERR => qr/Deleted \s 0 \s of \s 1 \s branches/xms,
            },
            option => {
                exclude => [],
                min_age => 10,
                max_age => 0,
                tag_prefix => '',
                tag_suffix => '',
                all        => 1,
            },
            name   => 'delete only old and merged branches',
        },
        {
            ARGV => [qw{--tag --test}],
            mock => [
                { config => undef },
                { branch => [map {"  $_"} qw{master feature old_project}] },
                { log    => (time - 60*60*24*50) . "\x{1}1111111111111111111111111111111111111111" },
                { branch => [map {"  $_"} qw{master feature}] },
                { log    => (time - 60*60*24*50) . "\x{1}1111111111111111111111111111111111111111" },
            ],
            STD => {
                OUT => qr//,
                ERR => qr/Deleted \s 2 \s of \s 2 \s branches/xms,
            },
            option => {
                exclude => [],
                max_age => 120,
                tag_prefix => '',
                tag_suffix => '',
                tag        => 1,
                test       => 1,
            },
            name   => 'test tag deleted branches',
        },
        {
            ARGV => [qw{--tag --no-test}],
            mock => [
                { config => undef },
                { branch => [map {"  $_"} qw{master feature old_project}] },
                { log    => (time - 60*60*24*50) . "\x{1}1111111111111111111111111111111111111111" },
                { branch => [map {"  $_"} qw{master feature}] },
                { tag    => undef },
                { branch => undef },
                { log    => (time - 60*60*24*50) . "\x{1}1111111111111111111111111111111111111111" },
                { tag    => undef },
                { branch => undef },
            ],
            STD => {
                OUT => qr//,
                ERR => qr/Deleted \s 2 \s of \s 2 \s branches/xms,
            },
            option => {
                exclude => [],
                max_age => 120,
                tag_prefix => '',
                tag_suffix => '',
                tag        => 1,
                test       => 0,
            },
            name   => 'tag deleted branches',
        },
        {
            ARGV => [qw{--exclude-file t/data/excludes.txt}],
            mock => [
                { config => undef },
                { branch => [map {"  $_"} qw{master feature exclude_me}] },
                { log    => (time - 60*60*24*50) . "\x{1}1111111111111111111111111111111111111111" },
                { branch => [map {"  $_"} qw{master}] },
                { branch => undef },
            ],
            STD => {
                OUT => qr//,
                ERR => qr/Deleted \s 1 \s of \s 1 \s branches/xms,
            },
            option => {
                exclude => [],
                max_age => 120,
                tag_prefix => '',
                tag_suffix => '',
                exclude_file => 't/data/excludes.txt',
            },
            name   => 'don\'t deleete excluded branches',
        },
        {
            ARGV => [qw{--tag}],
            mock => [
                { config => undef },
                { branch => [map {"  $_"} qw{master feature}] },
                { log    => (time - 60*60*24*50) . "\x{1}1111111111111111111111111111111111111111" },
                { branch => [map {"  $_"} qw{master}] },
                { tag    => undef },
                { branch => undef },
            ],
            STD => {
                OUT => qr//,
                ERR => qr/Deleted \s 1 \s of \s 1 \s branches/xms,
            },
            option => {
                exclude => [],
                max_age => 120,
                tag_prefix => '',
                tag_suffix => '',
                tag        => 1,
            },
            name   => 'tag deleted branches',
        },
        {
            ARGV => [qw{--tag --test}],
            mock => [
                { config => undef },
                { branch => [map {"  $_"} qw{master feature project_master}] },
                { log    => (time - 60*60*24*50) . "\x{1}1111111111111111111111111111111111111111" },
                { branch => [map {"  $_"} qw{feature project_master}] },
                { log    => (time - 60*60*24*5) . "\x{1}2222222222222222222222222222222222222222" },
                { branch => [map {"  $_"} qw{project_master}] },
            ],
            STD => {
                OUT => qr//,
                ERR => qr/Deleted \s 0 \s of \s 2 \s branches/xms,
            },
            option => {
                exclude => [],
                max_age => 120,
                tag_prefix => '',
                tag_suffix => '',
                tag        => 1,
                test       => 1,
            },
            name   => 'test deleting with out deleting anything',
        },
    );

    for my $data (@data) {
        command_ok('App::Git::Workflow::Command::BranchClean', $data)
            or return;
    }
}
