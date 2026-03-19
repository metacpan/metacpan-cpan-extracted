package Data::HashMap::Shared::SS;
use strict;
use warnings;
use Data::HashMap::Shared;
our $VERSION = '0.01';

sub import {
    $^H{"Data::HashMap::Shared::SS/shm_ss_put"}        = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_get"}        = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_remove"}     = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_exists"}     = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_size"}       = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_keys"}       = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_values"}     = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_items"}      = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_each"}       = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_iter_reset"} = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_clear"}      = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_to_hash"}    = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_max_entries"} = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_get_or_set"} = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_put_ttl"} = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_max_size"} = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_ttl"} = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_cursor"}       = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_cursor_next"}  = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_cursor_seek"}  = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_ttl_remaining"} = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_capacity"}     = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_tombstones"}   = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_cursor_reset"} = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_take"}           = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_flush_expired"}  = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_flush_expired_partial"} = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_mmap_size"}      = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_touch"}           = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_reserve"}         = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_stat_evictions"}  = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_stat_expired"}    = 1;
    $^H{"Data::HashMap::Shared::SS/shm_ss_stat_recoveries"}    = 1;
}

1;
