#===============================================================================
#
#  DESCRIPTION:  test for CLI::Gwrap.pm
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  07/09/2013 12:26:16 PM
#===============================================================================

use 5.008;
use strict;
use warnings;

use Test::More tests => 4;                      # last test to print
use IO::File;
use File::Spec;
use Readonly;

BEGIN {
    use_ok('CLI::Gwrap', qw(
        check
        radio
        string
        hash
        integer
        float
        incremental
        )
    );
}

# VERSION

my $cmd = 'ls';     # command to wrap
my $gwrap = new_ok(
    'CLI::Gwrap' => [
        command  => $cmd,
        columns  => 2,
        help => '--help',
        persist  => 1,
        main_opt    => hash(
            [
                '',         # this option has no name
                'pattern',  # alias (description)
            ],
            # 'hover' help
            qq[shell glob pattern to match file or directory names],
            state => 'XyZ',
        ),
        opts     => [
            string(
                'opt1',
                'description1',
                state => '1 1 1',
            ),
            check(
                'all',  # option name
                'do not ignore entries starting with .',
                label => 'all label',
            ),
            string(
                'opt2',
                'description2',
                width => 20,
            ),
            check(
                [
                    'l',   # option name
                    'long listing',     # short names can use some help
                ],
                'use a long listing format',
                state => 1,
            ),
        ],
        advanced    => [
            check(
                'almost-all',
                'do not list implied . and ..',
            ),
            radio(
                'color',
                qq[colorize the output. Defaults to 'always' or can be 'never' or 'auto'],
                choices => [
                    'never',    # the choices
                    'always',
                    'auto',
                ],
                state => 'auto',
            ),
        ]
    ],
);

is($gwrap->title, $cmd, 'title matches');
$gwrap->title("Gwrap $cmd");
is($gwrap->title, "Gwrap $cmd", 'title changed');

$gwrap->run if (@ARGV and $ARGV[0] eq 'run');
