package Data::HashMap::SI;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.01';

sub import {
    $^H{"Data::HashMap::SI/hm_si_put"}     = 1;
    $^H{"Data::HashMap::SI/hm_si_get"}     = 1;
    $^H{"Data::HashMap::SI/hm_si_remove"}  = 1;
    $^H{"Data::HashMap::SI/hm_si_exists"}  = 1;
    $^H{"Data::HashMap::SI/hm_si_incr"}    = 1;
    $^H{"Data::HashMap::SI/hm_si_decr"}    = 1;
    $^H{"Data::HashMap::SI/hm_si_incr_by"} = 1;
    $^H{"Data::HashMap::SI/hm_si_size"}    = 1;
    $^H{"Data::HashMap::SI/hm_si_keys"}    = 1;
    $^H{"Data::HashMap::SI/hm_si_values"}  = 1;
    $^H{"Data::HashMap::SI/hm_si_items"}    = 1;
    $^H{"Data::HashMap::SI/hm_si_max_size"} = 1;
    $^H{"Data::HashMap::SI/hm_si_ttl"}      = 1;
    $^H{"Data::HashMap::SI/hm_si_each"}       = 1;
    $^H{"Data::HashMap::SI/hm_si_iter_reset"} = 1;
    $^H{"Data::HashMap::SI/hm_si_clear"}      = 1;
    $^H{"Data::HashMap::SI/hm_si_to_hash"}    = 1;
    $^H{"Data::HashMap::SI/hm_si_put_ttl"}    = 1;
    $^H{"Data::HashMap::SI/hm_si_get_or_set"} = 1;
}

1;
