#!perl -T
use strict;
use warnings;
use Test::More tests => 2;

my $after_saw_orig_args = 0;

my $storage = "Foo";
my $child = Child->new();
is($child->orig($storage), "orig", "after didn't affect orig's return");
ok($after_saw_orig_args, "after saw original arguments");

BEGIN
{
    package Parent;
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
    our @ISA = 'Parent';
    use Class::Method::Modifiers::Fast;

    after 'orig' => sub
    {
        my $self = shift;
        my $arg = shift;
        $after_saw_orig_args = $arg eq "bAR";
        return sub { die "somehow a closure was executed" };
    };
}
