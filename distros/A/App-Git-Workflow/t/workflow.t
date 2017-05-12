#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Data::Dumper qw/Dumper/;
use lib 't/lib';
use App::Git::Workflow;
use Mock::App::Git::Workflow::Repository;

my $pom = App::Git::Workflow->new();
my $git = Mock::App::Git::Workflow::Repository->git;
$pom->{git} = $git;

test_branches();
test_tags();
test_config();
test_current();
test_match_commits();
test_release();
test_releases();
test_runner();
test_commit_details();
test_files_from_sha();
test_slurp();
test_spew();
test_settings();
test_save_settings();
test_url_encode();
done_testing();

sub test_branches {
    ok !eval{ $pom->branches('bad') } && $@, 'Bad branch type throws error';

    $git->mock_add({ branch => [map {"  $_"} qw{master abc_123} ]});
    is_deeply [$pom->branches()], [$pom->branches], "Two calls to branches uses cache";

}

sub test_tags {
    my @data = (
        [
            { tag => [qw /
                1.0
                10.0
                0.1
                v0.1
            /]},
            [qw /
                0.1
                1.0
                10.0
                v0.1
            /],
        ]
    );

    for my $data (@data) {
        $git->mock_add($data->[0]);
        is_deeply [$pom->tags()], $data->[1], "Get the sorted tags"
            or diag Dumper [$pom->tags()], $data->[1];
    }
}

sub test_config {
}

sub test_current {
    my @data = (
        [
            'git-simple',
            [qw'branch master'],
        ],
        [
            'git-tag',
            [qw'sha 55d0295a1227f591afc683dd12e43823cd2e404d'],
        ],
        [
            'git-branch',
            [qw'branch origin/master'],
        ],
    );

    for my $data (@data) {
        $git->mock_reset();
        $git->mock_add({ 'rev-parse' => 't/data' });
        $pom->{branches} = {};
        $pom->{tags}     = [];
        $pom->{GIT_DIR}  = $data->[0];
        my $ans = [$pom->current()];
        is_deeply $ans, $data->[1], "Get the current $data->[0]"
            or diag Dumper $ans, $data->[1];
    }
}

sub test_match_commits {
    return;
    my @data = (
        [
            [
                [qw{1.0 2.0 3.0}],
                [qw{master origin/master}],
            ],
            [qw/tag ./],
            [{
                branches => {},
                sha      => undef,
                user     => 'test user',
                email    => 'test@example.com',
                files    => {},
                name     => '3.0',
                time     => time,
            }],
        ],
        [
            [
                [qw{master origin/master}],
            ],
            [qw/branch ./],
            [{
                branches => {},
                sha      => undef,
                user     => 'test user',
                email    => 'test@example.com',
                files    => {},
                name     => '3.0',
                time     => time,
            }],
        ],
    );

    TODO:
    for my $data (@data) {
        local $TODO = 'Need to decide if this even needs to exits';
        $git->mock_reset();
        $git->mock_add(@{ $data->[0] });
        $pom->{branches} = {};
        $pom->{tags}     = [];
        my $ans = [$pom->match_commits(@{$data->[1]})];
        is_deeply $ans, $data->[2], "Get the commits for $data->[1][0]"
            or diag Dumper $ans, $data->[2];
    }
}

sub test_release {
    my @data = (
        [
            [
                { tag => [qw{1.0 10.0 2.0 3.0 ZZZ}] },
            ],
            [qw/tag local/, qr/^\d+/],
            '10.0',
        ],
        [
            [
                { branch => [map {"  $_"} qw{origin/other origin/master}] },
            ],
            [qw/branch remote/, qr/master/],
            'origin/master',
        ],
    );

    for my $data (@data) {
        $git->mock_reset();
        $git->mock_add(@{ $data->[0] });
        $pom->{branches} = {};
        $pom->{tags}     = [];
        my $ans = $pom->release(@{$data->[1]});
        is_deeply $ans, $data->[2], "Get the commits for $data->[1][0]"
            or diag Dumper $ans, $data->[2];
    }
}

