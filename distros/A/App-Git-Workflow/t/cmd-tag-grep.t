#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use App::Git::Workflow::Command::TagGrep;
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
                { tag => [qw/0.1 1.0 2.0/] },
            ],
            STD => {
                OUT => "0.1\n1.0\n",
                ERR => '',
            },
            option => {},
            name   => 'Default 1',
        },
        {
            ARGV => ["3"],
            mock => [
                { tag => [qw/1.0 2.0/] },
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
                { tag => [qw/A b c/] },
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
                { tag => [qw/A b c/] },
            ],
            STD => {
                OUT => "A\nb\nc\n",
                ERR => '',
            },
            option => {},
            name   => 'Default',
        },
    );

    for my $data (@data) {
        command_ok('App::Git::Workflow::Command::TagGrep', $data)
            or return;
    }
}
