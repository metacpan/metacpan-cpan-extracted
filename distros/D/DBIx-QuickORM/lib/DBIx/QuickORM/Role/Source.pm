package DBIx::QuickORM::Role::Source;
use strict;
use warnings;

use Carp qw/croak confess/;

use Role::Tiny;

requires qw{
    source_db_moniker
    source_orm_name

    row_class
    primary_key

    field_type
    field_affinity

    has_field

    fields_to_fetch
    fields_to_omit
    fields_list_all
};

sub cachable {
    my $pk = $_[0]->primary_key or return 0;
    return 1 if @$pk;
    return 0;
}

1;
