#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use App::Git::Workflow::Command::Branches;
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
                { branch => [] },
            ],
            STD => {
                OUT => qr//,
                ERR => qr//xms,
            },
            option => {
                exclude => [],
            },
            name   => 'default',
        },
    );

    for my $data (@data) {
        command_ok('App::Git::Workflow::Command::Branches', $data)
            or return;
    }
}
