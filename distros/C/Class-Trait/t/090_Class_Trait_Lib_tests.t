#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 20;

BEGIN {
    unshift @INC => ('t');
}

# this will test if

BEGIN {

    package Test::Class::LoadingTraitsWithColonsInThem;
    use Class::Trait qw(Test::LoadingTraitsWithColonsInThem);

    sub new { bless {} }
}

{
    can_ok( "Test::Class::LoadingTraitsWithColonsInThem", 'new' );
    my $test = Test::Class::LoadingTraitsWithColonsInThem->new();

    can_ok( $test, 'does' );
    ok(
        $test->does('Test::LoadingTraitsWithColonsInThem'),
        '... our trait was compiled successfully'
    );

    can_ok( $test, 'isLoaded' );
    is(
        $test->isLoaded(),
        'Test::LoadingTraitsWithColonsInThem',
        '... and our trait method is as we expected'
    );
}

BEGIN {

    package Test::Class::Another::ColonInTheName;
    use Class::Trait qw(Test::Another::ColonInTheName);

    sub new { bless {} }
}

{
    can_ok( "Test::Class::Another::ColonInTheName", 'new' );
    my $test = Test::Class::Another::ColonInTheName->new();

    can_ok( $test, 'does' );
    ok(
        $test->does('Test::Another::ColonInTheName'),
        '... our trait was compiled successfully'
    );

    can_ok( $test, 'isLoaded' );
    is(
        $test->isLoaded(),
        'Test::Another::ColonInTheName',
        '... and our trait method is as we expected'
    );
}

# test some of the Trait lib

{

    package Test::TEquality;

    use Class::Trait qw(TEquality);

    sub new {
        my ( $class, $num ) = @_;
        return bless { num => $num }, $class;
    }

    sub equalTo {
        my ( $left, $right ) = @_;
        if ( ref($right) ) {
            return $left->{num} == $right->{num};
        }
        else {
            return $left->{num} == $right;
        }
    }

}

# test TEquality
{
    my $test1 = Test::TEquality->new(5);
    my $test2 = Test::TEquality->new(5);
    my $test3 = Test::TEquality->new(10);

    ok( ( $test1 == $test2 ), '... our values compare correctly' );
    ok( ( $test2 == 5 ),      '... our values compare correctly' );
    ok( ( $test1 != $test3 ), '... our values compare correctly' );

    ok( $test1->isSameTypeAs($test2), '... our objects are the same type' );
    ok( !$test1->isSameTypeAs("test"),
        '... our objects are not the same type' );

    ok( $test1->isExactly($test1), '... our objects are the same type' );
    ok( !$test1->isExactly($test2), '... our objects not are the same type' );
}

{

    package Test::TComparable;

    use Class::Trait qw(TComparable);

    sub new {
        my ( $class, $num ) = @_;
        return bless { num => $num }, $class;
    }

    sub compare {
        my ( $left, $right ) = @_;
        return $left->{num} <=> $right->{num};
    }

}

{
    my $test1 = Test::TComparable->new(1);
    my $test2 = Test::TComparable->new(5);
    my $test3 = Test::TComparable->new(10);

    my @sorted = sort { $a <=> $b } $test3, $test1, $test2;
    is( "$sorted[0]", "$test1", '... got the right first item' );
    is( "$sorted[1]", "$test2", '... got the right second item' );
    is( "$sorted[2]", "$test3", '... got the right third item' );

}

