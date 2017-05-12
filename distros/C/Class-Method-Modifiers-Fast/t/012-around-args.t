#!perl -T
use strict;
use warnings;
use Test::More tests => 3;

my $child = Child->new();
my @words = split ' ', $child->orig("param");
is($words[0], "before");
is($words[1], "PARAM-orig");
is($words[2], "after");

BEGIN
{
    package Parent;
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
    our @ISA = 'Parent';
    use Class::Method::Modifiers::Fast;

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
