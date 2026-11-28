package DBIx::QuickORM::Test::Row;
use strict;
use warnings;

use Object::HashBase qw{
    row_data
    <orm
    <table
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Test::Row - A minimal row class for tests.

=head1 DESCRIPTION

Holds what the ORM builds a row with: C<row_data>, C<orm>, and C<table>,
and C<set_row_data> for the primitives that hand a given row its new data.

=cut

1;
