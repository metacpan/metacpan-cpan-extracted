package Data::HashMap::Shared::IS;
use strict;
use warnings;
use Data::HashMap::Shared;
our $VERSION = '0.01';

sub import {
    $^H{"Data::HashMap::Shared::IS/shm_is_put"}        = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_get"}        = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_remove"}     = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_exists"}     = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_size"}       = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_keys"}       = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_values"}     = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_items"}      = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_each"}       = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_iter_reset"} = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_clear"}      = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_to_hash"}    = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_max_entries"} = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_get_or_set"} = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_put_ttl"} = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_max_size"} = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_ttl"} = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_cursor"}       = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_cursor_next"}  = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_cursor_seek"}  = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_ttl_remaining"} = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_capacity"}     = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_tombstones"}   = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_cursor_reset"} = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_take"}           = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_flush_expired"}  = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_flush_expired_partial"} = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_mmap_size"}      = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_touch"}           = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_reserve"}         = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_stat_evictions"}  = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_stat_expired"}    = 1;
    $^H{"Data::HashMap::Shared::IS/shm_is_stat_recoveries"}    = 1;
}

1;
