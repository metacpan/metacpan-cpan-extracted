package DBIx::QuickORM::Test::ORM::Users;
use strict;
use warnings;

use DBIx::QuickORM::DSL qw/:table :row/;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Test::ORM::Users - A table class that is also its table's row class.

=head1 DESCRIPTION

Adjusts the C<users> table and is the class of its rows.

=cut

table {
    name 'users';
    omit qw/bio/;
    type prefs => 'JSON';
    fk orgs => {org_ref => 'id'};
};

row {
    parent;
};

sub display_name { "user " . $_[0]->field('name') }

1;
