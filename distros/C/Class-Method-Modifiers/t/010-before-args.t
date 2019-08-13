use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

my $storage = "Foo";

my $child = Child->new();
is($child->orig($storage), "before foo", "before affected orig's args a little");

BEGIN
{
    package MyParent;
    sub new { bless {}, shift }
    sub orig
    {
        my $self = shift;
        return lc shift;
    }
}

BEGIN
{
    package Child;
    our @ISA = 'MyParent';
    use Class::Method::Modifiers;

    before 'orig' => sub
    {
        my $self = shift;
        $_[0] = 'Before ' . $_[0];

        my $discard = shift;
        $discard = "will never be seen";
        return ["lc on an arrayref? ha ha ha"];
    };
}

done_testing;
