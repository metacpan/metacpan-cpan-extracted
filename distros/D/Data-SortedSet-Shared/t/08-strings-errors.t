use strict;
use warnings;
use Test::More;
BEGIN {
    eval { require Data::Intern::Shared; 1 }
        or plan skip_all => 'Data::Intern::Shared is required for string-keyed sets';
}
use Data::SortedSet::Shared::Strings;
use Data::SortedSet::Shared ();
use Data::Intern::Shared ();

# constructor guards
eval { Data::SortedSet::Shared::Strings->new() };
like $@, qr/max/, 'new without max croaks';

eval { Data::SortedSet::Shared::Strings->wrap("not an object", "x") };
like $@, qr/Data::SortedSet::Shared/, 'wrap with a non-SortedSet first arg croaks';

eval { Data::SortedSet::Shared::Strings->wrap(Data::SortedSet::Shared->new(undef, 2), "x") };
like $@, qr/Data::Intern::Shared/, 'wrap with a non-Intern second arg croaks';

# add returns undef when the MEMBER pool is full (key table has room)
{
    my $f = Data::SortedSet::Shared::Strings->new(max => 2, max_keys => 100);
    is $f->add("a", 1), 1, 'add a (1/2)';
    is $f->add("b", 2), 1, 'add b (2/2)';
    ok !defined($f->add("c", 3)), 'add of a new member returns undef when the member pool is full';
    is $f->count, 2, 'count unchanged after a full-pool add';
}

# incr croaks when the KEY table is full and the key is new
{
    my $g = Data::SortedSet::Shared::Strings->new(max => 100, max_keys => 2);
    $g->add("x", 1);
    $g->add("y", 2);                       # key table now full (2/2)
    eval { $g->incr("z", 1) };
    like $@, qr/full/, 'incr croaks when the key table is full and the key is new';
    is $g->incr("x", 5), 6, 'incr of an existing key still works when the key table is full';
}

done_testing;
