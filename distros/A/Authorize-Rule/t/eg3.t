#!perl

use strict;
use warnings;

use Test::More tests => 11;
use Authorize::Rule;

my $auth = Authorize::Rule->new(
    default => -1,
    rules   => {
        cats => {
            bedroom => [ [0] ],
            ''      => [ [1] ],
        },

        dogs => {
            table          => [ [0] ],
            bedroom        => [ [0] ],
            'laundry room' => [ [0] ],
            ''             => [ [1] ],
        },

        kitties => {
            bedroom => [ [1] ],
            ''      => [ [0] ],
        },
    }
);

isa_ok( $auth, 'Authorize::Rule' );
can_ok( $auth, 'is_allowed'      );

my @tests = (
    [ qw<1 cats   kitchen> ],
    [ qw<0 cats   bedroom> ],
    [ qw<1 dogs   kitchen> ],
    [ qw<0 dogs   table>   ],
    [ qw<0 dogs   bedroom> ],
    [ qw<0 dogs>, 'laundry room' ],
    [ qw<0 kitties kitchen> ],
    [ qw<0 kitties table>   ],
    [ qw<1 kitties bedroom> ],
);

foreach my $test (@tests) {
    my ( $success, $entity, $resource ) = @{$test};
    my $description = "$entity " . ( $success ? 'can' : 'cannot' ) .
                      " access $resource";

    cmp_ok(
        $auth->is_allowed( $entity => $resource ),
        '==',
        $success,
        $description,
    );
}

