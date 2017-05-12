use strict;

use lib 't/lib';

use Test::More tests => 33;

my ($CLASS, $TEST);
BEGIN {
    $CLASS = 'Class::LazyLoad';
    $TEST = 'Test3';

    use_ok( 'Test3' );
}

# Test reading ...
foreach my $type ( 'scalar', 'array', 'hash', 'sub' )
{
    my $obj1 = $TEST->new( $type );

    isa_ok( $obj1, $TEST );
    is( ref($obj1), $CLASS, "... but it's really a $CLASS" );

    if ( $type eq 'scalar' ) {
        my $v = $$obj1;
    } elsif ( $type eq 'array' ) {
        my $v = $obj1->[1];
    } elsif ( $type eq 'hash' ) {
        my $v = $obj1->{foo};
    } elsif ( $type eq 'sub' ) {
        my $v = $obj1->();
    } else {
        die "Cannot handle '$type'\n";
    }

    isa_ok( $obj1, $TEST );
    is( ref($obj1), $TEST, "... and it's really a $TEST" );
}

# Test writing ...
foreach my $type ( 'scalar', 'array', 'hash', 'sub' )
{
    my $obj1 = $TEST->new( $type );

    isa_ok( $obj1, $TEST );
    is( ref($obj1), $CLASS, "... but it's really a $CLASS" );

    if ( $type eq 'scalar' ) {
        $$obj1 = 1;
    } elsif ( $type eq 'array' ) {
        $obj1->[1] = 1;
    } elsif ( $type eq 'hash' ) {
        $obj1->{foo} = 1;
    } elsif ( $type eq 'sub' ) {
#GGG How do you 'write' to a subroutine?
        my $v = $obj1->();
    } else {
        die "Cannot handle '$type'\n";
    }

    isa_ok( $obj1, $TEST );
    is( ref($obj1), $TEST, "... and it's really a $TEST" );
}
