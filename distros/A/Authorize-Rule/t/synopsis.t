#!perl

use strict;
use warnings;

use Test::More tests => 18;
use Authorize::Rule;

my $auth = Authorize::Rule->new(
    rules => {
        # Marge can do everything
        Marge => { '' => [ [1] ] },

        # Homer can do everything except go to the kitchen
        Homer => {
            oven => [ [0] ],
            ''   => [ [1] ],
        },

        # kids can clean and eat at the kitchen
        # but nothing else
        # and they can do whatever they want in their bedroom
        kids => {
            kitchen => [
                [ 1, { action => 'eat'   } ],
                [ 1, { action => 'clean' } ],
                [0],
            ],

            bedroom => [ [1] ],
        },
    },
);

isa_ok( $auth, 'Authorize::Rule' );
can_ok( $auth, 'is_allowed'      );

my @tests = (
    [ qw<1 Marge kitchen>               ],
    [ qw<1 Marge kitchen   clean>       ],
    [ qw<1 Marge kitchen   destroy>     ],
    [ qw<1 Marge closet>,  'dance in'   ],
    [ qw<1 Marge bedroom>, 'sunggle in' ],

    [ qw<1 Homer kitchen>               ],
    [ qw<1 Homer kitchen   roam>        ],
    [ qw<0 Homer oven>                  ],
    [ qw<0 Homer oven>,    'play with'  ],
    [ qw<1 Homer closet>                ],
    [ qw<1 Homer closet>,  'hide in'    ],
    [ qw<1 Homer bedroom>, 'sunggle in' ],

    [ qw<0 kids kitchen>           ],
    [ qw<1 kids kitchen>, 'eat in' ],
    [ qw<0 kids kitchen   destroy> ],
    [ qw<1 kids kitchen   clean>   ],
);

foreach my $test (@tests) {
    my ( $success, $entity, $resource, $action ) = @{$test};
    my $description = "$entity " . ( $success ? 'can'   : 'cannot' ) .
                      ' '        . ( $action  ? $action : 'access' ) .
                      " the $resource";

    $action and ($action) = split /\s/, $action;

    cmp_ok(
        $auth->is_allowed( $entity, $resource, { action => $action } ),
        '==',
        $success,
        $description
    );
}

