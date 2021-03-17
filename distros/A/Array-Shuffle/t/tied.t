#!/usr/bin/perl

use strict;
use warnings;
use Array::Shuffle qw(shuffle_array);
use Data::Dumper;

use Test::More tests => 1;

my @src = 0..9;
my @ta;
tie @ta, "TA";
push @ta, @src;

shuffle_array(@ta);
is("@src", join(" ", sort { $a <=> $b } @ta));


package TA;

sub STORE {
    my ($self, $index, $value) = @_;
    # warn "store $index $value\n";
    return $self->{data}[$index] = $value;
}

sub PUSH {
    my ($self, @values) = @_;
    push(@{$self->{data}}, @values);
    $self->STORESIZE(scalar(@{$self->{data} // []}));
}

sub TIEARRAY {
    my ($class, @list) = @_;
    my $self = bless({data => []}, $class);
    return $self;
}

sub FETCHSIZE {
    my ($self) = @_;
    return $self->{count} // 0;
}

sub STORESIZE {
    my ($self, $count) = @_;
    return ($self->{count} = $count);
}

sub FETCH {
    my ($self, $index) = @_;
    # warn "fetch $index\n";
    return($self->{data}->[$index]);
}

sub DELETE {
    my ($self, $key) = @_;
    return splice(@{$self->{data}}, $key, 1);
}

sub CLEAR {
    my ($self) = @_;
    return($self->{data} = []);
}

1;
