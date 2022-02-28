package main;

use 5.008004;

use strict;
use warnings;

use DateTime;
use DateTime::Calendar::Christian;
use List::Util 1.29 qw{ pairs };
use Test::More 0.88;	# Because of done_testing();

BEGIN {
    eval {
	require Class::Inspector;
	1;
    } or plan skip_all => 'Class::Inspector not available';
}

foreach my $pair ( pairs( qw{ DateTime::Calendar::Christian DateTime } ) ) {
    my $got = interface_hash( $pair->[0] );
    my $want = interface_hash( $pair->[1] );
    foreach my $key ( keys %{ $got } ) {
	exists $want->{$key}
	    or delete $got->{$key};
    }
    foreach my $name ( sort keys %{ $want } ) {
	ok $got->{$name}, "$pair->[0] implements $name from $pair->[1]";
    }
}

done_testing;

sub interface_hash {
    my ( $module ) = @_;
    # We consider only functions that begin with a lower-case letter to
    # be part of the interface.
    my $rslt = {
	map { $_ => 1 }
	grep { m/ \A [[:lower:]] /smx }
	@{ Class::Inspector->functions( $module ) || [] }
    };
    # Certain functions are not part of the interface.
    delete $rslt->{$_} for qw{ bootstrap };
    return $rslt;
}

1;

# ex: set textwidth=72 :
