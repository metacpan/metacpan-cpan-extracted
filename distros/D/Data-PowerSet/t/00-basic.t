# 00-basic.t
#
# Test suite for Data::PowerSet
# Make sure the basic stuff works
#
# copyright (C) 2005-2008 David Landgren

use strict;

eval qq{ use Test::More tests => 7 };
if( $@ ) {
    warn "# Test::More not available, no tests performed\n";
    print "1..1\nok 1\n";
    exit 0;
}

use Data::PowerSet;

my $Unchanged = 'The scalar remains the same';
$_ = $Unchanged;

diag( "testing Data::PowerSet v$Data::PowerSet::VERSION" );

{
    my $t = Data::PowerSet->new;
    ok( defined($t), 'new() defines ...' );
    ok( ref($t) eq 'Data::PowerSet', '... a Data::PowerSet object' );
}

{
    my @set = (11, 7, 5);
    my $t = Data::PowerSet->new( @set );
    cmp_ok( $t->{min},     '==', 0, 'default min', );
    cmp_ok( $t->{max},     '==', 3, 'default max', );
    cmp_ok( $t->count,     '==', 3, 'default count()', );
    cmp_ok( $t->{current}, '==', (2**@set)-1, 'default current' );
}

cmp_ok( $_, 'eq', $Unchanged, '$_ has not been altered' );
