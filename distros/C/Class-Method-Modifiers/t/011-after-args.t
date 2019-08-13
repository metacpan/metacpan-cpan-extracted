use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

my $after_saw_orig_args = 0;

my $storage = "Foo";
my $child = Child->new();
is($child->orig($storage), "orig", "after didn't affect orig's return");
ok($after_saw_orig_args, "after saw original arguments");

BEGIN
{
    package MyParent;
    sub new { bless {}, shift }
    sub orig
    {
        my $self = shift;
        $_[0] =~ s/Foo/bAR/;
        return "orig";
    }
}

BEGIN
{
    package Child;
    our @ISA = 'MyParent';
    use Class::Method::Modifiers;

    after 'orig' => sub
    {
        my $self = shift;
        my $arg = shift;
        $after_saw_orig_args = $arg eq "bAR";
        return sub { die "somehow a closure was executed" };
    };
}

done_testing;
