#!perl -T
use strict;
use warnings;
use Test::More tests => 1;

my @seen;
my @expected = ("orig", "after 1", "after 2");

my $child = Child->new; $child->orig;

is_deeply(\@seen, \@expected, "multiple afters called in the right order");

BEGIN {
    package Parent;
    sub new { bless {}, shift }
    sub orig
    {
        push @seen, "orig";
    }
}

BEGIN {
    package Child;
    our @ISA = 'Parent';
    use Class::Method::Modifiers::Fast;

    after orig => sub
    {
        push @seen, "after 1";
    };

    after orig => sub
    {
        push @seen, "after 2";
    };
}

