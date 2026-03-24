package Data::HashMap::IS;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.06';

sub import {
    $^H{"Data::HashMap::IS/hm_is_put"}    = 1;
    $^H{"Data::HashMap::IS/hm_is_get"}    = 1;
    $^H{"Data::HashMap::IS/hm_is_remove"} = 1;
    $^H{"Data::HashMap::IS/hm_is_take"}   = 1;
    $^H{"Data::HashMap::IS/hm_is_drain"} = 1;
    $^H{"Data::HashMap::IS/hm_is_pop"}   = 1;
    $^H{"Data::HashMap::IS/hm_is_shift"} = 1;
    $^H{"Data::HashMap::IS/hm_is_reserve"} = 1;
    $^H{"Data::HashMap::IS/hm_is_purge"}   = 1;
    $^H{"Data::HashMap::IS/hm_is_capacity"} = 1;
    $^H{"Data::HashMap::IS/hm_is_persist"}  = 1;
    $^H{"Data::HashMap::IS/hm_is_swap"}    = 1;
    $^H{"Data::HashMap::IS/hm_is_exists"} = 1;
    $^H{"Data::HashMap::IS/hm_is_size"}   = 1;
    $^H{"Data::HashMap::IS/hm_is_keys"}   = 1;
    $^H{"Data::HashMap::IS/hm_is_values"} = 1;
    $^H{"Data::HashMap::IS/hm_is_items"}    = 1;
    $^H{"Data::HashMap::IS/hm_is_max_size"} = 1;
    $^H{"Data::HashMap::IS/hm_is_ttl"}      = 1;
    $^H{"Data::HashMap::IS/hm_is_lru_skip"} = 1;
    $^H{"Data::HashMap::IS/hm_is_each"}       = 1;
    $^H{"Data::HashMap::IS/hm_is_iter_reset"} = 1;
    $^H{"Data::HashMap::IS/hm_is_clear"}      = 1;
    $^H{"Data::HashMap::IS/hm_is_to_hash"}    = 1;
    $^H{"Data::HashMap::IS/hm_is_put_ttl"}    = 1;
    $^H{"Data::HashMap::IS/hm_is_get_or_set"} = 1;
    $^H{"Data::HashMap::IS/hm_is_get_direct"} = 1;
}

1;
