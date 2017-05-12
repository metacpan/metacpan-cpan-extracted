use strict;
use warnings;

use Test::More;
use Test::Exception;

require DateTimeX::Fiscal::Fiscal5253;
my $class = 'DateTimeX::Fiscal::Fiscal5253';

# This script only tests the accessors and not the values generated
# for the object other than the year parameter. Another script
# will perform those tests.

# Known params to test with.
my %params = (
    year        => 2014,
    end_month   => 1,
    end_dow     => 1,
    end_type    => 'closest',
    leap_period => 'first'
);

# Preparing an array of test cases makes it slightly easier, IMHO, to
# see what cases are being covered.
my @accessors = (
    {
        accessor => 'year',
        expect   => $params{year},
    },
    {
        accessor => 'end_month',
        expect   => $params{end_month},
    },
    {
        accessor => 'end_dow',
        expect   => $params{end_dow},
    },
    {
        accessor => 'end_type',
        expect   => $params{end_type},
    },
    {
        accessor => 'leap_period',
        expect   => $params{leap_period},
    },
    {
        accessor => 'start',
        expect   => '2013-01-29',
    },
    {
        accessor => 'end',
        expect   => '2014-02-03',
    },
    {
        accessor => 'weeks',
        expect   => '53',
    },
);

# Four times through the array
my $testplan = @accessors * 4;
plan( tests => $testplan );

# Get an object for testing with. Use values different from defaults
# to ensure the accessors are fetching real information.
my $fc = $class->new(%params);

# Test fetching the values. This tests that the accessors retrieve
# known values from the proper elements in the object.
foreach (@accessors) {
    my $accessor = $_->{accessor};
    cmp_ok( $fc->$accessor(), 'eq', $_->{expect}, "get $accessor" );
}

# Now test that trying to change a parameter value will emit a "croak"
foreach (@accessors) {
    my $accessor = $_->{accessor};
    throws_ok( sub { my $foo = $fc->$accessor( $_->{expect} ) },
        qr/$accessor/, "blocked setting $accessor" );
}

# Now do it all over again using the Empty::Fiscal5253 class to be sure
# this module can be safely sub-classed. A single test of the basic
# constructor would probably suffice, but why not be sure?

$class = 'Empty::Fiscal5253';
$fc    = $class->new(%params);

foreach (@accessors) {
    my $accessor = $_->{accessor};
    ok( $fc->$accessor() eq $_->{expect}, "get $accessor" );
}

foreach (@accessors) {
    my $accessor = $_->{accessor};
    throws_ok( sub { my $foo = $fc->$accessor( $_->{expect} ) },
        qr/$accessor/, "blocked setting $accessor" );
}

done_testing();

exit;

# package for empty package tests
package Empty::Fiscal5253;
use base qw(DateTimeX::Fiscal::Fiscal5253);

__END__
