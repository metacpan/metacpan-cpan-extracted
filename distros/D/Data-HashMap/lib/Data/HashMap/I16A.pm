package Data::HashMap::I16A;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.08';

sub import {
    $^H{"Data::HashMap::I16A/hm_i16a_put"}        = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_get"}        = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_remove"}     = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_take"}   = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_drain"} = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_pop"}   = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_shift"} = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_reserve"} = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_purge"}   = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_capacity"} = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_persist"}  = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_swap"}    = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_exists"}     = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_size"}       = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_keys"}       = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_values"}     = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_items"}      = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_max_size"}   = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_ttl"}        = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_lru_skip"} = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_each"}       = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_iter_reset"} = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_clear"}      = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_to_hash"}    = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_put_ttl"}    = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_get_or_set"} = 1;
}

1;
