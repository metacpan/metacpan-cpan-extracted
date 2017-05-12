#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use App::Git::Workflow::Command::Cows;
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
                { status => [
                    "#  modified: file1\n",
                    "#  modified: file2\n",
                ]},
                { diff   => "file1 differs\n" },
                { diff   =>     "" },
                { checkout =>     undef },
            ],
            STD => {
                OUT => '',
                ERR => "\tfile2\n",
            },
            option => {},
            name   => 'Default',
        },
        {
            ARGV => [qw/--quiet/],
            mock => [
                { status => [
                    "#  modified: file1\n",
                    "#  modified: file2\n",
                ]},
                { diff   => "file1 differs\n" },
                { diff   => "" },
                { checkout => undef },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => { quiet => 1 },
            name   => 'Default',
        },
    );

    for my $data (@data) {
        command_ok('App::Git::Workflow::Command::Cows', $data)
            or return;
    }
}
