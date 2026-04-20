package Data::HashMap::II;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.08';

sub import {
    $^H{"Data::HashMap::II/hm_ii_put"}     = 1;
    $^H{"Data::HashMap::II/hm_ii_get"}     = 1;
    $^H{"Data::HashMap::II/hm_ii_remove"}  = 1;
    $^H{"Data::HashMap::II/hm_ii_take"}   = 1;
    $^H{"Data::HashMap::II/hm_ii_drain"} = 1;
    $^H{"Data::HashMap::II/hm_ii_pop"}   = 1;
    $^H{"Data::HashMap::II/hm_ii_shift"} = 1;
    $^H{"Data::HashMap::II/hm_ii_reserve"} = 1;
    $^H{"Data::HashMap::II/hm_ii_purge"}   = 1;
    $^H{"Data::HashMap::II/hm_ii_capacity"} = 1;
    $^H{"Data::HashMap::II/hm_ii_persist"}  = 1;
    $^H{"Data::HashMap::II/hm_ii_swap"}    = 1;
    $^H{"Data::HashMap::II/hm_ii_cas"}     = 1;
    $^H{"Data::HashMap::II/hm_ii_exists"}  = 1;
    $^H{"Data::HashMap::II/hm_ii_incr"}    = 1;
    $^H{"Data::HashMap::II/hm_ii_decr"}    = 1;
    $^H{"Data::HashMap::II/hm_ii_incr_by"} = 1;
    $^H{"Data::HashMap::II/hm_ii_size"}    = 1;
    $^H{"Data::HashMap::II/hm_ii_keys"}    = 1;
    $^H{"Data::HashMap::II/hm_ii_values"}  = 1;
    $^H{"Data::HashMap::II/hm_ii_items"}    = 1;
    $^H{"Data::HashMap::II/hm_ii_max_size"} = 1;
    $^H{"Data::HashMap::II/hm_ii_ttl"}      = 1;
    $^H{"Data::HashMap::II/hm_ii_lru_skip"} = 1;
    $^H{"Data::HashMap::II/hm_ii_each"}       = 1;
    $^H{"Data::HashMap::II/hm_ii_iter_reset"} = 1;
    $^H{"Data::HashMap::II/hm_ii_clear"}      = 1;
    $^H{"Data::HashMap::II/hm_ii_to_hash"}    = 1;
    $^H{"Data::HashMap::II/hm_ii_put_ttl"}    = 1;
    $^H{"Data::HashMap::II/hm_ii_get_or_set"} = 1;
}

1;
