#!perl

use strict;
use warnings;

use Test::More tests => 10;
use Authorize::Rule;

my $auth = Authorize::Rule->new(
    default => -1,
    rules   => {
        Bender => {
            'fly ship'     => [ [0] ],
            'command team' => [ [0] ],
            ''             => [ [1] ],
        },

        Leila => {
            'goof off'     => [ [0] ],
            'fly ship'     => [ [1] ],
            'command team' => [ [1] ],
        },
    },
);

isa_ok( $auth, 'Authorize::Rule' );
can_ok( $auth, 'is_allowed'      );

my @tests = (
    [ qw< 0 Bender>, 'fly ship'     ],
    [ qw< 0 Bender>, 'command team' ],
    [ qw< 1 Bender>, 'goof off'     ],
    [ qw< 1 Bender>, 'dance around' ],
    [ qw< 1 Leila>,  'fly ship'     ],
    [ qw< 1 Leila>,  'command team' ],
    [ qw< 0 Leila>,  'goof off'     ],
    [ qw<-1 Leila>,  'dance around' ],
);

foreach my $test (@tests) {
    my ( $success, $entity, $resource ) = @{$test};
    my $description = "$entity " . ( $success ? 'can' : 'cannot' ) .
                      " $resource";

    cmp_ok(
        $auth->is_allowed( $entity => $resource ),
        '==',
        $success,
        $description,
    );
}

