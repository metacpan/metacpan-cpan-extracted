package Data::Buffer::Shared::Str;
use strict;
use warnings;
use Data::Buffer::Shared;
our $VERSION = '0.01';

sub import {
    $^H{"Data::Buffer::Shared::Str/buf_str_get"} = 1;
    $^H{"Data::Buffer::Shared::Str/buf_str_set"} = 1;
    $^H{"Data::Buffer::Shared::Str/buf_str_slice"} = 1;
    $^H{"Data::Buffer::Shared::Str/buf_str_fill"} = 1;
    $^H{"Data::Buffer::Shared::Str/buf_str_capacity"} = 1;
    $^H{"Data::Buffer::Shared::Str/buf_str_mmap_size"} = 1;
    $^H{"Data::Buffer::Shared::Str/buf_str_elem_size"} = 1;
    $^H{"Data::Buffer::Shared::Str/buf_str_lock_wr"} = 1;
    $^H{"Data::Buffer::Shared::Str/buf_str_unlock_wr"} = 1;
    $^H{"Data::Buffer::Shared::Str/buf_str_lock_rd"} = 1;
    $^H{"Data::Buffer::Shared::Str/buf_str_unlock_rd"} = 1;
    $^H{"Data::Buffer::Shared::Str/buf_str_ptr"} = 1;
    $^H{"Data::Buffer::Shared::Str/buf_str_ptr_at"} = 1;
    $^H{"Data::Buffer::Shared::Str/buf_str_clear"} = 1;
    $^H{"Data::Buffer::Shared::Str/buf_str_get_raw"} = 1;
    $^H{"Data::Buffer::Shared::Str/buf_str_set_raw"} = 1;
}

1;
