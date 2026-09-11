package Data::HashMap::I32S;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.09';

sub import {
    $^H{"Data::HashMap::I32S/hm_i32s_put"}    = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_get"}    = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_remove"} = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_take"}   = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_drain"} = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_pop"}   = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_shift"} = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_reserve"} = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_purge"}   = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_capacity"} = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_persist"}  = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_swap"}    = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_exists"} = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_size"}   = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_keys"}   = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_values"} = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_items"}    = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_max_size"} = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_ttl"}      = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_lru_skip"} = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_each"}       = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_iter_reset"} = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_clear"}      = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_to_hash"}    = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_put_ttl"}    = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_get_or_set"} = 1;
    $^H{"Data::HashMap::I32S/hm_i32s_get_direct"} = 1;
}

1;

__END__

=head1 NAME

Data::HashMap::I32S - hash map from int32 keys to string values

=head1 SYNOPSIS

    use Data::HashMap::I32S;
    my $map = Data::HashMap::I32S->new;
    hm_i32s_put $map, 1, "v";
    my $v = hm_i32s_get $map, 1;

=head1 DESCRIPTION

One of the fourteen variants of L<Data::HashMap>, which documents the API, the
C<hm_i32s_*> keywords and every caveat.

=cut
