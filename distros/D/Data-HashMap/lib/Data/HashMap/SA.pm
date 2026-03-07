package Data::HashMap::SA;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.01';

sub import {
    $^H{"Data::HashMap::SA/hm_sa_put"}        = 1;
    $^H{"Data::HashMap::SA/hm_sa_get"}        = 1;
    $^H{"Data::HashMap::SA/hm_sa_remove"}     = 1;
    $^H{"Data::HashMap::SA/hm_sa_exists"}     = 1;
    $^H{"Data::HashMap::SA/hm_sa_size"}       = 1;
    $^H{"Data::HashMap::SA/hm_sa_keys"}       = 1;
    $^H{"Data::HashMap::SA/hm_sa_values"}     = 1;
    $^H{"Data::HashMap::SA/hm_sa_items"}      = 1;
    $^H{"Data::HashMap::SA/hm_sa_max_size"}   = 1;
    $^H{"Data::HashMap::SA/hm_sa_ttl"}        = 1;
    $^H{"Data::HashMap::SA/hm_sa_each"}       = 1;
    $^H{"Data::HashMap::SA/hm_sa_iter_reset"} = 1;
    $^H{"Data::HashMap::SA/hm_sa_clear"}      = 1;
    $^H{"Data::HashMap::SA/hm_sa_to_hash"}    = 1;
    $^H{"Data::HashMap::SA/hm_sa_put_ttl"}    = 1;
    $^H{"Data::HashMap::SA/hm_sa_get_or_set"} = 1;
}

1;
