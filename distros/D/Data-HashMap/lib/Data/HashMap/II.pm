package Data::HashMap::II;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.09';

sub import {
    $^H{"Data::HashMap::II/hm_ii_put"}     = 1;
    $^H{"Data::HashMap::II/hm_ii_get"}     = 1;
    $^H{"Data::HashMap::II/hm_ii_remove"}  = 1;
    $^H{"Data::HashMap::II/hm_ii_take"}   = 1;
    $^H{"Data::HashMap::II/hm_ii_drain"} = 1;
    $^H{"Data::HashMap::II/hm_ii_pop"}   = 1;
    $^H{"Data::HashMap::II/hm_ii_shift"} = 1;
    $^H{"Data::HashMap::II/hm_ii_reserve"} = 1;
    $^H{"Data::HashMap::II/hm_ii_purge"}   = 1;
    $^H{"Data::HashMap::II/hm_ii_capacity"} = 1;
    $^H{"Data::HashMap::II/hm_ii_persist"}  = 1;
    $^H{"Data::HashMap::II/hm_ii_swap"}    = 1;
    $^H{"Data::HashMap::II/hm_ii_cas"}     = 1;
    $^H{"Data::HashMap::II/hm_ii_exists"}  = 1;
    $^H{"Data::HashMap::II/hm_ii_incr"}    = 1;
    $^H{"Data::HashMap::II/hm_ii_decr"}    = 1;
    $^H{"Data::HashMap::II/hm_ii_incr_by"} = 1;
    $^H{"Data::HashMap::II/hm_ii_size"}    = 1;
    $^H{"Data::HashMap::II/hm_ii_keys"}    = 1;
    $^H{"Data::HashMap::II/hm_ii_values"}  = 1;
    $^H{"Data::HashMap::II/hm_ii_items"}    = 1;
    $^H{"Data::HashMap::II/hm_ii_max_size"} = 1;
    $^H{"Data::HashMap::II/hm_ii_ttl"}      = 1;
    $^H{"Data::HashMap::II/hm_ii_lru_skip"} = 1;
    $^H{"Data::HashMap::II/hm_ii_each"}       = 1;
    $^H{"Data::HashMap::II/hm_ii_iter_reset"} = 1;
    $^H{"Data::HashMap::II/hm_ii_clear"}      = 1;
    $^H{"Data::HashMap::II/hm_ii_to_hash"}    = 1;
    $^H{"Data::HashMap::II/hm_ii_put_ttl"}    = 1;
    $^H{"Data::HashMap::II/hm_ii_get_or_set"} = 1;
}

1;

__END__

=head1 NAME

Data::HashMap::II - hash map from int64 keys to int64 values

=head1 SYNOPSIS

    use Data::HashMap::II;
    my $map = Data::HashMap::II->new;
    hm_ii_put $map, 1, 2;
    my $v = hm_ii_get $map, 1;

=head1 DESCRIPTION

One of the fourteen variants of L<Data::HashMap>, which documents the API, the
C<hm_ii_*> keywords and every caveat.

=cut
