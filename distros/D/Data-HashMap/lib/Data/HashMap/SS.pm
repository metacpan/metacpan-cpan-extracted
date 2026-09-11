package Data::HashMap::SS;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.09';

sub import {
    $^H{"Data::HashMap::SS/hm_ss_put"}    = 1;
    $^H{"Data::HashMap::SS/hm_ss_get"}    = 1;
    $^H{"Data::HashMap::SS/hm_ss_remove"} = 1;
    $^H{"Data::HashMap::SS/hm_ss_take"}   = 1;
    $^H{"Data::HashMap::SS/hm_ss_drain"} = 1;
    $^H{"Data::HashMap::SS/hm_ss_pop"}   = 1;
    $^H{"Data::HashMap::SS/hm_ss_shift"} = 1;
    $^H{"Data::HashMap::SS/hm_ss_reserve"} = 1;
    $^H{"Data::HashMap::SS/hm_ss_purge"}   = 1;
    $^H{"Data::HashMap::SS/hm_ss_capacity"} = 1;
    $^H{"Data::HashMap::SS/hm_ss_persist"}  = 1;
    $^H{"Data::HashMap::SS/hm_ss_swap"}    = 1;
    $^H{"Data::HashMap::SS/hm_ss_exists"} = 1;
    $^H{"Data::HashMap::SS/hm_ss_size"}   = 1;
    $^H{"Data::HashMap::SS/hm_ss_keys"}   = 1;
    $^H{"Data::HashMap::SS/hm_ss_values"} = 1;
    $^H{"Data::HashMap::SS/hm_ss_items"}    = 1;
    $^H{"Data::HashMap::SS/hm_ss_max_size"} = 1;
    $^H{"Data::HashMap::SS/hm_ss_ttl"}      = 1;
    $^H{"Data::HashMap::SS/hm_ss_lru_skip"} = 1;
    $^H{"Data::HashMap::SS/hm_ss_each"}       = 1;
    $^H{"Data::HashMap::SS/hm_ss_iter_reset"} = 1;
    $^H{"Data::HashMap::SS/hm_ss_clear"}      = 1;
    $^H{"Data::HashMap::SS/hm_ss_to_hash"}    = 1;
    $^H{"Data::HashMap::SS/hm_ss_put_ttl"}    = 1;
    $^H{"Data::HashMap::SS/hm_ss_get_or_set"} = 1;
    $^H{"Data::HashMap::SS/hm_ss_get_direct"} = 1;
}

1;

__END__

=head1 NAME

Data::HashMap::SS - hash map from string keys to string values

=head1 SYNOPSIS

    use Data::HashMap::SS;
    my $map = Data::HashMap::SS->new;
    hm_ss_put $map, "k", "v";
    my $v = hm_ss_get $map, "k";

=head1 DESCRIPTION

One of the fourteen variants of L<Data::HashMap>, which documents the API, the
C<hm_ss_*> keywords and every caveat.

=cut
