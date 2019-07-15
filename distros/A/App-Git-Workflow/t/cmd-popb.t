#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use App::Git::Workflow::Command::Popb;
use lib 't/lib';
use Test::Git::Workflow::Command;

our $name = 'test';

run();
done_testing();

sub run {
    my @data = (
        {
            ARGV => [""],
            mock => [
                { 'rev-parse' => [qw/.git/] },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            error  => "popb: branch stack empty\n",
            option => {},
            name   => 'Default 1',
        },
        #{
        #    ARGV => [""],
        #    mock => [
        #        { 'rev-parse' => [qw/.git/] },
        #        { 'rev-parse' => [qw/.git/] },
        #        { checkout    => [qw//] },
        #    ],
        #    STD => {
        #        OUT => '',
        #        ERR => "git pushb: no other branch\n",
        #    },
        #    option => {},
        #    name   => 'Default 1',
        #},
    );

    local $Test::Git::Workflow::Command::workflow = 'App::Git::Workflow::Brs';
    for my $data (@data) {
        command_ok('App::Git::Workflow::Command::Popb', $data)
            or last;
    }
}
