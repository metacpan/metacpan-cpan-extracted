#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 30;
use Authorize::Rule;
use Data::Dumper;

$Data::Dumper::Terse  = 1;
$Data::Dumper::Indent = 0;

# * dev:
#   - can access everything except Payroll
# * admin:
#   - can access everything
# * biz_rel:
#   - cannot access Graphs
#   - can access Invoices (but not with user parameter)
#   - can access Revenue and Payroll
#   - can access Databases only when table is Reservations
# * support:
#   - can access Databases only when table is Complaints
#   - can access Invoices
# * sysadmins:
#   - can access Graphs

#ENTITY => [
#    RESOURCE => [
#        [ ACTION, RULE, RULE ],
#    ]
#]

my $rules = {
    dev => {
        Payroll => [ [0] ], # always deny
        ''      => [ [1] ], # default allow
    },

    tester => {
        '' => [
            'check tester' => [ 1, { is_test => 1 }, 'test_name', 'test_id' ],
            'default' => [0],
        ]
    },

    admin => { '' => [ [1] ] },

    biz_rel => {
        Graphs    => [ [0] ],
        Databases => [
            [ 1, { table => 'Reservations' } ],
        ],

        Invoices => [
            [ 0, 'user' ],
            [ 1         ],
        ],

        Payroll => [ [1] ],
        Revenue => [ [1] ],
        ''      => [ [0] ],
    },

    support => {
        Databases => [
            [ 1, { table => 'Complaints' } ],
        ],

        Invoices => [ [1] ],
        ''       => [ [0] ],
    },

    sysadmins => {
        Graphs => [ [1] ],
        ''     => [ [0] ],
    },
};


my $auth = Authorize::Rule->new( default => -1, rules => $rules );

isa_ok( $auth, 'Authorize::Rule' );
can_ok( $auth, 'is_allowed'      );

my @groups  = keys %{$rules};
my @sources = qw<Databases Graphs Invoices Revenue Payroll>;

my @tests = (
    [ qw<1 dev       Databases> ],
    [ qw<0 dev       Payroll>   ],
    [ qw<0 biz_rel   Graphs>    ],
    [ qw<1 biz_rel   Databases>, { table => 'Reservations' } ],
    [ qw<0 biz_rel   Databases>, { table => 'else'         } ],
    [ qw<0 biz_rel   Databases> ],
    [ qw<1 biz_rel   Invoices>  ],
    [ qw<0 biz_rel   Invoices>,  { user  => 'whatever'   } ],
    [ qw<1 support   Databases>, { table => 'Complaints' } ],
    [ qw<1 support   Invoices>  ],
    [ qw<0 support   Databases>, { table => 'Reservations' } ],
    [ qw<0 support   Databases> ],
    [ qw<1 sysadmins Graphs>    ],
    [ qw<0 tester    Databases> ],
    [ qw<0 tester    Invoices>, { is_test => 1 } ],
    [ qw<0 tester    Invoices>, { is_test => 1, test_name => 'hi' } ],
    [ qw<1 tester    Invoices>,
        { is_test => 1, test_name => 'hi', test_id => 30 } ],
    [ qw<1 tester    Invoices>,
        { is_test => 1, test_name => 'hi', test_id => 0 } ],
    [ qw<0 tester    Invoices>,
        { is_test => 1, test_name => undef, test_id => 30 } ],
);

# admin accesses everything
push @tests, map { [ qw<1 admin>, $_ ] } @sources;

# biz_rel has access to everything (excluding Graphs and Databases)
push @tests, map { [ qw<1 biz_rel>, $_ ] }
             grep { $_ ne 'Graphs' && $_ ne 'Databases' } @sources;

foreach my $test (@tests) {
    my ( $success, $entity, $resource, $params ) = @{$test};

    my $description = "$entity " . ( $success ? 'can'   : 'cannot' ) .
                      " access the $resource" .
                      ( $params ? ', params: ' . Dumper($params) : '' );

    cmp_ok(
        $auth->is_allowed( $entity, $resource, $params ),
        '==',
        $success,
        $description,
    );
}

is_deeply(
    $auth->allowed(
        'tester', 'Payroll',
        { test_id => 13, test_name => 'it', is_test => 1 }
    ),
    {
        entity      => 'tester',
        resource    => 'Payroll',
        params      => { test_id => 13, test_name => 'it', is_test => 1 },
        action      => 1,
        label       => 'check tester',
        ruleset_idx => 1,
    },
    'Ruleset labeling works',
);
