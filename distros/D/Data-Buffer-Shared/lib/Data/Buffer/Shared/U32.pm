package Data::Buffer::Shared::U32;
use strict;
use warnings;
use Data::Buffer::Shared;
our $VERSION = '0.01';

sub import {
    $^H{"Data::Buffer::Shared::U32/buf_u32_get"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_set"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_slice"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_fill"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_capacity"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_mmap_size"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_elem_size"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_lock_wr"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_unlock_wr"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_lock_rd"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_unlock_rd"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_ptr"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_ptr_at"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_clear"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_get_raw"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_set_raw"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_incr"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_decr"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_add"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_cas"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_cmpxchg"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_atomic_and"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_atomic_or"} = 1;
    $^H{"Data::Buffer::Shared::U32/buf_u32_atomic_xor"} = 1;
}

1;
