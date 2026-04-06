package Data::Buffer::Shared::I16;
use strict;
use warnings;
use Data::Buffer::Shared;
our $VERSION = '0.01';

sub import {
    $^H{"Data::Buffer::Shared::I16/buf_i16_get"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_set"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_slice"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_fill"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_capacity"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_mmap_size"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_elem_size"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_lock_wr"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_unlock_wr"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_lock_rd"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_unlock_rd"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_ptr"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_ptr_at"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_clear"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_get_raw"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_set_raw"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_incr"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_decr"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_add"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_cas"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_cmpxchg"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_atomic_and"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_atomic_or"} = 1;
    $^H{"Data::Buffer::Shared::I16/buf_i16_atomic_xor"} = 1;
}

1;
