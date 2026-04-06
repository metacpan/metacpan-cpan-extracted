package Data::Buffer::Shared::F64;
use strict;
use warnings;
use Data::Buffer::Shared;
our $VERSION = '0.01';

sub import {
    $^H{"Data::Buffer::Shared::F64/buf_f64_get"} = 1;
    $^H{"Data::Buffer::Shared::F64/buf_f64_set"} = 1;
    $^H{"Data::Buffer::Shared::F64/buf_f64_slice"} = 1;
    $^H{"Data::Buffer::Shared::F64/buf_f64_fill"} = 1;
    $^H{"Data::Buffer::Shared::F64/buf_f64_capacity"} = 1;
    $^H{"Data::Buffer::Shared::F64/buf_f64_mmap_size"} = 1;
    $^H{"Data::Buffer::Shared::F64/buf_f64_elem_size"} = 1;
    $^H{"Data::Buffer::Shared::F64/buf_f64_lock_wr"} = 1;
    $^H{"Data::Buffer::Shared::F64/buf_f64_unlock_wr"} = 1;
    $^H{"Data::Buffer::Shared::F64/buf_f64_lock_rd"} = 1;
    $^H{"Data::Buffer::Shared::F64/buf_f64_unlock_rd"} = 1;
    $^H{"Data::Buffer::Shared::F64/buf_f64_ptr"} = 1;
    $^H{"Data::Buffer::Shared::F64/buf_f64_ptr_at"} = 1;
    $^H{"Data::Buffer::Shared::F64/buf_f64_clear"} = 1;
    $^H{"Data::Buffer::Shared::F64/buf_f64_get_raw"} = 1;
    $^H{"Data::Buffer::Shared::F64/buf_f64_set_raw"} = 1;
}

1;
