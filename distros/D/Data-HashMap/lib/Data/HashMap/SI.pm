package Data::HashMap::SI;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.09';

sub import {
    $^H{"Data::HashMap::SI/hm_si_put"}     = 1;
    $^H{"Data::HashMap::SI/hm_si_get"}     = 1;
    $^H{"Data::HashMap::SI/hm_si_remove"}  = 1;
    $^H{"Data::HashMap::SI/hm_si_take"}   = 1;
    $^H{"Data::HashMap::SI/hm_si_drain"} = 1;
    $^H{"Data::HashMap::SI/hm_si_pop"}   = 1;
    $^H{"Data::HashMap::SI/hm_si_shift"} = 1;
    $^H{"Data::HashMap::SI/hm_si_reserve"} = 1;
    $^H{"Data::HashMap::SI/hm_si_purge"}   = 1;
    $^H{"Data::HashMap::SI/hm_si_capacity"} = 1;
    $^H{"Data::HashMap::SI/hm_si_persist"}  = 1;
    $^H{"Data::HashMap::SI/hm_si_swap"}    = 1;
    $^H{"Data::HashMap::SI/hm_si_cas"}     = 1;
    $^H{"Data::HashMap::SI/hm_si_exists"}  = 1;
    $^H{"Data::HashMap::SI/hm_si_incr"}    = 1;
    $^H{"Data::HashMap::SI/hm_si_decr"}    = 1;
    $^H{"Data::HashMap::SI/hm_si_incr_by"} = 1;
    $^H{"Data::HashMap::SI/hm_si_size"}    = 1;
    $^H{"Data::HashMap::SI/hm_si_keys"}    = 1;
    $^H{"Data::HashMap::SI/hm_si_values"}  = 1;
    $^H{"Data::HashMap::SI/hm_si_items"}    = 1;
    $^H{"Data::HashMap::SI/hm_si_max_size"} = 1;
    $^H{"Data::HashMap::SI/hm_si_ttl"}      = 1;
    $^H{"Data::HashMap::SI/hm_si_lru_skip"} = 1;
    $^H{"Data::HashMap::SI/hm_si_each"}       = 1;
    $^H{"Data::HashMap::SI/hm_si_iter_reset"} = 1;
    $^H{"Data::HashMap::SI/hm_si_clear"}      = 1;
    $^H{"Data::HashMap::SI/hm_si_to_hash"}    = 1;
    $^H{"Data::HashMap::SI/hm_si_put_ttl"}    = 1;
    $^H{"Data::HashMap::SI/hm_si_get_or_set"} = 1;
}

1;

__END__

=head1 NAME

Data::HashMap::SI - hash map from string keys to int64 values

=head1 SYNOPSIS

    use Data::HashMap::SI;
    my $map = Data::HashMap::SI->new;
    hm_si_put $map, "k", 2;
    my $v = hm_si_get $map, "k";

=head1 DESCRIPTION

One of the fourteen variants of L<Data::HashMap>, which documents the API, the
C<hm_si_*> keywords and every caveat.

=cut
