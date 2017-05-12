#!perl

use strict;
use warnings;
use utf8;
use Capture::Tiny qw/capture/;
use App::pmdeps;

use Test::More;

subtest 'show short usage' => sub {
    subtest 'dies ok' => sub {
        my ($got) = capture {
            eval { App::pmdeps->new->show_short_usage };
        };
        ok $@;
    };

    subtest 'when argument is empty' => sub {
        my ($got) = capture {
            eval { App::pmdeps->new->run() };
        };
        like( $got, qr/^Usage: pm-deps \[options\] Module \[module_version\]\n/ );
    };
};

done_testing;
