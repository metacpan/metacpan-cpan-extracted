package DBIx::QuickORM::Test::ORM::OrgRow;
use strict;
use warnings;

use DBIx::QuickORM::DSL ':row';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Test::ORM::OrgRow - A row class in its own package.

=head1 DESCRIPTION

The row class of the C<orgs> table. It sits in the ORM's namespace without a
C<table> block, so the namespace search loads it and leaves it out.

=cut

row {
    parent;
};

sub label { "org " . $_[0]->field('name') }

1;
