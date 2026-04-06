package Data::Buffer::Shared::U64;
use strict;
use warnings;
use Data::Buffer::Shared;
our $VERSION = '0.01';

sub import {
    $^H{"Data::Buffer::Shared::U64/buf_u64_get"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_set"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_slice"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_fill"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_capacity"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_mmap_size"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_elem_size"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_lock_wr"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_unlock_wr"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_lock_rd"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_unlock_rd"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_ptr"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_ptr_at"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_clear"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_get_raw"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_set_raw"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_incr"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_decr"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_add"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_cas"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_cmpxchg"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_atomic_and"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_atomic_or"} = 1;
    $^H{"Data::Buffer::Shared::U64/buf_u64_atomic_xor"} = 1;
}

1;
