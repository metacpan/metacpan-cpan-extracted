#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use App::Git::Workflow::Command::SinceRelease;
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
                { tag      => [qw/0.1 0.3/] },
                { 'rev-list' => [qw/1414516991 31baa55db4c99774432b97ea5ec2784819a86079/] },
                { 'rev-list' => [qw/1414516992 31baa55db4c99774432b97ea5ec2784819a86079/] },
                { 'rev-parse' => [qw/31baa55db4c99774432b97ea5ec2784819a86079 31baa55db4c99774432b97ea5ec2784819a86079/] },
                { 'rev-list' => [qw/1414516991 31baa55db4c99774432b97ea5ec2784819a86079/] },
            ],
            STD => {
                OUT => "Ahead by 0 commits\n",
                ERR => '',
            },
            option => {},
            name   => 'Upto date branch',
        },
        {
            ARGV => [qw/-q/],
            mock => [
                { tag      => [qw/0.1 0.3/] },
                { 'rev-list' => [qw/1414516991 31baa55db4c99774432b97ea5ec2784819a86079/] },
                { 'rev-list' => [qw/1414516992 31baa55db4c99774432b97ea5ec2784819a86079/] },
                { 'rev-parse' => [qw/31baa55db4c99774432b97ea5ec2784819a86079 31baa55db4c99774432b97ea5ec2784819a86079/] },
                { 'rev-list' => [qw/1414516991 31baa55db4c99774432b97ea5ec2784819a86079/] },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => {
                quiet => 1,
            },
            name   => 'Up to date quiet branch',
        },
        {
            ARGV => [],
            mock => [
                { tag      => [qw/0.1 0.3/] },
                { 'rev-list' => [qw/1414516991 31baa55db4c99774432b97ea5ec2784819a86079/] },
                { 'rev-list' => [qw/1414516992 31baa55db4c99774432b97ea5ec2784819a86079/] },
                { 'rev-parse' => [qw/31baa55db4c99774432b97ea5ec2784819a86079 31baa55db4c99774432b97ea5ec2784819a86079/] },
                { 'rev-list' => [qw/1414516992 31baa55db4c99774432b97ea5ec2784819a86079/] },
            ],
            STD => {
                OUT => "Ahead by 1 commit\n",
                ERR => '',
            },
            option => {},
            name   => 'Out of date',
        },
        {
            ARGV => [qw/-q/],
            mock => [
                { tag      => [qw/0.1 0.3/] },
                { 'rev-list' => [qw/1414516991 31baa55db4c99774432b97ea5ec2784819a86071/] },
                { 'rev-list' => [qw/1414516992 31baa55db4c99774432b97ea5ec2784819a86072/] },
                { 'rev-parse' => [qw/31baa55db4c99774432b97ea5ec2784819a86073 31baa55db4c99774432b97ea5ec2784819a86074/] },
                { 'rev-list' => [qw/1414516992 31baa55db4c99774432b97ea5ec2784819a86074/] },
                { 'rev-list' => [qw/1414516993 31baa55db4c99774432b97ea5ec2784819a86073/] },
            ],
            STD => {
                OUT => "Ahead by 2 commits\n",
                ERR => '',
            },
            option => {
                quiet => 1,
            },
            name   => 'Out of date quiet',
        },
    );

    for my $data (@data) {
        command_ok('App::Git::Workflow::Command::SinceRelease', $data)
            or return;
    }
}
