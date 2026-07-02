use strict;
use warnings;
use Test::More;
use Data::SortedSet::Shared;

my $z = Data::SortedSet::Shared->new(undef, 100);

eval { Data::SortedSet::Shared->new(undef, 0) };     ok $@, 'max_entries 0 rejected';
eval { $z->add(1, ("NaN" + 0)) };                    like $@, qr/NaN/, 'NaN score croaks';
eval { $z->incr(1, ("NaN" + 0)) };                   like $@, qr/NaN/, 'NaN incr delta croaks';
eval { $z->add_many("nope") };                       like $@, qr/arrayref/, 'add_many non-arrayref croaks';
eval { $z->each("notcode") };                        ok $@, 'each non-coderef croaks';
eval { $z->range_by_score(1, 2, bogus => 1) };       like $@, qr/unknown option/, 'unknown range option croaks';
eval { $z->range_by_score(1, 2, "withscores") };     like $@, qr/key => value/, 'odd range-option count croaks';

my $full = Data::SortedSet::Shared->new(undef, 2);
$full->add(1, 1); $full->add(2, 2);
eval { $full->incr(3, 5) };                          like $@, qr/exhausted|max_entries/, 'incr on a full pool croaks';
eval { Data::SortedSet::Shared->new_from_fd(-1) };   ok $@, 'new_from_fd of an invalid fd croaks';

done_testing;
