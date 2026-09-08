package Data::HashMap::Shared::SI32;
use strict;
use warnings;
use Data::HashMap::Shared;
our $VERSION = '0.20';

my @KEYWORDS = qw(
    put get remove exists incr decr incr_by max min size keys values
    items each iter_reset clear to_hash max_entries get_or_set put_ttl
    max_size ttl cursor cursor_next cursor_seek ttl_remaining capacity
    tombstones cursor_reset take pop shift drain flush_expired
    flush_expired_partial mmap_size touch reserve stat_evictions
    stat_expired stat_recoveries arena_used arena_cap add add_ttl
    update_ttl update swap cas cas_take persist set_ttl
);

sub import {
    $^H{__PACKAGE__ . "/shm_si32_$_"} = 1 for @KEYWORDS;
}

sub unimport {
    my $prefix = __PACKAGE__ . '/';
    delete $^H{$_} for grep { index($_, $prefix) == 0 } CORE::keys(%^H);
}

1;

__END__

=head1 NAME

Data::HashMap::Shared::SI32 - shared-memory hash map, string keys to int32 values

=head1 DESCRIPTION

One of the ten typed variants of L<Data::HashMap::Shared>. See that module for
the constructor, the full API and the keyword forms, and
L<Data::HashMap::Shared/Variants> for choosing between them.

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
