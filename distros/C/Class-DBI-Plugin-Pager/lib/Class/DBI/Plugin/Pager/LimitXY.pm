package Class::DBI::Plugin::Pager::LimitXY;
use strict;
use warnings;

use base 'Class::DBI::Plugin::Pager';

sub make_limit {
    my ( $self ) = @_;

    my $offset = $self->skipped;
    my $rows   = $self->entries_per_page;

    return "LIMIT $offset, $rows";
}

1;
