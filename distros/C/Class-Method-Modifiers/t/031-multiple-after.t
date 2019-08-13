use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

my @seen;
my @expected = ("orig", "after 1", "after 2");

my $child = Child->new; $child->orig;

is_deeply(\@seen, \@expected, "multiple afters called in the right order");

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

    after orig => sub
    {
        push @seen, "after 1";
    };

    after orig => sub
    {
        push @seen, "after 2";
    };
}

done_testing;
