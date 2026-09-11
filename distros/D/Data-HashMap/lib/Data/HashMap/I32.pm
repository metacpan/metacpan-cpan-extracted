package Data::HashMap::I32;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.09';

sub import {
    $^H{"Data::HashMap::I32/hm_i32_put"}     = 1;
    $^H{"Data::HashMap::I32/hm_i32_get"}     = 1;
    $^H{"Data::HashMap::I32/hm_i32_remove"}  = 1;
    $^H{"Data::HashMap::I32/hm_i32_take"}   = 1;
    $^H{"Data::HashMap::I32/hm_i32_drain"} = 1;
    $^H{"Data::HashMap::I32/hm_i32_pop"}   = 1;
    $^H{"Data::HashMap::I32/hm_i32_shift"} = 1;
    $^H{"Data::HashMap::I32/hm_i32_reserve"} = 1;
    $^H{"Data::HashMap::I32/hm_i32_purge"}   = 1;
    $^H{"Data::HashMap::I32/hm_i32_capacity"} = 1;
    $^H{"Data::HashMap::I32/hm_i32_persist"}  = 1;
    $^H{"Data::HashMap::I32/hm_i32_swap"}    = 1;
    $^H{"Data::HashMap::I32/hm_i32_cas"}     = 1;
    $^H{"Data::HashMap::I32/hm_i32_exists"}  = 1;
    $^H{"Data::HashMap::I32/hm_i32_incr"}    = 1;
    $^H{"Data::HashMap::I32/hm_i32_decr"}    = 1;
    $^H{"Data::HashMap::I32/hm_i32_incr_by"} = 1;
    $^H{"Data::HashMap::I32/hm_i32_size"}    = 1;
    $^H{"Data::HashMap::I32/hm_i32_keys"}    = 1;
    $^H{"Data::HashMap::I32/hm_i32_values"}  = 1;
    $^H{"Data::HashMap::I32/hm_i32_items"}    = 1;
    $^H{"Data::HashMap::I32/hm_i32_max_size"} = 1;
    $^H{"Data::HashMap::I32/hm_i32_ttl"}      = 1;
    $^H{"Data::HashMap::I32/hm_i32_lru_skip"} = 1;
    $^H{"Data::HashMap::I32/hm_i32_each"}       = 1;
    $^H{"Data::HashMap::I32/hm_i32_iter_reset"} = 1;
    $^H{"Data::HashMap::I32/hm_i32_clear"}      = 1;
    $^H{"Data::HashMap::I32/hm_i32_to_hash"}    = 1;
    $^H{"Data::HashMap::I32/hm_i32_put_ttl"}    = 1;
    $^H{"Data::HashMap::I32/hm_i32_get_or_set"} = 1;
}

1;

__END__

=head1 NAME

Data::HashMap::I32 - hash map from int32 keys to int32 values

=head1 SYNOPSIS

    use Data::HashMap::I32;
    my $map = Data::HashMap::I32->new;
    hm_i32_put $map, 1, 2;
    my $v = hm_i32_get $map, 1;

=head1 DESCRIPTION

One of the fourteen variants of L<Data::HashMap>, which documents the API, the
C<hm_i32_*> keywords and every caveat.

=cut
