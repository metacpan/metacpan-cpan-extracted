#!perl

use strict;
use warnings;

use Test::More tests => 10;
use Authorize::Rule;

my $auth = Authorize::Rule->new(
    default => -1,
    rules   => {
        CEO => {
            Payroll => [ [0] ],
            ''      => [ [1] ],
        },

        support => {
            UserPreferences      => [ [1] ],
            UserComplaintHistory => [ [1] ],
            ''                   => [ [0] ],
        },
    }
);

isa_ok( $auth, 'Authorize::Rule' );
can_ok( $auth, 'is_allowed'      );

my @tests = (
    [ qw<0 CEO     Payroll> ],
    [ qw<1 CEO     UserPreferences> ],
    [ qw<1 CEO     UserComplaintHistory> ],
    [ qw<1 CEO     SecretStuff> ],
    [ qw<0 support Payroll> ],
    [ qw<1 support UserPreferences> ],
    [ qw<1 support UserComplaintHistory> ],
    [ qw<0 support SecretStuff> ],
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

