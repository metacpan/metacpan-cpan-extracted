package Data::HashMap::I16A;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.09';

sub import {
    $^H{"Data::HashMap::I16A/hm_i16a_put"}        = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_get"}        = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_remove"}     = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_take"}   = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_drain"} = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_pop"}   = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_shift"} = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_reserve"} = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_purge"}   = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_capacity"} = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_persist"}  = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_swap"}    = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_exists"}     = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_size"}       = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_keys"}       = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_values"}     = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_items"}      = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_max_size"}   = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_ttl"}        = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_lru_skip"} = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_each"}       = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_iter_reset"} = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_clear"}      = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_to_hash"}    = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_put_ttl"}    = 1;
    $^H{"Data::HashMap::I16A/hm_i16a_get_or_set"} = 1;
}

1;

__END__

=head1 NAME

Data::HashMap::I16A - hash map from int16 keys to any Perl value values

=head1 SYNOPSIS

    use Data::HashMap::I16A;
    my $map = Data::HashMap::I16A->new;
    hm_i16a_put $map, 1, [1, 2];
    my $v = hm_i16a_get $map, 1;

=head1 DESCRIPTION

One of the fourteen variants of L<Data::HashMap>, which documents the API, the
C<hm_i16a_*> keywords and every caveat.

=cut
