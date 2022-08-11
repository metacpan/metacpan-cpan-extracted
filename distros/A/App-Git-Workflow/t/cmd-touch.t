#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use App::Git::Workflow::Command::Touch;
use lib 't/lib';
use Test::Git::Workflow::Command;

our $name = 'test';

run();
done_testing();

sub run {
    my @data = (
        {   ARGV => ["test"],
            mock => [
                { log => ["2021-11-26 05:47:54 +1100\n"] },

                #{ tag => [qw/0.1 1.0 2.0/] },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => {},
            name   => 'Default 1',
        },
    );

    for my $data (@data) {
        warn $data;
        command_ok( 'App::Git::Workflow::Command::Touch', $data )
            or last;
    }
}
