package Data::HashMap::SA;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.09';

sub import {
    $^H{"Data::HashMap::SA/hm_sa_put"}        = 1;
    $^H{"Data::HashMap::SA/hm_sa_get"}        = 1;
    $^H{"Data::HashMap::SA/hm_sa_remove"}     = 1;
    $^H{"Data::HashMap::SA/hm_sa_take"}   = 1;
    $^H{"Data::HashMap::SA/hm_sa_drain"} = 1;
    $^H{"Data::HashMap::SA/hm_sa_pop"}   = 1;
    $^H{"Data::HashMap::SA/hm_sa_shift"} = 1;
    $^H{"Data::HashMap::SA/hm_sa_reserve"} = 1;
    $^H{"Data::HashMap::SA/hm_sa_purge"}   = 1;
    $^H{"Data::HashMap::SA/hm_sa_capacity"} = 1;
    $^H{"Data::HashMap::SA/hm_sa_persist"}  = 1;
    $^H{"Data::HashMap::SA/hm_sa_swap"}    = 1;
    $^H{"Data::HashMap::SA/hm_sa_exists"}     = 1;
    $^H{"Data::HashMap::SA/hm_sa_size"}       = 1;
    $^H{"Data::HashMap::SA/hm_sa_keys"}       = 1;
    $^H{"Data::HashMap::SA/hm_sa_values"}     = 1;
    $^H{"Data::HashMap::SA/hm_sa_items"}      = 1;
    $^H{"Data::HashMap::SA/hm_sa_max_size"}   = 1;
    $^H{"Data::HashMap::SA/hm_sa_ttl"}        = 1;
    $^H{"Data::HashMap::SA/hm_sa_lru_skip"} = 1;
    $^H{"Data::HashMap::SA/hm_sa_each"}       = 1;
    $^H{"Data::HashMap::SA/hm_sa_iter_reset"} = 1;
    $^H{"Data::HashMap::SA/hm_sa_clear"}      = 1;
    $^H{"Data::HashMap::SA/hm_sa_to_hash"}    = 1;
    $^H{"Data::HashMap::SA/hm_sa_put_ttl"}    = 1;
    $^H{"Data::HashMap::SA/hm_sa_get_or_set"} = 1;
}

1;

__END__

=head1 NAME

Data::HashMap::SA - hash map from string keys to any Perl value values

=head1 SYNOPSIS

    use Data::HashMap::SA;
    my $map = Data::HashMap::SA->new;
    hm_sa_put $map, "k", [1, 2];
    my $v = hm_sa_get $map, "k";

=head1 DESCRIPTION

One of the fourteen variants of L<Data::HashMap>, which documents the API, the
C<hm_sa_*> keywords and every caveat.

=cut
