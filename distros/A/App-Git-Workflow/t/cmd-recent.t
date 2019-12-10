#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Path::Tiny;
use App::Git::Workflow::Command::Recent;
use lib 't/lib';
use Test::Git::Workflow::Command;

our $name = 'test';

my $git_dir = "t/data/git-recent/";
if ( ( -e $git_dir && -w $git_dir ) || -w "$git_dir/.." ) {
    plan( skip_all => "This test requires write access to run" );
}

path($git_dir)->remove_tree if -d $git_dir;
system "tree -a $git_dir";

run();
done_testing();

sub run {
    my @data = (
        {
            ARGV => [],
            mock => [
                { 'rev-parse' => "$git_dir\n" },
                { 'rev-list' =>  [
                    '1000000000000000000000000000000000000000',
                ]},
                { log    => "1414997088\x{1}1000000000000000000000000000000000000000\x{1}Test User\x{1}test.user\@example.com\x{1}file1\n" },
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
                    '2000000000000000000000000000000000000000',
                ]},
                { log    => "1414997088\x{1}2000000000000000000000000000000000000000\x{1}Test User\x{1}test.user\@example.com\x{1}file1\n" },
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
                    '3000000000000000000000000000000000000000',
                ]},
                { log    => "1414997088\x{1}3000000000000000000000000000000000000000\x{1}Test User\x{1}test.user\@example.com\x{1}file1\n" },
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
                    '4000000000000000000000000000000000000000',
                ]},
                { log    => "1414997088\x{1}4000000000000000000000000000000000000000\x{1}Test User\x{1}test.user\@example.com\x{1}file1\n" },
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
                    '5000000000000000000000000000000000000000',
                ]},
                { log    => "1414997088\x{1}5000000000000000000000000000000000000000\x{1}Test User\x{1}test.user\@example.com\x{1}file1\n" },
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
                    '6000000000000000000000000000000000000000',
                ]},
                { log    => "1414997088\x{1}6000000000000000000000000000000000000000\x{1}Test User\x{1}test.user\@example.com\x{1}file1\n" },
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
                    '7000000000000000000000000000000000000000',
                ]},
                { log    => "1414997088\x{1}7000000000000000000000000000000000000000\x{1}Test User\x{1}test.user\@example.com\x{1}file1\n" },
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
                    '8000000000000000000000000000000000000000',
                    '1111111111111111111111111111111111111111',
                ]},
                { log    => "1414997088\x{1}8000000000000000000000000000000000000000\x{1}Test User\x{1}test.user\@example.com\x{1}file1\n" },
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
            or last;
    }
}
