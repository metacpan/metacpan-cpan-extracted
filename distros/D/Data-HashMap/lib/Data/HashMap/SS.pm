package Data::HashMap::SS;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.01';

sub import {
    $^H{"Data::HashMap::SS/hm_ss_put"}    = 1;
    $^H{"Data::HashMap::SS/hm_ss_get"}    = 1;
    $^H{"Data::HashMap::SS/hm_ss_remove"} = 1;
    $^H{"Data::HashMap::SS/hm_ss_exists"} = 1;
    $^H{"Data::HashMap::SS/hm_ss_size"}   = 1;
    $^H{"Data::HashMap::SS/hm_ss_keys"}   = 1;
    $^H{"Data::HashMap::SS/hm_ss_values"} = 1;
    $^H{"Data::HashMap::SS/hm_ss_items"}    = 1;
    $^H{"Data::HashMap::SS/hm_ss_max_size"} = 1;
    $^H{"Data::HashMap::SS/hm_ss_ttl"}      = 1;
    $^H{"Data::HashMap::SS/hm_ss_each"}       = 1;
    $^H{"Data::HashMap::SS/hm_ss_iter_reset"} = 1;
    $^H{"Data::HashMap::SS/hm_ss_clear"}      = 1;
    $^H{"Data::HashMap::SS/hm_ss_to_hash"}    = 1;
    $^H{"Data::HashMap::SS/hm_ss_put_ttl"}    = 1;
    $^H{"Data::HashMap::SS/hm_ss_get_or_set"} = 1;
}

1;
