package Data::HashMap::I16S;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.01';

sub import {
    $^H{"Data::HashMap::I16S/hm_i16s_put"}    = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_get"}    = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_remove"} = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_exists"} = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_size"}   = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_keys"}   = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_values"} = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_items"}    = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_max_size"} = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_ttl"}      = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_each"}       = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_iter_reset"} = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_clear"}      = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_to_hash"}    = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_put_ttl"}    = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_get_or_set"} = 1;
}

1;
