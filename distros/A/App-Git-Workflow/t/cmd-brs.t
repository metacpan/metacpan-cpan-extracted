#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use App::Git::Workflow::Command::Brs;
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
    );

    local $Test::Git::Workflow::Command::workflow = 'App::Git::Workflow::Brs';
    for my $data (@data) {
        command_ok('App::Git::Workflow::Command::Brs', $data)
            or last;
    }
}
