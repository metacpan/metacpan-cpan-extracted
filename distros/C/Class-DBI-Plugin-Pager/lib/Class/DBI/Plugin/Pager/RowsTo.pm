package Class::DBI::Plugin::Pager::RowsTo;
use strict;
use warnings;

use base 'Class::DBI::Plugin::Pager';

sub make_limit {
    my ( $self ) = @_;

    my $offset = $self->skipped;
    my $rows   = $self->entries_per_page;

    my $last = $rows + $offset;

    return "ROWS $offset TO $last";
}

1;

