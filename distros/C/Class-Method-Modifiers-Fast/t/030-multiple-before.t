#!perl -T
use strict;
use warnings;
use Test::More tests => 1;

my @seen;
my @expected = ("before 2", "before 1", "orig");

my $child = Child->new; $child->orig;

is_deeply(\@seen, \@expected, "multiple befores called in the right order");

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

    before orig => sub
    {
        push @seen, "before 1";
    };

    before orig => sub
    {
        push @seen, "before 2";
    };
}

