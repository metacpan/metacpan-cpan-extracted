package Data::Buffer::Shared::U16;
use strict;
use warnings;
use Data::Buffer::Shared;
our $VERSION = '0.03';

sub import {
    $^H{"Data::Buffer::Shared::U16/buf_u16_get"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_set"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_slice"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_fill"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_capacity"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_mmap_size"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_elem_size"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_lock_wr"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_unlock_wr"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_lock_rd"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_unlock_rd"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_ptr"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_ptr_at"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_clear"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_get_raw"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_set_raw"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_incr"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_decr"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_add"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_cas"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_cmpxchg"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_atomic_and"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_atomic_or"} = 1;
    $^H{"Data::Buffer::Shared::U16/buf_u16_atomic_xor"} = 1;
}

*memfd = \&fd;
1;
