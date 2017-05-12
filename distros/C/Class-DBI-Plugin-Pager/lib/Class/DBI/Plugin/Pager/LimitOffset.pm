package Class::DBI::Plugin::Pager::LimitOffset;
use strict;
use warnings;

use base 'Class::DBI::Plugin::Pager';

sub make_limit {
    my ( $self ) = @_;

    my $offset = $self->skipped;
    my $rows   = $self->entries_per_page;

    return "LIMIT $rows OFFSET $offset";
}

1;

