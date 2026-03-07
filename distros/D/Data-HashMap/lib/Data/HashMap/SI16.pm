package Data::HashMap::SI16;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.01';

sub import {
    $^H{"Data::HashMap::SI16/hm_si16_put"}     = 1;
    $^H{"Data::HashMap::SI16/hm_si16_get"}     = 1;
    $^H{"Data::HashMap::SI16/hm_si16_remove"}  = 1;
    $^H{"Data::HashMap::SI16/hm_si16_exists"}  = 1;
    $^H{"Data::HashMap::SI16/hm_si16_incr"}    = 1;
    $^H{"Data::HashMap::SI16/hm_si16_decr"}    = 1;
    $^H{"Data::HashMap::SI16/hm_si16_incr_by"} = 1;
    $^H{"Data::HashMap::SI16/hm_si16_size"}    = 1;
    $^H{"Data::HashMap::SI16/hm_si16_keys"}    = 1;
    $^H{"Data::HashMap::SI16/hm_si16_values"}  = 1;
    $^H{"Data::HashMap::SI16/hm_si16_items"}    = 1;
    $^H{"Data::HashMap::SI16/hm_si16_max_size"} = 1;
    $^H{"Data::HashMap::SI16/hm_si16_ttl"}      = 1;
    $^H{"Data::HashMap::SI16/hm_si16_each"}       = 1;
    $^H{"Data::HashMap::SI16/hm_si16_iter_reset"} = 1;
    $^H{"Data::HashMap::SI16/hm_si16_clear"}      = 1;
    $^H{"Data::HashMap::SI16/hm_si16_to_hash"}    = 1;
    $^H{"Data::HashMap::SI16/hm_si16_put_ttl"}    = 1;
    $^H{"Data::HashMap::SI16/hm_si16_get_or_set"} = 1;
}

1;
