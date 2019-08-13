use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

my @seen;
my @expected = ("before 4",
                  "before 3",
                    "around 4 before",
                      "around 3 before",
                        "before 2",
                          "before 1",
                            "around 2 before",
                              "around 1 before",
                                "orig",
                              "around 1 after",
                            "around 2 after",
                          "after 1",
                        "after 2",
                      "around 3 after",
                    "around 4 after",
                  "after 3",
                "after 4",
               );

my $child = Grandchild->new; $child->orig;

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

    before orig => sub
    {
        push @seen, "before 1";
    };

    before orig => sub
    {
        push @seen, "before 2";
    };

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

    after orig => sub
    {
        push @seen, "after 1";
    };

    after orig => sub
    {
        push @seen, "after 2";
    };
}

BEGIN {
    package Grandchild;
    our @ISA = 'Child';
    use Class::Method::Modifiers;

    before orig => sub
    {
        push @seen, "before 3";
    };

    before orig => sub
    {
        push @seen, "before 4";
    };

    around orig => sub
    {
        my $orig = shift;
        push @seen, "around 3 before";
        $orig->();
        push @seen, "around 3 after";
    };

    around orig => sub
    {
        my $orig = shift;
        push @seen, "around 4 before";
        $orig->();
        push @seen, "around 4 after";
    };

    after orig => sub
    {
        push @seen, "after 3";
    };

    after orig => sub
    {
        push @seen, "after 4";
    };
}

done_testing;
