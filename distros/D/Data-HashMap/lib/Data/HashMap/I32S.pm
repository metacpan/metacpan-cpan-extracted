package Data::HashMap::I32S;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.01';

sub import {
    $^H{"Data::HashMap::I32S/hm_i32s_put"}    = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_get"}    = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_remove"} = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_exists"} = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_size"}   = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_keys"}   = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_values"} = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_items"}    = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_max_size"} = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_ttl"}      = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_each"}       = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_iter_reset"} = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_clear"}      = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_to_hash"}    = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_put_ttl"}    = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_get_or_set"} = 1;
}

1;
