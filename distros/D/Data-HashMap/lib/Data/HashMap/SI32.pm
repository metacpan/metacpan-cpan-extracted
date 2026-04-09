package Data::HashMap::SI32;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.07';

sub import {
    $^H{"Data::HashMap::SI32/hm_si32_put"}     = 1;
    $^H{"Data::HashMap::SI32/hm_si32_get"}     = 1;
    $^H{"Data::HashMap::SI32/hm_si32_remove"}  = 1;
    $^H{"Data::HashMap::SI32/hm_si32_take"}   = 1;
    $^H{"Data::HashMap::SI32/hm_si32_drain"} = 1;
    $^H{"Data::HashMap::SI32/hm_si32_pop"}   = 1;
    $^H{"Data::HashMap::SI32/hm_si32_shift"} = 1;
    $^H{"Data::HashMap::SI32/hm_si32_reserve"} = 1;
    $^H{"Data::HashMap::SI32/hm_si32_purge"}   = 1;
    $^H{"Data::HashMap::SI32/hm_si32_capacity"} = 1;
    $^H{"Data::HashMap::SI32/hm_si32_persist"}  = 1;
    $^H{"Data::HashMap::SI32/hm_si32_swap"}    = 1;
    $^H{"Data::HashMap::SI32/hm_si32_cas"}     = 1;
    $^H{"Data::HashMap::SI32/hm_si32_exists"}  = 1;
    $^H{"Data::HashMap::SI32/hm_si32_incr"}    = 1;
    $^H{"Data::HashMap::SI32/hm_si32_decr"}    = 1;
    $^H{"Data::HashMap::SI32/hm_si32_incr_by"} = 1;
    $^H{"Data::HashMap::SI32/hm_si32_size"}    = 1;
    $^H{"Data::HashMap::SI32/hm_si32_keys"}    = 1;
    $^H{"Data::HashMap::SI32/hm_si32_values"}  = 1;
    $^H{"Data::HashMap::SI32/hm_si32_items"}    = 1;
    $^H{"Data::HashMap::SI32/hm_si32_max_size"} = 1;
    $^H{"Data::HashMap::SI32/hm_si32_ttl"}      = 1;
    $^H{"Data::HashMap::SI32/hm_si32_lru_skip"} = 1;
    $^H{"Data::HashMap::SI32/hm_si32_each"}       = 1;
    $^H{"Data::HashMap::SI32/hm_si32_iter_reset"} = 1;
    $^H{"Data::HashMap::SI32/hm_si32_clear"}      = 1;
    $^H{"Data::HashMap::SI32/hm_si32_to_hash"}    = 1;
    $^H{"Data::HashMap::SI32/hm_si32_put_ttl"}    = 1;
    $^H{"Data::HashMap::SI32/hm_si32_get_or_set"} = 1;
}

1;
