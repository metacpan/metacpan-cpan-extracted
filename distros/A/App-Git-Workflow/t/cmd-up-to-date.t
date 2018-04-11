#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use App::Git::Workflow::Command::UpToDate;
use lib 't/lib';
use Test::Git::Workflow::Command;

our $name = 'test';
%App::Git::Workflow::Command::UpToDate::p2u_extra = ( -exitval => 'NOEXIT', );

run();
done_testing();

sub run {
    my $only = shift @ARGV;
    my @data = (
        {
            ARGV => [],
            mock => [
                { config => undef },
                { config => undef },
                { branch =>  [map {"  $_"} qw{master origin/master}] },
                { log    => "1411637048\x{1}0000000000000000000000000000000000000000" },
                { log    => ['1111111111111111111111111111111111111111 1414746381 <Ivan Wills>ivan.wills@gmail.com'] },
            ],
            STD => {
                OUT => '',
                ERR => "Missing release origin/master!\n",
            },
            option => {
                format      => 'test',
                max_history => 1,
                branches    => 0,
            },
            name   => 'Default am-i',
        },
        {
            ARGV => [qw/am-i/],
            mock => [
                { config => undef },
                { config => undef },
                { branch => [map {"  $_"} qw{master origin/master}] },
                { log    => "1411637048\x{1}0000000000000000000000000000000000000000" },
                { log    => ['1111111111111111111111111111111111111111 1414746381 <Ivan Wills>ivan.wills@gmail.com'] },
            ],
            STD => {
                OUT => '',
                ERR => "Missing release origin/master!\n",
            },
            option => {
                format      => 'test',
                max_history => 1,
                branches    => 0,
            },
            name   => 'am-i',
        },
        {
            ARGV => [qw/am-i --fix/],
            mock => [
                { config => undef },
                { config => undef },
                { branch => [map {"  $_"} qw{master origin/master}] },
                { log    => "1411637048\x{1}0000000000000000000000000000000000000000" },
                { log    => ['1111111111111111111111111111111111111111 1414746381 <Ivan Wills>ivan.wills@gmail.com'] },
                { merge  => undef },
            ],
            STD => {
                OUT => '',
                ERR => "Missing release origin/master!\n",
            },
            option => {
                format      => 'test',
                max_history => 1,
                fix         => 1,
                branches    => 0,
            },
            name   => 'am-i',
        },
        {
            ARGV => [qw/am-i/],
            mock => [
                { config => undef },
                { config => undef },
                { branch => [map {"  $_"} qw{master origin/master}] },
                { log    => "1411637048\x{1}0000000000000000000000000000000000000000" },
                { log    => ['0000000000000000000000000000000000000000 1414746381 <Ivan Wills>ivan.wills@gmail.com'] },
            ],
            STD => {
                OUT => "Up to date\n",
                ERR => '',
            },
            option => {
                format      => 'test',
                max_history => 1,
                branches    => 0,
            },
            name   => 'am-i good',
        },
        {
            ARGV => [qw/--quiet/],
            mock => [
                { config => 30 },
            ],
            STD => {
                OUT => qr/Usage:/,
                ERR => "Unknown option: quiet\n",
            },
            option => {
                format      => 'test',
                max_history => 30,
                branches    => 0,
            },
            name   => 'Default --quiet',
        },
        {
            ARGV => [qw/unknown/],
            mock => [
                { config => undef },
            ],
            STD => {
                OUT => '',
                ERR => "Unknown action 'unknown'!\n",
            },
            option => {
                format      => 'test',
                max_history => 1,
                branches    => 0,
            },
            name   => 'Bad param',
        },
        {
            ARGV => [qw/show --format unknown /],
            mock => [
                { config => undef },
            ],
            STD => {
                OUT => '',
                ERR => "Unknown format 'unknown'!\n",
            },
            option => {
                format      => 'unknown',
                max_history => 1,
                branches    => 0,
            },
            name   => 'show --format unknown',
        },
        {
            ARGV => [qw/show/],
            mock => [
                { config => undef },
                { config => undef },
                { branch => [map {"  $_"} qw{master origin/master}] },
                { log    => "1411637048\x{1}0000000000000000000000000000000000000000" },
                { branch => [map {"  $_"} qw{master origin/master}] },
                { log    => ['0000000000000000000000000000000000000000 1414746381 <Ivan Wills>ivan.wills@gmail.com'] },
                { log    => ['0000000000000000000000000000000000000000 1414746381 <Ivan Wills>ivan.wills@gmail.com'] },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => {
                format      => 'test',
                max_history => 1,
                branches    => 1,
                all         => 1,
            },
            name   => 'Show (test)',
        },
        {
            ARGV => [qw/show --format test/],
            mock => [
                { config => undef },
                { config => undef },
                { branch => [map {"  $_"} qw{master origin/master}] },
                { log    => "1411637048\x{1}0000000000000000000000000000000000000000" },
                { branch => [map {"  $_"} qw{master origin/master}] },
                { log    => ['0000000000000000000000000000000000000000 1414746381 <Ivan Wills>ivan.wills@gmail.com'] },
                { log    => ['0000000000000000000000000000000000000000 1414746381 <Ivan Wills>ivan.wills@gmail.com'] },
            ],
            STD => {
                OUT => '',
                ERR => '',
            },
            option => {
                format      => 'test',
                max_history => 1,
                branches    => 1,
                all         => 1,
            },
            name   => 'Show test',
        },
        {
            ARGV => [qw/show --format text/],
            mock => [
                { config => undef },
                { config => undef },
                { branch => [map {"  $_"} qw{master origin/master}] },
                { log    => "1411637048\x{1}0000000000000000000000000000000000000000" },
                { branch => [map {"  $_"} qw{master origin/master}] },
                { log    => ['1414746381 <Ivan Wills>ivan.wills@gmail.com'] },
                { log    => ['1414746381 <Ivan Wills>ivan.wills@gmail.com'] },
            ],
            STD => {
                OUT => "origin/master master        <Ivan Wills>ivan.wills\@gmail.com ( 0 days old)\n".
                       "origin/master origin/master <Ivan Wills>ivan.wills\@gmail.com ( 0 days old)\n",
                ERR => '',
            },
            option => {
                format      => 'text',
                max_history => 1,
                branches    => 1,
            },
            name   => 'Show text',
        },
        {
            ARGV => [qw/show --format csv/],
            mock => [
                { config => undef },
                { config => undef },
                { branch => [map {"  $_"} qw{master origin/master}] },
                { log    => "1411637048\x{1}0000000000000000000000000000000000000000" },
                { branch => [map {"  $_"} qw{master origin/master}] },
                { log    => ['1414746381 <Ivan Wills>ivan.wills@gmail.com'] },
                { log    => ['1414746381 <Ivan Wills>ivan.wills@gmail.com'] },
            ],
            STD => {
                OUT => "origin/master,master,<Ivan Wills>ivan.wills\@gmail.com,0,0\n".
                       "origin/master,origin/master,<Ivan Wills>ivan.wills\@gmail.com,0,0\n",
                ERR => '',
            },
            option => {
                format      => 'csv',
                max_history => 1,
                branches    => 1,
            },
            name   => 'Show csv',
        },
        {
            ARGV => [qw/show --format tab/],
            mock => [
                { config => undef },
                { config => undef },
                { branch => [map {"  $_"} qw{master origin/master}] },
                { log    => "1411637048\x{1}0000000000000000000000000000000000000000" },
                { branch => [map {"  $_"} qw{master origin/master}] },
                { log    => ['1414746381 <Ivan Wills>ivan.wills@gmail.com'] },
                { log    => ['1414746381 <Ivan Wills>ivan.wills@gmail.com'] },
            ],
            STD => {
                OUT => "origin/master\tmaster\t<Ivan Wills>ivan.wills\@gmail.com\t0\t0\n".
                       "origin/master\torigin/master\t<Ivan Wills>ivan.wills\@gmail.com\t0\t0\n",
                ERR => '',
            },
            option => {
                format      => 'tab',
                max_history => 1,
                branches    => 1,
            },
            name   => 'Show tab',
        },
        {
            ARGV => [qw/show --format html --fetch/],
            mock => [
                { config => undef },
                { fetch  => undef },
                { config => undef },
                { branch => [map {"  $_"} qw{master origin/master}] },
                { log    => "1411637048\x{1}0000000000000000000000000000000000000000" },
                { branch => [map {"  $_"} qw{master origin/master}] },
                { log    => ['1414746381 <Ivan Wills>ivan.wills@gmail.com'] },
                { log    => ['1414746381 <Ivan Wills>ivan.wills@gmail.com'] },
                { config => "http://example.com/example.git" },
            ],
            STD => {
                OUT => qr{<table>
    <caption>Branch statuses for <i>http://example.com/example.git</i> [(][^)]*[)]</caption>
    <thead>
        <tr>
            <th>Production Branch/Tag Status</th>
            <th>Branch Name</th>
            <th>Last commit owner</th>
            <th>Included release age [(]days[)]</th>
        </tr>
    </thead>
<tr class="age_0"><td>origin/master</td><td>master</td><td>Ivan Wills</td><td>0</td></tr>
<tr class="age_0"><td>origin/master</td><td>origin/master</td><td>Ivan Wills</td><td>0</td></tr>
</table>
},
                ERR => '',
            },
            time => 1411672543,
            option => {
                format      => 'html',
                max_history => 1,
                branches    => 1,
                fetch       => 1,
            },
            name   => 'Show html',
        },
        {
            ARGV => [qw/show --format json/],
            mock => [
                { config => undef },
                { config => undef },
                { branch => [map {"  $_"} qw{master origin/master}] },
                { log    => "1411637048\x{1}0000000000000000000000000000000000000000" },
                { branch => [map {"  $_"} qw{master origin/master}] },
                { log    => ['1414746381 <Ivan Wills>ivan.wills@gmail.com'] },
                { log    => ['1414746381 <Ivan Wills>ivan.wills@gmail.com'] },
                { config => 'http://example.com/example.git' },
            ],
            STD => {
                OUT => {
                   branches => [
                      {
                         last_author => '<Ivan Wills>ivan.wills@gmail.com',
                         release_age => 0,
                         name => 'master',
                         status => 'origin/master'
                      },
                      {
                         release_age => 0,
                         name => 'origin/master',
                         status => 'origin/master',
                         last_author => '<Ivan Wills>ivan.wills@gmail.com'
                      }
                   ],
                   release => 'origin/master',
                   repository => 'http://example.com/example.git',
                   release_date => ''.localtime(1411637048),
                   name => '//example.com/example'
                },
                OUT_PRE => sub { JSON::decode_json($_[0]) },
                ERR => '',
            },
            option => {
                format      => 'json',
                max_history => 1,
                branches    => 1,
            },
            name   => 'Show json',
            skip   => sub { !eval { require JSON; }; },
        },
        {
            ARGV => [qw{current}],
            mock => [
                { config => undef },
                { config => undef },
                { branch => [map {"  $_"} qw{master origin/master}] },
                { log    => "1411637048\x{1}0000000000000000000000000000000000000000" },
            ],
            STD => {
                OUT => qq{Current prod "origin/master"\n},
                ERR => '',
            },
            option => {
                format      => 'test',
                max_history => 1,
                branches    => 0,
            },
            name   => 'current',
        },
        {
            ARGV => [qw{update-me}],
            mock => [
                { config => undef },
                { config => undef },
                { branch => [map {"  $_"} qw{master origin/master}] },
                { log    => "1411637048\x{1}0000000000000000000000000000000000000000" },
                { merge  => undef },
            ],
            STD => {
                OUT => qq{Merging "origin/master"\n},
                ERR => '',
            },
            option => {
                format      => 'test',
                max_history => 1,
                branches    => 0,
            },
            name   => 'update-me',
        },
    );

    for my $data (@data) {
        next if $only && $data->{name} ne $only;
        command_ok('App::Git::Workflow::Command::UpToDate', $data)
            or return;
    }
}
