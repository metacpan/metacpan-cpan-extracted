package Data::HashMap::IS;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.09';

sub import {
    $^H{"Data::HashMap::IS/hm_is_put"}    = 1;
    $^H{"Data::HashMap::IS/hm_is_get"}    = 1;
    $^H{"Data::HashMap::IS/hm_is_remove"} = 1;
    $^H{"Data::HashMap::IS/hm_is_take"}   = 1;
    $^H{"Data::HashMap::IS/hm_is_drain"} = 1;
    $^H{"Data::HashMap::IS/hm_is_pop"}   = 1;
    $^H{"Data::HashMap::IS/hm_is_shift"} = 1;
    $^H{"Data::HashMap::IS/hm_is_reserve"} = 1;
    $^H{"Data::HashMap::IS/hm_is_purge"}   = 1;
    $^H{"Data::HashMap::IS/hm_is_capacity"} = 1;
    $^H{"Data::HashMap::IS/hm_is_persist"}  = 1;
    $^H{"Data::HashMap::IS/hm_is_swap"}    = 1;
    $^H{"Data::HashMap::IS/hm_is_exists"} = 1;
    $^H{"Data::HashMap::IS/hm_is_size"}   = 1;
    $^H{"Data::HashMap::IS/hm_is_keys"}   = 1;
    $^H{"Data::HashMap::IS/hm_is_values"} = 1;
    $^H{"Data::HashMap::IS/hm_is_items"}    = 1;
    $^H{"Data::HashMap::IS/hm_is_max_size"} = 1;
    $^H{"Data::HashMap::IS/hm_is_ttl"}      = 1;
    $^H{"Data::HashMap::IS/hm_is_lru_skip"} = 1;
    $^H{"Data::HashMap::IS/hm_is_each"}       = 1;
    $^H{"Data::HashMap::IS/hm_is_iter_reset"} = 1;
    $^H{"Data::HashMap::IS/hm_is_clear"}      = 1;
    $^H{"Data::HashMap::IS/hm_is_to_hash"}    = 1;
    $^H{"Data::HashMap::IS/hm_is_put_ttl"}    = 1;
    $^H{"Data::HashMap::IS/hm_is_get_or_set"} = 1;
    $^H{"Data::HashMap::IS/hm_is_get_direct"} = 1;
}

1;

__END__

=head1 NAME

Data::HashMap::IS - hash map from int64 keys to string values

=head1 SYNOPSIS

    use Data::HashMap::IS;
    my $map = Data::HashMap::IS->new;
    hm_is_put $map, 1, "v";
    my $v = hm_is_get $map, 1;

=head1 DESCRIPTION

One of the fourteen variants of L<Data::HashMap>, which documents the API, the
C<hm_is_*> keywords and every caveat.

=cut
