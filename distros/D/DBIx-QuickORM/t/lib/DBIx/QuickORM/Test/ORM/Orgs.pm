package DBIx::QuickORM::Test::ORM::Orgs;
use strict;
use warnings;

use DBIx::QuickORM::DSL ':table';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Test::ORM::Orgs - A table class whose rows use another class.

=head1 DESCRIPTION

Adjusts the C<orgs> table. Its rows are
L<DBIx::QuickORM::Test::ORM::OrgRow> objects.

=cut

table {
    name 'orgs';
    row_class 'DBIx::QuickORM::Test::ORM::OrgRow';
};

1;
