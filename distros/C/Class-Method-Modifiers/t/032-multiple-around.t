use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

my @seen;
my @expected = ("around 2 before", "around 1 before", "orig", "around 1 after", "around 2 after");

my $child = Child->new; $child->orig;

is_deeply(\@seen, \@expected, "multiple arounds called in the right order");

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

    around orig => sub
    {
        my $orig = shift;
        push @seen, "around 1 before";
        $orig->();
        push @seen, "around 1 after";
    };

    around orig => sub
    {
        my $orig = shift;
        push @seen, "around 2 before";
        $orig->();
        push @seen, "around 2 after";
    };
}

done_testing;
