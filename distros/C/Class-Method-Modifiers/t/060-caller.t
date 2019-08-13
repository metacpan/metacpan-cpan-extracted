use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

my ($parent_caller, $before_caller, $around_caller, $after_caller);

my $parent = MyParent->new();
$parent->orig();

is($parent_caller, 'main', "parent with no modifiers sees 'main' as caller");

my $child = Child->new();
$child->orig();

TODO:
{
    local $TODO = "caller magic not implemented yet";

    is($parent_caller, 'main', "parent with modifiers sees 'main' as caller");
    is($before_caller, 'main', "before modifiers sees 'main' as caller");
    is($around_caller, 'main', "around modifiers sees 'main' as caller");
    is($after_caller,  'main', "after modifiers sees 'main' as caller");
}

BEGIN
{
    package MyParent;
    sub new { bless {}, shift }
    sub orig
    {
        $parent_caller = caller;
    }
}

BEGIN
{
    package Child;
    our @ISA = 'MyParent';
    use Class::Method::Modifiers;

    before 'orig' => sub
    {
        $before_caller = caller;
    };

    after 'orig' => sub
    {
        $after_caller = caller;
    };

    around 'orig' => sub
    {
        my $orig = shift;
        $around_caller = caller;
        $orig->();
    };
}

done_testing;
