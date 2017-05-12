#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 8646;

BEGIN {
    use_ok('AlignDB::IntSpan');
}

# Basic hash based set for testing

package TestSet;

sub new {
    return bless {}, shift;
}

sub add {
    my $self = shift;
    $self->{$_} = 1 for @_;
}

sub add_range {
    my $self = shift;
    die unless ( @_ % 2 ) == 0;
    while ( my ( $from, $to ) = splice( @_, 0, 2 ) ) {
        die unless $from <= $to;
        $self->add( $from .. $to );
    }
}

sub remove {
    my $self = shift;
    delete $self->{$_} for @_;
}

sub remove_range {
    my $self = shift;
    die unless ( @_ % 2 ) == 0;
    while ( my ( $from, $to ) = splice( @_, 0, 2 ) ) {
        die unless $from <= $to;
        $self->remove( $from .. $to );
    }
}

sub as_array_ref {
    my $self = shift;
    return [ sort { $a <=> $b } map { 1 * $_ } keys %$self ];
}

# Extend AlignDB::IntSpan

package AlignDB::IntSpan;

sub as_array_ref {
    my $self = shift;
    return [ $self->as_array() ];
}

sub is_sane {
    my $self = shift;
    my $last = undef;
    my $urk  = 0;
    my @ranges = $self->ranges();
    while ( @ranges ) {
        my $from = shift @ranges;
        my $to = shift @ranges;
        if ( $from > $to ) {
            warn "elements out of order ($from, $to)";
            $urk++;
        }
        if ( defined($last) && $from <= $last + 1 ) {
            warn "runs overlap ($last, $from)";
            $urk++;
        }
        $last = $to;
    }
    return $urk;
}

package main;

# Simple cases - two ranges overlapping in various ways
for my $i ( -5 .. 5 ) {
    for my $j ( $i .. 5 ) {
        my @set = ( AlignDB::IntSpan->new, TestSet->new );
        $_->add_range( -2, 2 ) for @set;
        is_deeply(
            $set[0]->as_array_ref(),
            $set[1]->as_array_ref(),
            "add init range"
        );
        $_->add_range( $i, $j ) for @set;
        is_deeply(
            $set[0]->as_array_ref(),
            $set[1]->as_array_ref(),
            "add $i to $j"
        );
        is( $set[0]->is_sane(), 0, "sanity check" );
    }
}

# More complex cases - multiple overlaps
for my $i ( -20 .. 20 ) {
    for my $j ( $i .. 20 ) {
        my @set = ( AlignDB::IntSpan->new, TestSet->new );
        for my $s (@set) {
            my $gap = 0;
            my $pos = -18;
            while ( $pos < 18 ) {
                $s->add_range( $pos, $pos + $gap );
                $pos += $gap * 2;
                $gap++;
            }

            # Half the time add an extra element
            if ( $j & 1 ) {
                $s->add_range( $pos, $pos );
            }
        }
        is_deeply(
            $set[0]->as_array_ref(),
            $set[1]->as_array_ref(),
            "add init range"
        );
        $_->add_range( $i, $j ) for @set;
        is_deeply(
            $set[0]->as_array_ref(),
            $set[1]->as_array_ref(),
            "add $i to $j"
        );
        is( $set[0]->is_sane(), 0, "sanity check" );
    }
}

# Simple cases - two ranges overlapping in various ways
for my $i ( -5 .. 5 ) {
    for my $j ( $i .. 5 ) {
        my @set = ( AlignDB::IntSpan->new, TestSet->new );
        $_->add_range( -2, 2 ) for @set;
        is_deeply(
            $set[0]->as_array_ref(),
            $set[1]->as_array_ref(),
            "add init range"
        );
        $_->remove_range( $i, $j ) for @set;
        is_deeply(
            $set[0]->as_array_ref(),
            $set[1]->as_array_ref(),
            "remove $i to $j"
        );
        is( $set[0]->is_sane(), 0, "sanity check" );
    }
}

# More complex cases - multiple overlaps
for my $i ( -20 .. 20 ) {
    for my $j ( $i .. 20 ) {
        my @set = ( AlignDB::IntSpan->new, TestSet->new );
        for my $s (@set) {
            my $gap = 0;
            my $pos = -18;
            while ( $pos < 18 ) {
                $s->add_range( $pos, $pos + $gap );
                $pos += $gap * 2;
                $gap++;
            }

            # Half the time add an extra element
            if ( $j & 1 ) {
                $s->add_range( $pos, $pos );
            }
        }
        is_deeply(
            $set[0]->as_array_ref(),
            $set[1]->as_array_ref(),
            "add init range"
        );
        $_->remove_range( $i, $j ) for @set;
        is_deeply(
            $set[0]->as_array_ref(),
            $set[1]->as_array_ref(),
            "remove $i to $j"
        );
        is( $set[0]->is_sane(), 0, "sanity check" );
    }
}

# Some psuedorandom cases
srand(1);
for ( 1 .. 500 ) {
    my @set = ( AlignDB::IntSpan->new, TestSet->new );
    my @add = map { ( $_, $_ + int( rand(10) ) ) }
        map { int( rand(10) ) } ( 1 .. int( rand(17) ) );
    my @rem = map { ( $_, $_ + int( rand(10) ) ) }
        map { int( rand(10) ) } ( 1 .. int( rand(17) ) );
    $_->add_range(@add)    for @set;
    $_->remove_range(@rem) for @set;
    is_deeply(
        $set[0]->as_array_ref(),
        $set[1]->as_array_ref(),
        "random ranges"
    );
}

# add and remove object
for my $i ( -20 .. 20 ) {
    for my $j ( $i .. 20 ) {
        my @set = ( AlignDB::IntSpan->new, TestSet->new );
        {
            my $gap = 0;
            my $pos = -18;
            while ( $pos < 18 ) {
                my $t = AlignDB::IntSpan->new;
                $t->add_range($pos, $pos + $gap);
                $set[0]->add( $t);
                $pos += $gap * 2;
                $gap++;
            }

            # Half the time add an extra element
            if ( $j & 1 ) {
                $set[0]->add( AlignDB::IntSpan->new($pos) );
            }
        }
        {
            my $gap = 0;
            my $pos = -18;
            while ( $pos < 18 ) {
                $set[1]->add_range( $pos, $pos + $gap );
                $pos += $gap * 2;
                $gap++;
            }

            # Half the time add an extra element
            if ( $j & 1 ) {
                $set[1]->add_range( $pos, $pos );
            }
        }
        is_deeply(
            $set[0]->as_array_ref(),
            $set[1]->as_array_ref(),
            "add init range"
        );
        
        {
            my $t = AlignDB::IntSpan->new;
            $t->add_range($i, $j);
            $set[0]->remove($t);
        }
        {
            $set[1]->remove_range( $i, $j )
        }
        is_deeply(
            $set[0]->as_array_ref(),
            $set[1]->as_array_ref(),
            "remove $i to $j"
        );
        is( $set[0]->is_sane(), 0, "sanity check" );
    }
}
