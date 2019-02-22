#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use App::Git::Workflow::Command::BranchClean;
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
                { config => undef },
                { branch => [map {"  $_"} qw{master feature1 feature2}] },
                { log    => time . "\x{1}1111111111111111111111111111111111111111" },
                { branch => [map {"  $_"} qw{master feature1}] },
                { branch => undef },
                { log    => time . "\x{1}2222222222222222222222222222222222222222" },
                { branch => [map {"  $_"} qw{feature2}] },
            ],
            STD => {
                OUT => qr//,
                ERR => qr/deleting \s merged \s branch \s feature1/xms,
            },
            option => {
                exclude => [],
                max_age => 120,
                tag_prefix => '',
                tag_suffix => '',
            },
            name   => 'default',
        },
    );

    for my $data (@data) {
        command_ok('App::Git::Workflow::Command::BranchClean', $data)
            or return;
    }
}
