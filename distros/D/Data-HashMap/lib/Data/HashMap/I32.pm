package Data::HashMap::I32;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.01';

sub import {
    $^H{"Data::HashMap::I32/hm_i32_put"}     = 1;
    $^H{"Data::HashMap::I32/hm_i32_get"}     = 1;
    $^H{"Data::HashMap::I32/hm_i32_remove"}  = 1;
    $^H{"Data::HashMap::I32/hm_i32_exists"}  = 1;
    $^H{"Data::HashMap::I32/hm_i32_incr"}    = 1;
    $^H{"Data::HashMap::I32/hm_i32_decr"}    = 1;
    $^H{"Data::HashMap::I32/hm_i32_incr_by"} = 1;
    $^H{"Data::HashMap::I32/hm_i32_size"}    = 1;
    $^H{"Data::HashMap::I32/hm_i32_keys"}    = 1;
    $^H{"Data::HashMap::I32/hm_i32_values"}  = 1;
    $^H{"Data::HashMap::I32/hm_i32_items"}    = 1;
    $^H{"Data::HashMap::I32/hm_i32_max_size"} = 1;
    $^H{"Data::HashMap::I32/hm_i32_ttl"}      = 1;
    $^H{"Data::HashMap::I32/hm_i32_each"}       = 1;
    $^H{"Data::HashMap::I32/hm_i32_iter_reset"} = 1;
    $^H{"Data::HashMap::I32/hm_i32_clear"}      = 1;
    $^H{"Data::HashMap::I32/hm_i32_to_hash"}    = 1;
    $^H{"Data::HashMap::I32/hm_i32_put_ttl"}    = 1;
    $^H{"Data::HashMap::I32/hm_i32_get_or_set"} = 1;
}

1;
