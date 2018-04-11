#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use App::Git::Workflow::Command::Recent;
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
                { 'rev-list' =>  [
                    '0000000000000000000000000000000000000000',
                ]},
                { log    => "1414997088\x{1}0000000000000000000000000000000000000000\x{1}Test User\x{1}test.user\@example.com\x{1}file1\n" },
                { branch => ['  master'] },
            ],
            STD => {
                OUT => <<'OUT',
file1
  Changed by : Test User
  In branches: master
OUT
                ERR => '',
            },
            option => {},
            name   => 'Default',
        },
        {
            ARGV => [qw/--out text/],
            mock => [
                { 'rev-list' =>  [
                    '0000000000000000000000000000000000000000',
                ]},
                { log    => "1414997088\x{1}0000000000000000000000000000000000000000\x{1}Test User\x{1}test.user\@example.com\x{1}file1\n" },
                { branch => ['  master'] },
            ],
            STD => {
                OUT => <<'OUT',
file1
  Changed by : Test User
  In branches: master
OUT
                ERR => '',
            },
            option => { out => 'text' },
            name   => 'Text',
        },
        {
            ARGV => [qw/--out json/],
            mock => [
                { 'rev-list' =>  [
                    '0000000000000000000000000000000000000000',
                ]},
                { log    => "1414997088\x{1}0000000000000000000000000000000000000000\x{1}Test User\x{1}test.user\@example.com\x{1}file1\n" },
                { branch => ['  master'] },
            ],
            STD => {
                OUT => {
                    file1 => {
                        branches => ['master'],
                        users    => ['Test User'],
                    }
                },
                OUT_PRE => sub { JSON::decode_json($_[0]) },
                ERR => '',
            },
            option => { out => 'json' },
            name   => 'JSON',
            skip   => sub { !eval { require JSON; }; },
        },
        {
            ARGV => [qw/--out perl/],
            mock => [
                { 'rev-list' =>  [
                    '0000000000000000000000000000000000000000',
                ]},
                { log    => "1414997088\x{1}0000000000000000000000000000000000000000\x{1}Test User\x{1}test.user\@example.com\x{1}file1\n" },
                { branch => ['  master'] },
            ],
            STD => {
                OUT => {
                    file1 => {
                        branches => ['master'],
                        users    => ['Test User'],
                    }
                },
                OUT_PRE => sub { my $VAR1; eval $_[0] },
                ERR => '',
            },
            option => { out => 'perl' },
            name   => 'Perl',
        },
        {
            ARGV => [qw/--out unknown/],
            mock => [
                { 'rev-list' =>  [
                    '0000000000000000000000000000000000000000',
                ]},
                { log    => "1414997088\x{1}0000000000000000000000000000000000000000\x{1}Test User\x{1}test.user\@example.com\x{1}file1\n" },
                { branch => ['  master'] },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => { out => 'unknown' },
            name   => 'Unknown',
        },
        {
            ARGV => [qw/--out json --since 2014-11-10/],
            mock => [
                { 'rev-list' =>  [
                    '0000000000000000000000000000000000000000',
                ]},
                { log    => "1414997088\x{1}0000000000000000000000000000000000000000\x{1}Test User\x{1}test.user\@example.com\x{1}file1\n" },
                { branch => ['  master'] },
            ],
            STD => {
                OUT => {
                    file1 => {
                        branches => ['master'],
                        users    => ['Test User'],
                    }
                },
                OUT_PRE => sub { JSON::decode_json($_[0]) },
                ERR => '',
            },
            option => {
                out => 'json',
                since => '2014-11-10',
            },
            name   => 'JSON Since',
            skip   => sub { !eval { require JSON; }; },
        },
        {
            ARGV => [qw/--out json --month/],
            mock => [
                { 'rev-list' =>  [
                    '0000000000000000000000000000000000000000',
                ]},
                { log    => "1414997088\x{1}0000000000000000000000000000000000000000\x{1}Test User\x{1}test.user\@example.com\x{1}file1\n" },
                { branch => ['  master'] },
            ],
            STD => {
                OUT => {
                    file1 => {
                        branches => ['master'],
                        users    => ['Test User'],
                    }
                },
                OUT_PRE => sub { JSON::decode_json($_[0]) },
                ERR => '',
            },
            option => {
                out => 'json',
                month => 1,
            },
            name   => 'JSON Month',
            skip   => sub { !eval { require JSON; }; },
        },
        {
            ARGV => [qw/--out json --week/],
            mock => [
                { 'rev-list' =>  [
                    '0000000000000000000000000000000000000000',
                    '1111111111111111111111111111111111111111',
                ]},
                { log    => "1414997088\x{1}0000000000000000000000000000000000000000\x{1}Test User\x{1}test.user\@example.com\x{1}file1\n" },
                { branch => ['  master'] },
                { log    => "1414997088\x{1}1111111111111111111111111111111111111111\x{1}Test Other\x{1}test.other\@example.com\x{1}file1\n" },
                { branch => ['  master'] },
            ],
            STD => {
                OUT => {
                    file1 => {
                        branches => ['master'],
                        users    => ['Test Other', 'Test User'],
                    }
                },
                OUT_PRE => sub { JSON::decode_json($_[0]) },
                ERR => '',
            },
            option => {
                out => 'json',
                week => 1,
            },
            name   => 'JSON Week',
            skip   => sub { !eval { require JSON; }; },
        },
    );

    for my $data (@data) {
        command_ok('App::Git::Workflow::Command::Recent', $data)
            or return;
    }
}