sub test_releases {
    my @data = (
        [
            [
                { tag    => [qw/not-release v3.0 v1.0 v1.1 v2.0/] },
                { 'rev-list' => ['1405968782 55d0295a1227f591afc683dd12e43823cd2e404d'] },
                { branch => [map {"  $_"} qw{master origin/master}] },
            ],
            { tag => '^v\d+(?:[.]\d+)*$' },
            [
                {
                    branches => {
                        master          => 1,
                        'origin/master' => 1
                    },
                    files => {},
                    user  => '',
                    time  => '1405968782',
                    name  => 'v3.0',
                    email => '',
                    sha   => '55d0295a1227f591afc683dd12e43823cd2e404d'
                }
            ],
        ],
        [
            [
                { branch => [map {"  $_"} qw{master origin/master origin/R1.0 origin/R2.0 origin/R3.0}] },
                { 'rev-list' => ['1405968782 55d0295a1227f591afc683dd12e43823cd2e404d'] },
                { branch => [map {"  $_"} qw{origin/R1.0 origin/R2.0 origin/R3.0}] },
            ],
            { branch => '^origin/R\d+(?:[.]\d+)*$' },
            [
                {
                    branches => {
                        map {$_ => 1} qw{origin/R1.0 origin/R2.0 origin/R3.0},
                    },
                    files => {},
                    user  => '',
                    time  => '1405968782',
                    name  => 'origin/R3.0',
                    email => '',
                    sha   => '55d0295a1227f591afc683dd12e43823cd2e404d'
                }
            ],
        ],
        [
            [
                { config => undef },
                { branch => [map {"  $_"} qw{master origin/master origin/R1.0 origin/R2.0 origin/R3.0}] },
                { 'rev-list' => ['1405968782 55d0295a1227f591afc683dd12e43823cd2e404d'] },
                { branch => [map {"  $_"} qw{master origin/master origin/R1.0 origin/R2.0}] },
            ],
            { local => 1 },
            [
                {
                    branches => {
                        map {$_ => 1} qw{master origin/master origin/R1.0 origin/R2.0},
                    },
                    files => {},
                    user  => '',
                    time  => '1405968782',
                    name  => 'master',
                    email => '',
                    sha   => '55d0295a1227f591afc683dd12e43823cd2e404d'
                }
            ],
        ],
        [
            [
                { config => '?' },
                { branch => [map {"  $_"} qw{master origin/master origin/R1.0 origin/R2.0 origin/R3.0}] },
                { 'rev-list' => ['1405968782 55d0295a1227f591afc683dd12e43823cd2e404d'] },
                { branch => [map {"  $_"} qw{master origin/master origin/R1.0}] },
            ],
            { local => 1 },
            [
                {
                    branches => {
                        map {$_ => 1} qw{master origin/master origin/R1.0},
                    },
                    files => {},
                    user  => '',
                    time  => '1405968782',
                    name  => 'origin/master',
                    email => '',
                    sha   => '55d0295a1227f591afc683dd12e43823cd2e404d'
                }
            ],
        ],
    );

    for my $data (@data) {
        $git->mock_reset();
        $git->mock_add(@{ $data->[0] });
        $pom->{branches} = {};
        $pom->{tags}     = [];
        my $ans = [ $pom->releases(%{$data->[1]}) ];
        is_deeply $ans, $data->[2], "Get the releases"
            or diag Dumper $ans, $data->[2];
    }
}

sub test_runner {
}

sub test_commit_details {
}

sub test_files_from_sha {
    my @data = (
        [
            [{ show => <<'SHOW'
commit 4614a57568bb1889138bfab239d2e82b5b6bc338
Author: Ivan Wills <ivan.wills@gmail.com>
Date:   Sun Sep 14 16:54:22 2014 +1000

    Added more tests

A   t/slurp.txt
M   t/workflow.t
SHOW
            }],
            [qw/4614a57568bb1889138bfab239d2e82b5b6bc338/],
            {
                't/slurp.txt'  => 'A',
                't/workflow.t' => 'M',
            },
        ],
    );

    for my $data (@data) {
        $git->mock_reset();
        $git->mock_add(@{ $data->[0] });
        $pom->{branches} = {};
        $pom->{tags}     = [];
        my $ans = $pom->files_from_sha(@{$data->[1]});
        is_deeply $ans, $data->[2], "Get the commits for $data->[1][0]"
            or diag Dumper $ans, $data->[2];
    }
}

sub test_slurp {
    is +(scalar $pom->slurp('t/data/slurp.txt')), "true\n", 'Can slurp a file';
}

sub test_spew {
    SKIP: {
        skip "Can't wright to directory", 1 if !-w 't';
        my $file = 't/data/spew.txt';
        unlink $file if -f $file;
        $pom->spew($file, "test");
        is -s $file, 4, 'Wrote to file';
        unlink $file;
    }
}

sub test_settings {
}

sub test_save_settings {
}

sub test_url_encode {
    my @data = (
        [qw{? %3f}],
        [qw{: :}],
    );
    for my $data (@data) {
        is $pom->_url_encode($data->[0]), $data->[1], "Encode '$data->[0]' correctly"
            or diag join "\t", @$data;
    }
}
