package Data::HashMap::IA;
use strict;
use warnings;
use Data::HashMap;
our $VERSION = '0.09';

sub import {
    $^H{"Data::HashMap::IA/hm_ia_put"}        = 1;
    $^H{"Data::HashMap::IA/hm_ia_get"}        = 1;
    $^H{"Data::HashMap::IA/hm_ia_remove"}     = 1;
    $^H{"Data::HashMap::IA/hm_ia_take"}   = 1;
    $^H{"Data::HashMap::IA/hm_ia_drain"} = 1;
    $^H{"Data::HashMap::IA/hm_ia_pop"}   = 1;
    $^H{"Data::HashMap::IA/hm_ia_shift"} = 1;
    $^H{"Data::HashMap::IA/hm_ia_reserve"} = 1;
    $^H{"Data::HashMap::IA/hm_ia_purge"}   = 1;
    $^H{"Data::HashMap::IA/hm_ia_capacity"} = 1;
    $^H{"Data::HashMap::IA/hm_ia_persist"}  = 1;
    $^H{"Data::HashMap::IA/hm_ia_swap"}    = 1;
    $^H{"Data::HashMap::IA/hm_ia_exists"}     = 1;
    $^H{"Data::HashMap::IA/hm_ia_size"}       = 1;
    $^H{"Data::HashMap::IA/hm_ia_keys"}       = 1;
    $^H{"Data::HashMap::IA/hm_ia_values"}     = 1;
    $^H{"Data::HashMap::IA/hm_ia_items"}      = 1;
    $^H{"Data::HashMap::IA/hm_ia_max_size"}   = 1;
    $^H{"Data::HashMap::IA/hm_ia_ttl"}        = 1;
    $^H{"Data::HashMap::IA/hm_ia_lru_skip"} = 1;
    $^H{"Data::HashMap::IA/hm_ia_each"}       = 1;
    $^H{"Data::HashMap::IA/hm_ia_iter_reset"} = 1;
    $^H{"Data::HashMap::IA/hm_ia_clear"}      = 1;
    $^H{"Data::HashMap::IA/hm_ia_to_hash"}    = 1;
    $^H{"Data::HashMap::IA/hm_ia_put_ttl"}    = 1;
    $^H{"Data::HashMap::IA/hm_ia_get_or_set"} = 1;
}

1;

__END__

=head1 NAME

Data::HashMap::IA - hash map from int64 keys to any Perl value values

=head1 SYNOPSIS

    use Data::HashMap::IA;
    my $map = Data::HashMap::IA->new;
    hm_ia_put $map, 1, [1, 2];
    my $v = hm_ia_get $map, 1;

=head1 DESCRIPTION

One of the fourteen variants of L<Data::HashMap>, which documents the API, the
C<hm_ia_*> keywords and every caveat.

=cut
