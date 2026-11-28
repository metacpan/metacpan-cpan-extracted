package DBIx::QuickORM::Test::ORM;
use strict;
use warnings;

use DBIx::QuickORM::Test::Row();
use DBIx::QuickORM::DSL ':orm';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Test::ORM - An ORM class whose table classes are found by namespace.

=head1 DESCRIPTION

For a database with the tables C<orgs>, C<users>, and C<audit>. Its table
classes are the C<table> packages under C<DBIx::QuickORM::Test::ORM::>.

=cut

orm {
    retain_cache 1;
    override(omit => {audit => ['payload'], users => ['name']}, row_class => 'DBIx::QuickORM::Test::Row');
};

1;
