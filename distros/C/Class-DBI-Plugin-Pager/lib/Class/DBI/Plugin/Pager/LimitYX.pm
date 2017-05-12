package Class::DBI::Plugin::Pager::LimitYX;
use strict;
use warnings;

use base 'Class::DBI::Plugin::Pager';

sub make_limit {
    my ( $self ) = @_;

    my $offset = $self->skipped;
    my $rows   = $self->entries_per_page;

    # SQLite (but it can also use LimitOffset)
    return "LIMIT $rows, $offset";
}

1;
