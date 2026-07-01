use strict;
use warnings;
use Test::More;
use Data::Intern::Shared;

my $in = Data::Intern::Shared->new(undef, 100);

ok !eval { Data::Intern::Shared->new(undef, 0); 1 },        'max_strings 0 croaks';
eval { Data::Intern::Shared->new_from_fd(-1) };             ok $@, 'new_from_fd of an invalid fd croaks';
eval { $in->intern("\x{100}") };                            ok $@, 'interning a wide-character string croaks (encode bytes first)';
ok !defined($in->string(2**31)),                            'string of a huge out-of-range id is undef';
ok !defined($in->id_of("never interned")),                 'id_of of an absent string is undef';

done_testing;
