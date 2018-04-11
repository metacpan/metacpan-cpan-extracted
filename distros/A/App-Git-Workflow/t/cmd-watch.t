#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use App::Git::Workflow::Command::Watch;
use lib 't/lib';
use Test::Git::Workflow::Command;

our $name = 'test';

run();
done_testing();

sub run {
    my $localdate = localtime 1411592689;
    my $only = shift @ARGV;
    my @data = (
        {
            ARGV => [qw{--once --sleep 0}],
            mock => [
                { log    =>  [
                    '9999999 Message9',
                    '8888888 Message8',
                    '7777777 Message7',
                    '6666666 Message6',
                    '5555555 Message5',
                    '4444444 Message4',
                    '3333333 Message3',
                    '2222222 Message2',
                    '1111111 Message1',
                    '0000000 Message0',
                ]},
                { log    =>  [
                    '9999999 Message9',
                    '8888888 Message8',
                    '7777777 Message7',
                    '6666666 Message6',
                    '5555555 Message5',
                    '4444444 Message4',
                    '3333333 Message3',
                    '2222222 Message2',
                    '1111111 Message1',
                    '0000000 Message0',
                ]},
                { log    =>  [
                    'aaaaaaa Message10',
                    '9999999 Message9',
                    '8888888 Message8',
                    '7777777 Message7',
                    '6666666 Message6',
                    '5555555 Message5',
                    '4444444 Message4',
                    '3333333 Message3',
                    '2222222 Message2',
                    '1111111 Message1',
                    '0000000 Message0',
                ]},
                { log    => time . "\x{1}aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\x{1}Ivan Wills\x{1}ivan.wills\@example.com\x{1}file1\nfile2\n" },
                { branch => ["  master"] },
            ],
            STD => {
                OUT => <<'STDOUT',
aaaaaaa
  Branches: master
  Files:    file1, file2
  Users:    Ivan Wills

STDOUT
                ERR => '',
            },
            option => {
                max      => 10,
                sleep    => 0,
                pull_options => '',
                once     => 1,
            },
            name   => 'Default (show)',
        },
        {
            ARGV => [qw{show --once --sleep 0}],
            mock => [
                { log    =>  [
                    '9999999 Message9',
                    '8888888 Message8',
                    '7777777 Message7',
                    '6666666 Message6',
                    '5555555 Message5',
                    '4444444 Message4',
                    '3333333 Message3',
                    '2222222 Message2',
                    '1111111 Message1',
                    '0000000 Message0',
                ]},
                { log    =>  [
                    'aaaaaaa Message10',
                    '9999999 Message9',
                    '8888888 Message8',
                    '7777777 Message7',
                    '6666666 Message6',
                    '5555555 Message5',
                    '4444444 Message4',
                    '3333333 Message3',
                    '2222222 Message2',
                    '1111111 Message1',
                    '0000000 Message0',
                ]},
                { log    => time . "\x{1}aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\x{1}Ivan Wills\x{1}ivan.wills\@example.com\x{1}file1\nfile2\n" },
                { branch => ["  master"] },
            ],
            STD => {
                OUT => <<'STDOUT',
aaaaaaa
  Branches: master
  Files:    file1, file2
  Users:    Ivan Wills

STDOUT
                ERR => '',
            },
            option => {
                max      => 10,
                sleep    => 0,
                pull_options => '',
                once     => 1,
            },
            name   => 'Default show',
        },
        {
            ARGV => [qw{show --once --sleep 0 --verbose}],
            mock => [
                { log    =>  [
                    '9999999 Message9',
                    '8888888 Message8',
                    '7777777 Message7',
                    '6666666 Message6',
                    '5555555 Message5',
                    '4444444 Message4',
                    '3333333 Message3',
                    '2222222 Message2',
                    '1111111 Message1',
                    '0000000 Message0',
                ]},
                { log    =>  [
                    'aaaaaaa Message10',
                    '9999999 Message9',
                    '8888888 Message8',
                    '7777777 Message7',
                    '6666666 Message6',
                    '5555555 Message5',
                    '4444444 Message4',
                    '3333333 Message3',
                    '2222222 Message2',
                    '1111111 Message1',
                    '0000000 Message0',
                ]},
                { log    => "1411592689\x{1}aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\x{1}Ivan Wills\x{1}ivan.wills\@example.com\x{1}file1\nfile2\n" },
                { branch => ["  master"] },
            ],
            STD => {
                OUT => <<"STDOUT",
aaaaaaa @ $localdate
  Branches:\x{20}
    master
  Files:   \x{20}
    file1
    file2
  Users:   \x{20}
    Ivan Wills

STDOUT
                ERR => qr{^[-/|\\.]?},
            },
            option => {
                max      => 10,
                sleep    => 0,
                pull_options => '',
                once     => 1,
                verbose  => 1,
            },
            name   => 'Show verbose',
        },
        {
            ARGV => [qw{show --once --sleep 0 --verbose --quiet}],
            mock => [
                { log    =>  [
                    '9999999 Message9',
                    '8888888 Message8',
                    '7777777 Message7',
                    '6666666 Message6',
                    '5555555 Message5',
                    '4444444 Message4',
                    '3333333 Message3',
                    '2222222 Message2',
                    '1111111 Message1',
                    '0000000 Message0',
                ]},
                { log    =>  [
                    'aaaaaaa Message10',
                    '9999999 Message9',
                    '8888888 Message8',
                    '7777777 Message7',
                    '6666666 Message6',
                    '5555555 Message5',
                    '4444444 Message4',
                    '3333333 Message3',
                    '2222222 Message2',
                    '1111111 Message1',
                    '0000000 Message0',
                ]},
                { log    => "1411592689\x{1}aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\x{1}Ivan Wills\x{1}ivan.wills\@example.com\x{1}file1\nfile2\n" },
                { branch => ["  master"] },
            ],
            STD => {
                OUT => <<"STDOUT",
aaaaaaa @ $localdate
STDOUT
                ERR => qr{^[-/|\\.]?},
            },
            option => {
                max      => 10,
                sleep    => 0,
                pull_options => '',
                once     => 1,
                verbose  => 1,
                quiet    => 1,
            },
            name   => 'Show verbose and quiet',
        },
        {
            ARGV => [qw{echo --once --sleep 0 --pull}],
            mock => [
                { log    =>  [
                    '9999999 Message9',
                    '8888888 Message8',
                    '7777777 Message7',
                    '6666666 Message6',
                    '5555555 Message5',
                    '4444444 Message4',
                    '3333333 Message3',
                    '2222222 Message2',
                    '1111111 Message1',
                    '0000000 Message0',
                ]},
                { pull => undef },
                { log    =>  [
                    'aaaaaaa Message10',
                    '9999999 Message9',
                    '8888888 Message8',
                    '7777777 Message7',
                    '6666666 Message6',
                    '5555555 Message5',
                    '4444444 Message4',
                    '3333333 Message3',
                    '2222222 Message2',
                    '1111111 Message1',
                    '0000000 Message0',
                ]},
                { log    => time . "\x{1}aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\x{1}Ivan Wills\x{1}ivan.wills\@example.com\x{1}file1\nfile2\n" },
                { branch => ["  master"] },
            ],
            STD => {
                OUT => qr/^\n?$/,
                ERR => '',
            },
            option => {
                max      => 10,
                sleep    => 0,
                pull_options => '',
                once     => 1,
                pull     => 1,
            },
            skip   => sub { $^O eq 'MSWin32' },
            name   => 'Show with echo and pull',
        },
        {
            ARGV => [qw{--remote --once --sleep 0 --file 3 --branch other}],
            mock => [
                { 'rev-list' =>  [
                    '4444444444444444444444444444444444444444',
                    '3333333333333333333333333333333333333333',
                    '2222222222222222222222222222222222222222',
                    '1111111111111111111111111111111111111111',
                    '0000000000000000000000000000000000000000',
                ]},
                { fetch => undef },
                { 'rev-list' =>  [
                    '1666666666666666666666666666666666666666',
                    '5555555555555555555555555555555555555555',
                    '4444444444444444444444444444444444444444',
                    '3333333333333333333333333333333333333333',
                    '2222222222222222222222222222222222222222',
                    '1111111111111111111111111111111111111111',
                    '0000000000000000000000000000000000000000',
                ]},
                { log    => time . "\x{1}1666666666666666666666666666666666666666\x{1}Some One\x{1}some.one\@example.com\x{1}file3\n" },
                { branch => [map {"  $_"} qw/master other/] },
                { log    => time . "\x{1}5555555555555555555555555555555555555555\x{1}Ivan Wills\x{1}ivan.wills\@example.com\x{1}file1\nfile2\n" },
                { branch => ["  master"] },
            ],
            STD => {
                OUT => <<'STDOUT',
1666666666666666666666666666666666666666
  Branches: master, other
  Files:    file1, file2, file3
  Users:    Ivan Wills, Some One

STDOUT
                ERR => '',
            },
            option => {
                max      => 10,
                sleep    => 0,
                pull_options => '',
                once     => 1,
                remote   => 1,
                file     => 3,
                branch   => 'other'
            },
            name   => 'show remote with 3 files and other branch',
        },
        {
            ARGV => [qw{--remote --once --sleep 0 --branch other}],
            mock => [
                { 'rev-list' =>  [
                    '4444444444444444444444444444444444444444',
                    '3333333333333333333333333333333333333333',
                    '2222222222222222222222222222222222222222',
                    '1111111111111111111111111111111111111111',
                    '0000000000000000000000000000000000000000',
                ]},
                { fetch => undef },
                { 'rev-list' =>  [
                    '2666666666666666666666666666666666666666',
                    '5555555555555555555555555555555555555555',
                    '4444444444444444444444444444444444444444',
                    '3333333333333333333333333333333333333333',
                    '2222222222222222222222222222222222222222',
                    '1111111111111111111111111111111111111111',
                    '0000000000000000000000000000000000000000',
                ]},
                { log    => time . "\x{1}2666666666666666666666666666666666666666\x{1}Some One\x{1}some.one\@example.com\x{1}file3\n" },
                { branch => [map {"  $_"} qw/master ~ther/] },
                { log    => time . "\x{1}5555555555555555555555555555555555555555\x{1}Ivan Wills\x{1}ivan.wills\@example.com\x{1}file1\nfile2\n" },
                { branch => ["  master"] },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => {
                max      => 10,
                sleep    => 0,
                pull_options => '',
                once     => 1,
                remote   => 1,
                branch   => 'other'
            },
            name   => 'show remote and other branch',
        },
        {
            ARGV => [qw{--all --once --sleep 0 --file qwerty.txt --branch other}],
            mock => [
                { 'rev-list' =>  [
                    '4444444444444444444444444444444444444444',
                    '3333333333333333333333333333333333333333',
                    '2222222222222222222222222222222222222222',
                    '1111111111111111111111111111111111111111',
                    '0000000000000000000000000000000000000000',
                ]},
                { fetch => undef },
                { 'rev-list' =>  [
                    '3666666666666666666666666666666666666666',
                    '5555555555555555555555555555555555555555',
                    '4444444444444444444444444444444444444444',
                    '3333333333333333333333333333333333333333',
                    '2222222222222222222222222222222222222222',
                    '1111111111111111111111111111111111111111',
                    '0000000000000000000000000000000000000000',
                ]},
                { log    => time . "\x{1}3666666666666666666666666666666666666666\x{1}Some One\x{1}some.one\@example.com\x{1}file3\n" },
                { branch => [map {"  $_"} qw/master other/] },
                { log    => time . "\x{1}5555555555555555555555555555555555555555\x{1}Ivan Wills\x{1}ivan.wills\@example.com\x{1}file1\nfile2\n" },
                { branch => ["  master"] },
            ],
            STD => {
                OUT => <<'STDOUT',
3666666666666666666666666666666666666666
  Branches: master, other
  Files:    file1, file2, file3
  Users:    Ivan Wills, Some One

STDOUT
                ERR => '',
            },
            option => {
                max      => 10,
                sleep    => 0,
                pull_options => '',
                once     => 1,
                all      => 1,
                file     => 'qwerty.txt',
                branch   => 'other'
            },
            name   => 'show all with file qwerty.txt and branch other',
        },
        {
            ARGV => [qw{--remote --once --sleep 0 --file qwerty.txt --branch no-found}],
            mock => [
                { 'rev-list' =>  [
                    '4444444444444444444444444444444444444444',
                    '3333333333333333333333333333333333333333',
                    '2222222222222222222222222222222222222222',
                    '1111111111111111111111111111111111111111',
                    '0000000000000000000000000000000000000000',
                ]},
                { fetch => undef },
                { 'rev-list' =>  [
                    '4666666666666666666666666666666666666666',
                    '5555555555555555555555555555555555555555',
                    '4444444444444444444444444444444444444444',
                    '3333333333333333333333333333333333333333',
                    '2222222222222222222222222222222222222222',
                    '1111111111111111111111111111111111111111',
                    '0000000000000000000000000000000000000000',
                ]},
                { log    => time . "\x{1}4666666666666666666666666666666666666666\x{1}Some One\x{1}some.one\@example.com\x{1}file3\n" },
                { branch => [map {"  $_"} qw/master ~ther/] },
                { log    => time . "\x{1}5555555555555555555555555555555555555555\x{1}Ivan Wills\x{1}ivan.wills\@example.com\x{1}file1\nfile2\n" },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => {
                max      => 10,
                sleep    => 0,
                pull_options => '',
                once     => 1,
                remote   => 1,
                file     => 'qwerty.txt',
                branch   => 'no-found'
            },
            name   => 'show remote file qwerty.txt and branch that doesn\'t exist',
        },
    );

    for my $data (@data) {
        next if $only && $data->{name} ne $only;
        command_ok('App::Git::Workflow::Command::Watch', $data)
            or return;
    }
}
