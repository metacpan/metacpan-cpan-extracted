package Data::HashMap::I32A;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.01';

sub import {
    $^H{"Data::HashMap::I32A/hm_i32a_put"}        = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_get"}        = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_remove"}     = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_exists"}     = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_size"}       = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_keys"}       = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_values"}     = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_items"}      = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_max_size"}   = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_ttl"}        = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_each"}       = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_iter_reset"} = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_clear"}      = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_to_hash"}    = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_put_ttl"}    = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_get_or_set"} = 1;
}

1;
