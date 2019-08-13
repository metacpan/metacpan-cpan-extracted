use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

my ($after_called, $orig_called) = (0, 0);
my $child = Child->new();
my @results = $child->orig();

ok($orig_called, "original method called");
ok($after_called, "after-modifier called");
is(@results, 0, "list context with after doesn't screw up 'return'");

($after_called, $orig_called) = (0, 0);
my $result = $child->orig();

ok($orig_called, "original method called");
ok($after_called, "after-modifier called");
is($result, undef, "scalar context with after doesn't screw up 'return'");

BEGIN
{
    package MyParent;
    sub new { bless {}, shift }
    sub orig
    {
        my $self = shift;
        $orig_called = 1;
        return;
    }
}

BEGIN
{
    package Child;
    our @ISA = 'MyParent';
    use Class::Method::Modifiers;

    after 'orig' => sub
    {
        $after_called = 1;
    };
}

done_testing;
