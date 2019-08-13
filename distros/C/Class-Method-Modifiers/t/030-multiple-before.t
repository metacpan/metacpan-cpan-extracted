use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

my @seen;
my @expected = ("before 2", "before 1", "orig");

my $child = Child->new; $child->orig;

is_deeply(\@seen, \@expected, "multiple befores called in the right order");

BEGIN {
    package MyParent;
    sub new { bless {}, shift }
    sub orig
    {
        push @seen, "orig";
    }
}

BEGIN {
    package Child;
    our @ISA = 'MyParent';
    use Class::Method::Modifiers;

    before orig => sub
    {
        push @seen, "before 1";
    };

    before orig => sub
    {
        push @seen, "before 2";
    };
}

done_testing;
