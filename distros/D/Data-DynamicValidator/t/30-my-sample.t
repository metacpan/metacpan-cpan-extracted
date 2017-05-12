use strict;
use warnings;

use Test::More;
use Test::Warnings;

use Data::DynamicValidator qw/validator/;
use List::MoreUtils qw/all any/;
use Net::hostent;
use Scalar::Util qw/looks_like_number/;

my $cfg = {

    features => [
        "a/f",
        "application/feature1",
        "application/feature2",
    ],

    service_points => {
        localhost => {
            "a/f" => {
                job_slots => 3,
            },
            "application/feature1" => {
                job_slots => 5,
            },
            "application/feature2" => {
                job_slots => 5,
            },
        },
        "127.0.0.1" => {
            "application/feature2" => {
                job_slots => 5,
            },
        },

    },

    mojolicious => {
    	hypnotoad => {
            pid_file => '/tmp/hypnotoad-ng.pid',
            listen  => [
                'http://localhost:3000',
            ],
        },
    },
};


subtest 'my-positive' => sub {
    my $errors = validator($cfg)->(
        on      => '/features/*',
        should  => sub { @_ > 0 },
        because => "at least one feature should be defined",
        each    => sub {
            my $f = $_->();
            shift->(
                on      => "//service_points/*/`$f`/job_slots",
                should  => sub { defined($_[0]) && $_[0] > 0 },
                because => "at least 1 service point should be defined for feature '$f'",
            )
        }
    )->rebase('/service_points' => sub {
        shift->(
            on      => '/sp:*',
            should  => sub { @_ > 0 },
            because => "at least one service point should be defined",
            each    => sub {
                my $sp;
                shift->report_error("SP '$sp' isn't resolvable")
                    unless gethost($sp);
            }
        )->(
            on      => '/sp:*/f:*',
            should  => sub { @_ > 0 },
            because => "at least one feature under service point should be defined",
            each    => sub {
                my ($sp, $f);
                shift->(
                    on      => "//features/`*[value eq '$f']`",
                    should  => sub { 1 },
                    because => "Feature '$f' of service point '$sp' should be decrlared in top-level features list",
                )
            },
        )
    })->rebase('/mojolicious/hypnotoad' => sub {
        shift->(
            on      => '/pid_file',
            should  => sub { @_ == 1 },
            because => "hypnotoad pid_file should be defined",
        )->(
            on      => '/listen/*',
            should  => sub { @_ > 0 },
            because => "hypnotoad listening interfaces defined",
        );
    })->errors;
    is_deeply $errors, [], "no errors on valid data";
};

subtest 'my-demo-test' => sub {
    my $data = {
        ports => [2000, 3000],
        2000  => 'tcp',
        3000  => 'udp',
    };
    my $errors = validator($data)->(
        on      => '/ports/*[value > 1000 ]',
        should  => sub { @_ > 0 },
        because => 'At least one port > 1000 should be defined in "ports" section',
        each    => sub {
            my $port = $_->();
            shift->(
                on      => "//*[key eq $port]",
                should  => sub { @_ == 1 && any { $_[0] eq $_ } (qw/tcp udp/)  },
                because => "The port $port should be declated at top-level as tcp or udp",
            )
        }
    )->errors;
    is_deeply $errors, [], "no errors on valid data";
};

done_testing;
