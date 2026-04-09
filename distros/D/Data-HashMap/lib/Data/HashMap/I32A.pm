package Data::HashMap::I32A;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.07';

sub import {
    $^H{"Data::HashMap::I32A/hm_i32a_put"}        = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_get"}        = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_remove"}     = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_take"}   = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_drain"} = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_pop"}   = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_shift"} = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_reserve"} = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_purge"}   = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_capacity"} = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_persist"}  = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_swap"}    = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_exists"}     = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_size"}       = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_keys"}       = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_values"}     = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_items"}      = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_max_size"}   = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_ttl"}        = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_lru_skip"} = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_each"}       = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_iter_reset"} = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_clear"}      = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_to_hash"}    = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_put_ttl"}    = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_get_or_set"} = 1;
}

1;
