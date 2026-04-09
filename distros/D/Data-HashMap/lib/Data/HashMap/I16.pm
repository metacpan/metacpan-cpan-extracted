package Data::HashMap::I16;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.07';

sub import {
    $^H{"Data::HashMap::I16/hm_i16_put"}     = 1;
    $^H{"Data::HashMap::I16/hm_i16_get"}     = 1;
    $^H{"Data::HashMap::I16/hm_i16_remove"}  = 1;
    $^H{"Data::HashMap::I16/hm_i16_take"}   = 1;
    $^H{"Data::HashMap::I16/hm_i16_drain"} = 1;
    $^H{"Data::HashMap::I16/hm_i16_pop"}   = 1;
    $^H{"Data::HashMap::I16/hm_i16_shift"} = 1;
    $^H{"Data::HashMap::I16/hm_i16_reserve"} = 1;
    $^H{"Data::HashMap::I16/hm_i16_purge"}   = 1;
    $^H{"Data::HashMap::I16/hm_i16_capacity"} = 1;
    $^H{"Data::HashMap::I16/hm_i16_persist"}  = 1;
    $^H{"Data::HashMap::I16/hm_i16_swap"}    = 1;
    $^H{"Data::HashMap::I16/hm_i16_cas"}     = 1;
    $^H{"Data::HashMap::I16/hm_i16_exists"}  = 1;
    $^H{"Data::HashMap::I16/hm_i16_incr"}    = 1;
    $^H{"Data::HashMap::I16/hm_i16_decr"}    = 1;
    $^H{"Data::HashMap::I16/hm_i16_incr_by"} = 1;
    $^H{"Data::HashMap::I16/hm_i16_size"}    = 1;
    $^H{"Data::HashMap::I16/hm_i16_keys"}    = 1;
    $^H{"Data::HashMap::I16/hm_i16_values"}  = 1;
    $^H{"Data::HashMap::I16/hm_i16_items"}    = 1;
    $^H{"Data::HashMap::I16/hm_i16_max_size"} = 1;
    $^H{"Data::HashMap::I16/hm_i16_ttl"}      = 1;
    $^H{"Data::HashMap::I16/hm_i16_lru_skip"} = 1;
    $^H{"Data::HashMap::I16/hm_i16_each"}       = 1;
    $^H{"Data::HashMap::I16/hm_i16_iter_reset"} = 1;
    $^H{"Data::HashMap::I16/hm_i16_clear"}      = 1;
    $^H{"Data::HashMap::I16/hm_i16_to_hash"}    = 1;
    $^H{"Data::HashMap::I16/hm_i16_put_ttl"}    = 1;
    $^H{"Data::HashMap::I16/hm_i16_get_or_set"} = 1;
}

1;
