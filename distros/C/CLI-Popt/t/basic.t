#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Deep;
use Test::Fatal;

use CLI::Popt;

{
    my $popt = CLI::Popt->new(
        [
        {
            long_name  => 'foo',
            short_name => 'f',
            type       => 'int',
            descrip => 'This is my description of foo. It is a very long description that should be line-wrapped in some way. I’m not sure how it works, but this is my description’s real, true, and final END.',
            arg_descrip => 'foo-number'
        },
        {
            long_name  => 'bar',
            short_name => 'b',
        },
        {
            long_name => 'toggleme',
            flags     => ['toggle'],
            type      => 'val',
            val       => -42,
        },
        {
            long_name  => 'qux',
            short_name => 'q',
            type       => 'argv',
        },
        {
            long_name  => 'zoo',
            short_name => 'z',
            type       => 'string',
        },
        ],
        name => 'this-is-my-name',
    );

    cmp_deeply(
        $popt->get_help(),
        all(
            re( qr<foo-number> ),
            re( qr<--foo> ),
            re( qr<[^-]-f[^o]> ),
            re( qr<This is my.*\n.*END>ms ),

            re( qr<[^-]-b[^a]> ),
            re( qr<--bar> ),

            none( re( qr<[^-]-t[^o]> ) ),
            re( qr<--.*no[^\n]+toggle> ),

            re( qr<[^-]-q[^u]> ),
            re( qr<--qux> ),

            re( qr<[^-]-z[^o]> ),
            re( qr<--zoo> ),
        ),
        'get_help() output',
    );

    my @got = $popt->parse(
        '--qux', '--bar baz --foo',
        '--qux', 'ree - dux',
        '--foo=7',
        '--bar',
        '--toggleme',
        qw(--zoo haha),
        qw(    one two three ),
    );

    cmp_deeply(
        \@got,
    [
        {
            foo        => 7,
            bar        => bool(1),
            'qux'      => [
                '--bar baz --foo',
                'ree - dux',
            ],
            'toggleme' => -42,
            'zoo'      => 'haha'
        },
        qw( one two three ),
    ],
        'parse() as expected',
    ) or diag explain \@got;

    my $err = exception {
        diag explain [ $popt->parse('--zzz') ]
    };

    cmp_deeply(
        $err,
        all(
            Isa('CLI::Popt::X::BadOption'),
            methods(
                [ get => 'option' ] => '--zzz',
                [ get => 'error_code' ] => re( qr<\A-?[0-9]+\z> ),
                [ get => 'error_desc' ] => re( qr<[a-z]+>),
            ),
        ),
        'bad option: expected error thrown',
    ) or diag explain $err;
}

done_testing;

1;
