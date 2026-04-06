package Data::Buffer::Shared::F32;
use strict;
use warnings;
use Data::Buffer::Shared;
our $VERSION = '0.01';

sub import {
    $^H{"Data::Buffer::Shared::F32/buf_f32_get"} = 1;
    $^H{"Data::Buffer::Shared::F32/buf_f32_set"} = 1;
    $^H{"Data::Buffer::Shared::F32/buf_f32_slice"} = 1;
    $^H{"Data::Buffer::Shared::F32/buf_f32_fill"} = 1;
    $^H{"Data::Buffer::Shared::F32/buf_f32_capacity"} = 1;
    $^H{"Data::Buffer::Shared::F32/buf_f32_mmap_size"} = 1;
    $^H{"Data::Buffer::Shared::F32/buf_f32_elem_size"} = 1;
    $^H{"Data::Buffer::Shared::F32/buf_f32_lock_wr"} = 1;
    $^H{"Data::Buffer::Shared::F32/buf_f32_unlock_wr"} = 1;
    $^H{"Data::Buffer::Shared::F32/buf_f32_lock_rd"} = 1;
    $^H{"Data::Buffer::Shared::F32/buf_f32_unlock_rd"} = 1;
    $^H{"Data::Buffer::Shared::F32/buf_f32_ptr"} = 1;
    $^H{"Data::Buffer::Shared::F32/buf_f32_ptr_at"} = 1;
    $^H{"Data::Buffer::Shared::F32/buf_f32_clear"} = 1;
    $^H{"Data::Buffer::Shared::F32/buf_f32_get_raw"} = 1;
    $^H{"Data::Buffer::Shared::F32/buf_f32_set_raw"} = 1;
}

1;
