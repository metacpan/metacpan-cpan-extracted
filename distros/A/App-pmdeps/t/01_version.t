#!perl

use strict;
use warnings;
use utf8;
use Capture::Tiny qw/capture/;
use App::pmdeps;

use Test::More;

subtest 'show version' => sub {
    subtest 'dies ok' => sub {
        my ($got) = capture {
            eval { App::pmdeps->new->show_version() };
        };
        ok $@;
    };

    subtest 'by short option' => sub {
        my ($got) = capture {
            eval { App::pmdeps->new->run('-v') };
        };
        is( $got, "pm-deps (App::pmdeps): v$App::pmdeps::VERSION" );
    };

    subtest 'by long option' => sub {
        my ($got) = capture {
            eval { App::pmdeps->new->run('--version') };
        };
        is( $got, "pm-deps (App::pmdeps): v$App::pmdeps::VERSION" );
    };
};

done_testing;
