package Data::Buffer::Shared::I64;
use strict;
use warnings;
use Data::Buffer::Shared;
our $VERSION = '0.01';

sub import {
    $^H{"Data::Buffer::Shared::I64/buf_i64_get"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_set"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_slice"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_fill"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_capacity"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_mmap_size"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_elem_size"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_lock_wr"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_unlock_wr"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_lock_rd"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_unlock_rd"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_ptr"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_ptr_at"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_clear"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_get_raw"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_set_raw"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_incr"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_decr"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_add"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_cas"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_cmpxchg"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_atomic_and"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_atomic_or"} = 1;
    $^H{"Data::Buffer::Shared::I64/buf_i64_atomic_xor"} = 1;
}

1;
