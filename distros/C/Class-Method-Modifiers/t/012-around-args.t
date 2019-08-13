use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

my $child = Child->new();
my @words = split ' ', $child->orig("param");
is($words[0], "before");
is($words[1], "PARAM-orig");
is($words[2], "after");

BEGIN
{
    package MyParent;
    sub new { bless {}, shift }
    sub orig
    {
        my $self = shift;
        my $arg = shift;
        return "$arg-orig";
    }
}

BEGIN
{
    package Child;
    our @ISA = 'MyParent';
    use Class::Method::Modifiers;

    around 'orig' => sub
    {
        my $orig = shift;
        my $self = shift;
        my $arg = shift;

        join ' ',
            "before",
            $orig->($self, uc $arg),
            "after";
    };
}

done_testing;
