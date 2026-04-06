use strict;
use warnings;
use Test::More;
use Data::Queue::Shared;

plan skip_all => "built without XS::Parse::Keyword"
    unless $Data::Queue::Shared::HAVE_KEYWORDS;

# ---- Int keywords ----
use Data::Queue::Shared::Int;

subtest 'q_int keywords' => sub {
    my $q = Data::Queue::Shared::Int->new(undef, 16);
    q_int_push $q, 42;
    q_int_push $q, 99;
    is q_int_peek $q, 42, 'peek';
    is q_int_size $q, 2, 'size';
    is q_int_pop $q, 42, 'pop 1';
    is q_int_pop $q, 99, 'pop 2';
    is q_int_size $q, 0, 'empty';
};

# ---- Int32 keywords ----
use Data::Queue::Shared::Int32;

subtest 'q_int32 keywords' => sub {
    my $q = Data::Queue::Shared::Int32->new(undef, 16);
    q_int32_push $q, 2000000;
    is q_int32_pop $q, 2000000, 'push/pop';
    q_int32_push $q, -100;
    is q_int32_peek $q, -100, 'peek negative';
    is q_int32_size $q, 1, 'size';
    q_int32_pop $q;
};

# ---- Int16 keywords ----
use Data::Queue::Shared::Int16;

subtest 'q_int16 keywords' => sub {
    my $q = Data::Queue::Shared::Int16->new(undef, 16);
    q_int16_push $q, 32767;
    is q_int16_pop $q, 32767, 'max int16';
    q_int16_push $q, -32768;
    is q_int16_pop $q, -32768, 'min int16';
};

# ---- Str keywords ----
use Data::Queue::Shared::Str;

subtest 'q_str keywords' => sub {
    my $q = Data::Queue::Shared::Str->new(undef, 16);
    q_str_push $q, "hello";
    q_str_push $q, "world";
    is q_str_peek $q, "hello", 'peek';
    is q_str_size $q, 2, 'size';
    is q_str_pop $q, "hello", 'pop 1';
    is q_str_pop $q, "world", 'pop 2';
};

# ---- import/unimport mechanism ----
subtest 'import mechanism' => sub {
    my $can_import = Data::Queue::Shared::Int->can('import');
    ok($can_import, 'import method exists');
    my $can_unimport = Data::Queue::Shared::Int->can('unimport');
    ok($can_unimport, 'unimport method exists');
};

done_testing;
