#!/usr/bin/env perl

# A "is_na" function is used in Data::Frame::Util's
#  guess_and_convert_to_pdl() function.
# 
# The result indicates that for a small length of @na, grep could be the
#  most practical way for performance. It looks like that the overhead from
#  closure and Perl operators is obvious in this case.

use 5.016;
use warnings;

use List::Util qw(any);
use Benchmark qw(:all);

my @na = ( qw(NA BAD), '' );

# array of string with 100k data
my @s = (qw(foo bar baz quux)) x 25000;

sub is_na_any {
    any { $_[0] eq $_ } @na;
}

sub is_na_grep {
    scalar(grep { $_[0] eq $_ } @na);
}

my $re = qr/^(?:NA|BAD|)$/;

sub is_na_regex {
    $_[0] =~ $re;
}

sub is_na_regex2 {
    # this is for comparison with above is_na_regex()
    $_[0] =~ /^(?:NA|BAD|)$/;
}

cmpthese(
    100,
    {
        'is_na_any' => sub {
            my @x = map { is_na_any($_) } @s;
        },
        'is_na_grep' => sub {
            my @x = map { is_na_grep($_) } @s;
        },
        'is_na_regex' => sub {
            my @x = map { is_na_regex($_) } @s;
        },
        'is_na_regex2' => sub {
            my @x = map { is_na_regex2($_) } @s;
        },
    },
);

