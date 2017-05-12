#!perl

use strict;
use warnings;
use utf8;
use Capture::Tiny qw/capture/;
use App::pmdeps;

use Test::More;

subtest 'show usage' => sub {
    subtest 'dies ok' => sub {
        my ($got) = capture {
            eval { App::pmdeps->new->show_usage() };
        };
        ok $@;
    };

    subtest 'by short option' => sub {
        my ($got) = capture {
            eval { App::pmdeps->new->run('-h') };
        };
        like( $got, qr/^Usage:\n/ );
    };

    subtest 'by long option' => sub {
        my ($got) = capture {
            eval { App::pmdeps->new->run('--help') };
        };
        like( $got, qr/^Usage:\n/ );
    };

    subtest 'by illegal option' => sub {
        my ($got) = capture {
            eval { App::pmdeps->new->run('--I_AM_ILLEGAL') };
        };
        like( $got, qr/^Usage:\n/ );
    };
};

done_testing;
