package Data::HashMap::IA;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.01';

sub import {
    $^H{"Data::HashMap::IA/hm_ia_put"}        = 1;
    $^H{"Data::HashMap::IA/hm_ia_get"}        = 1;
    $^H{"Data::HashMap::IA/hm_ia_remove"}     = 1;
    $^H{"Data::HashMap::IA/hm_ia_exists"}     = 1;
    $^H{"Data::HashMap::IA/hm_ia_size"}       = 1;
    $^H{"Data::HashMap::IA/hm_ia_keys"}       = 1;
    $^H{"Data::HashMap::IA/hm_ia_values"}     = 1;
    $^H{"Data::HashMap::IA/hm_ia_items"}      = 1;
    $^H{"Data::HashMap::IA/hm_ia_max_size"}   = 1;
    $^H{"Data::HashMap::IA/hm_ia_ttl"}        = 1;
    $^H{"Data::HashMap::IA/hm_ia_each"}       = 1;
    $^H{"Data::HashMap::IA/hm_ia_iter_reset"} = 1;
    $^H{"Data::HashMap::IA/hm_ia_clear"}      = 1;
    $^H{"Data::HashMap::IA/hm_ia_to_hash"}    = 1;
    $^H{"Data::HashMap::IA/hm_ia_put_ttl"}    = 1;
    $^H{"Data::HashMap::IA/hm_ia_get_or_set"} = 1;
}

1;
