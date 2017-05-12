#!/usr/bin/perl -w

use strict;

use Test::More;
plan tests => 34;

use DateTime;
use DateTime::Set;

my $future = DateTime::Infinite::Future->new();
my $past   = DateTime::Infinite::Past->new();
my $t1     = new DateTime( year => '1810', month => '11', day => '22' );
my $t2     = new DateTime( year => '1900', month => '11', day => '22' );

# Set tests

{
    my $set1 = DateTime::Set->from_datetimes( dates => [ $t1, $t2 ] );

    ok( $set1->min->ymd eq '1810-11-22',   'min is ' . $set1->min->ymd );
    ok( $set1->max->ymd eq '1900-11-22',   'max is ' . $set1->max->ymd );
    ok( $set1->start->ymd eq '1810-11-22', 'start is ' . $set1->start->ymd );
    ok( $set1->end->ymd eq '1900-11-22',   'end is ' . $set1->end->ymd );
}

{
    my $set1 = DateTime::Set->from_datetimes( dates => [ $past, $future ] );

    ok( $set1->min->is_infinite,   'min is infinite' );
    ok( $set1->max->is_infinite,   'max is infinite' );
    ok( $set1->start->is_infinite, 'start is infinite' );
    ok( $set1->end->is_infinite,   'end is infinite' );
}

{
    my $set1 = DateTime::Set->from_datetimes( dates => [] );

    ok( !defined $set1->min,   'min is undef' );
    ok( !defined $set1->max,   'max is undef' );
    ok( !defined $set1->start, 'start is undef' );
    ok( !defined $set1->end,   'end is undef' );
}

# Span tests

{
    my $set1 = DateTime::Span->from_datetimes( start => $t1, end => $t2  );

    ok( $set1->min->ymd eq '1810-11-22',   'min is ' . $set1->min->ymd );
    ok( $set1->max->ymd eq '1900-11-22',   'max is ' . $set1->max->ymd );
    ok( $set1->start->ymd eq '1810-11-22', 'start is ' . $set1->start->ymd );
    ok( $set1->end->ymd eq '1900-11-22',   'end is ' . $set1->end->ymd );
}

{
    my $set1 = DateTime::Span->from_datetimes( start => $past, end => $future  );

    ok( $set1->min->is_infinite,   'min is infinite' );
    ok( $set1->max->is_infinite,   'max is infinite' );
    ok( $set1->start->is_infinite, 'start is infinite' );
    ok( $set1->end->is_infinite,   'end is infinite' );
}

{
    my $set1 = DateTime::Span->from_datetimes( start => $past );

    ok( $set1->max->is_infinite,   'max is infinite' );
    ok( $set1->end->is_infinite,   'end is infinite' );
}

# SpanSet tests

{
    my $set1 = DateTime::SpanSet->from_spans( spans => [ DateTime::Set->from_datetimes( dates => [ $t1, $t2 ] ) ] );

    ok( $set1->min->ymd eq '1810-11-22',   'min is ' . $set1->min->ymd );
    ok( $set1->max->ymd eq '1900-11-22',   'max is ' . $set1->max->ymd );
    ok( $set1->start->ymd eq '1810-11-22', 'start is ' . $set1->start->ymd );
    ok( $set1->end->ymd eq '1900-11-22',   'end is ' . $set1->end->ymd );
}

{
    my $set1 = DateTime::SpanSet->from_spans( spans => [ DateTime::Set->from_datetimes( dates => [ $past, $future ] ) ] );

    ok( $set1->min->is_infinite,   'min is infinite' );
    ok( $set1->max->is_infinite,   'max is infinite' );
    ok( $set1->start->is_infinite, 'start is infinite' );
    ok( $set1->end->is_infinite,   'end is infinite' );
}

{
    my $set1 = DateTime::SpanSet->from_spans( spans => [ ] );

    ok( !defined $set1->min,   'min is undef' );
    ok( !defined $set1->max,   'max is undef' );
    ok( !defined $set1->start, 'start is undef' );
    ok( !defined $set1->end,   'end is undef' );
}

1;

