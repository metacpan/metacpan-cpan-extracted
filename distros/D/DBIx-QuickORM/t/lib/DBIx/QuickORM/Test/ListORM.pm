package DBIx::QuickORM::Test::ListORM;
use strict;
use warnings;

use DBIx::QuickORM::DSL ':orm';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Test::ListORM - An ORM class listing its table classes.

=head1 DESCRIPTION

Uses only L<DBIx::QuickORM::Test::ORM::Orgs> of the table classes, and plain
hashrefs for every other table.

=cut

orm {
    tables ['DBIx::QuickORM::Test::ORM::Orgs'];
    row_class undef;
};

1;
