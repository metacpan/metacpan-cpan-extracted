package Data::Buffer::Shared::I32;
use strict;
use warnings;
use Data::Buffer::Shared;
our $VERSION = '0.03';

sub import {
    $^H{"Data::Buffer::Shared::I32/buf_i32_get"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_set"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_slice"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_fill"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_capacity"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_mmap_size"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_elem_size"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_lock_wr"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_unlock_wr"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_lock_rd"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_unlock_rd"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_ptr"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_ptr_at"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_clear"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_get_raw"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_set_raw"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_incr"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_decr"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_add"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_cas"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_cmpxchg"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_atomic_and"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_atomic_or"} = 1;
    $^H{"Data::Buffer::Shared::I32/buf_i32_atomic_xor"} = 1;
}

*memfd = \&fd;
1;
