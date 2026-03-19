package Data::HashMap::Shared::I32S;
use strict;
use warnings;
use Data::HashMap::Shared;
our $VERSION = '0.01';

sub import {
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_put"}        = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_get"}        = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_remove"}     = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_exists"}     = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_size"}       = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_keys"}       = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_values"}     = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_items"}      = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_each"}       = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_iter_reset"} = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_clear"}      = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_to_hash"}    = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_max_entries"} = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_get_or_set"} = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_put_ttl"} = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_max_size"} = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_ttl"} = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_cursor"}       = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_cursor_next"}  = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_cursor_seek"}  = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_ttl_remaining"} = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_capacity"}     = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_tombstones"}   = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_cursor_reset"} = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_take"}           = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_flush_expired"}  = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_flush_expired_partial"} = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_mmap_size"}      = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_touch"}           = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_reserve"}         = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_stat_evictions"}  = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_stat_expired"}    = 1;
    $^H{"Data::HashMap::Shared::I32S/shm_i32s_stat_recoveries"}    = 1;
}

1;
