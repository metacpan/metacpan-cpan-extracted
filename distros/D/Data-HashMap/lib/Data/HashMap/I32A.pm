package Data::HashMap::I32A;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.09';

sub import {
    $^H{"Data::HashMap::I32A/hm_i32a_put"}        = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_get"}        = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_remove"}     = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_take"}   = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_drain"} = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_pop"}   = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_shift"} = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_reserve"} = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_purge"}   = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_capacity"} = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_persist"}  = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_swap"}    = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_exists"}     = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_size"}       = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_keys"}       = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_values"}     = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_items"}      = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_max_size"}   = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_ttl"}        = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_lru_skip"} = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_each"}       = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_iter_reset"} = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_clear"}      = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_to_hash"}    = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_put_ttl"}    = 1;
    $^H{"Data::HashMap::I32A/hm_i32a_get_or_set"} = 1;
}

1;

__END__

=head1 NAME

Data::HashMap::I32A - hash map from int32 keys to any Perl value values

=head1 SYNOPSIS

    use Data::HashMap::I32A;
    my $map = Data::HashMap::I32A->new;
    hm_i32a_put $map, 1, [1, 2];
    my $v = hm_i32a_get $map, 1;

=head1 DESCRIPTION

One of the fourteen variants of L<Data::HashMap>, which documents the API, the
C<hm_i32a_*> keywords and every caveat.

=cut
