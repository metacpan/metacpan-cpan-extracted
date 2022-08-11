#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use App::Git::Workflow::Command::Memo;
use lib 't/lib';
use Test::Git::Workflow::Command;

*Pod::Usage::pod2usage = sub { warn "usage\n"; };
our $name = 'test';

my $git_dir = "t/data/git-memo/";
if ( !-w $git_dir || !-w "$git_dir/.." ) {
    plan( skip_all => "This test requires write access to run" );
}

run();
done_testing();

sub run {
    my @data = (
        {   ARGV => [],
            mock => [
                { 'rev-parse' => './t/data/git-memo' },
                { 'rev-parse' => 'master' },
                { 'log' => ['c345772070ad1f12eb8b1e6b91e545e2f00ee8bb'] },
                { 'rev-parse' => './t/data/git-memo' },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => {},
            name   => 'Default add current branch',
        },
        {   ARGV => [qw/add branch/],
            mock => [
                { 'rev-parse' => './t/data/git-memo' },
                { 'log' => ['c345772070ad1f12eb8b1e6b91e545e2f00ee8bb'] },
                { 'rev-parse' => './t/data/git-memo' },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => {},
            name   => 'Default add branch',
        },
        {   ARGV => [qw/add -c branch/],
            mock => [
                { 'rev-parse' => './t/data/git-memo' },
                { 'log' => ['c345772070ad1f12eb8b1e6b91e545e2f00ee8bb'] },
                { 'rev-parse' => './t/data/git-memo' },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => { commitish => 'branch' },
            name   => 'Default add branch',
        },
        {   ARGV => [qw/list/],
            mock => [
                { 'rev-parse' => './t/data/git-memo' },
                { 'rev-parse' => 'master' },
                { 'log' => ['c345772070ad1f12eb8b1e6b91e545e2f00ee8bb'] },
            ],
            STD => {
                OUT => "[0] # branch\n[1] * master\n",
                ERR => '',
            },
            option => {},
            name   => 'Default list',
        },
        {   ARGV => [qw/switch/],
            mock => [ { 'rev-parse' => './t/data/git-memo' }, ],
            STD  => {
                OUT => '',
                ERR => "git memo switch requires an argument!\nusage\n",
            },
            option => { number => 'switch', },
            name   => 'Default switch no argument',
        },
        {   ARGV => [qw/switch 0/],
            mock => [
                { 'rev-parse' => './t/data/git-memo' },
                { 'checkout'  => [] },
                { 'rev-parse' => './t/data/git-memo' },
                { 'rev-parse' => './t/data/git-memo' },
                { 'rev-parse' => 'master' },
                { 'log' => ['c345772070ad1f12eb8b1e6b91e545e2f00ee8bb'] },
            ],
            STD => {
                OUT => "[0] # branch\n[1] * master\n",
                ERR => '',
            },
            option => { number => 0, },
            name   => 'Default switch to option 0',
        },
        {   ARGV => [qw/switch -n 0/],
            mock => [
                { 'rev-parse' => './t/data/git-memo' },
                { 'checkout'  => [] },
                { 'rev-parse' => './t/data/git-memo' },
                { 'rev-parse' => './t/data/git-memo' },
                { 'rev-parse' => 'master' },
                { 'log' => ['c345772070ad1f12eb8b1e6b91e545e2f00ee8bb'] },
            ],
            STD => {
                OUT => "[0] # branch\n[1] * master\n",
                ERR => '',
            },
            option => { number => 0, },
            name   => 'Default switch to option -n 0',
        },
        {   ARGV => [qw/delete/],
            mock => [ { 'rev-parse' => './t/data/git-memo' }, ],
            STD  => {
                OUT => '',
                ERR => "git memo delete requires an argument!\nusage\n",
            },
            option => { number => 'delete', },
            name   => 'Default delete no argument',
        },
        {   ARGV => [qw/delete 0/],
            mock => [
                { 'rev-parse' => './t/data/git-memo' },
                { 'rev-parse' => './t/data/git-memo' },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => { number => 0, },
            name   => 'Default delete to option 0',
        },
        {   ARGV => [qw/unknown/],
            mock => [],
            STD  => {
                OUT => '',
                ERR => "Unknown action unknown!\nusage\n",
            },
            option => {},
            name   => 'Default switch to option 1',
        },
    );

    for my $data (@data) {
        command_ok( 'App::Git::Workflow::Command::Memo', $data )
            or last;
    }
}
