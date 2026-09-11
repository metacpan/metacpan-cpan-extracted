package Data::HashMap::I16S;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.09';

sub import {
    $^H{"Data::HashMap::I16S/hm_i16s_put"}    = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_get"}    = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_remove"} = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_take"}   = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_drain"} = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_pop"}   = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_shift"} = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_reserve"} = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_purge"}   = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_capacity"} = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_persist"}  = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_swap"}    = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_exists"} = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_size"}   = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_keys"}   = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_values"} = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_items"}    = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_max_size"} = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_ttl"}      = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_lru_skip"} = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_each"}       = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_iter_reset"} = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_clear"}      = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_to_hash"}    = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_put_ttl"}    = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_get_or_set"} = 1;
    $^H{"Data::HashMap::I16S/hm_i16s_get_direct"} = 1;
}

1;

__END__

=head1 NAME

Data::HashMap::I16S - hash map from int16 keys to string values

=head1 SYNOPSIS

    use Data::HashMap::I16S;
    my $map = Data::HashMap::I16S->new;
    hm_i16s_put $map, 1, "v";
    my $v = hm_i16s_get $map, 1;

=head1 DESCRIPTION

One of the fourteen variants of L<Data::HashMap>, which documents the API, the
C<hm_i16s_*> keywords and every caveat.

=cut
