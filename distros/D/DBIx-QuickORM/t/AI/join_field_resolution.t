# '!L': this test defines its own L() helper for Link objects, which would
# otherwise clash with Test2::Tools::Compare's exported L() (array-check builder).
use Test2::V0 '!meta', '!pass', '!L';

# Regression tests for Join field/alias resolution:
#  B5: a bare (unqualified) field present in more than one component must be a
#      clean ambiguity, not a silent first-match.
#  B6: inferring the join 'from' side must catch an ambiguous table even when it
#      is the primary source (self-join), not silently pick the first alias.
#  B10: alias.field protos must split on the first dot (as Join::Row does), and a
#      caller-supplied 'as' must be a valid identifier.

use DBIx::QuickORM::Schema;
use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;
use DBIx::QuickORM::Link;
use DBIx::QuickORM::Join;

my $C = 'DBIx::QuickORM::Schema::Table::Column';
sub col { $C->new(name => $_[0], order => $_[1], affinity => 'string') }
sub L { DBIx::QuickORM::Link->new(@_) }

subtest bare_field_ambiguity_and_proto_split => sub {
    my $authors = DBIx::QuickORM::Schema::Table->new(name => 'authors', columns => {id => col('id', 1), name => col('name', 2)}, primary_key => ['id']);
    my $abooks  = L(local_table => 'authors', other_table => 'books', local_columns => ['id'], other_columns => ['author_id'], unique => 0);
    my $books   = DBIx::QuickORM::Schema::Table->new(name => 'books', columns => {id => col('id', 1), name => col('name', 2), author_id => col('author_id', 3)}, primary_key => ['id']);
    my $schema  = DBIx::QuickORM::Schema->new(name => 's', tables => {authors => $authors, books => $books});
    my $join    = DBIx::QuickORM::Join->new(schema => $schema, primary_source => $authors)->left_join($abooks);

    like(dies { $join->_field_source('name') }, qr/ambiguous/i, "a bare field present in two components croaks as ambiguous");

    my @q = $join->_field_source('a.name');
    is($q[0], 'a', "a qualified proto resolves to its alias");

    # First-dot split (matches Join::Row's split ..., 2).
    my @deep = $join->_field_source('a.weird.field');
    is($deep[0], 'a',           "alias.field split takes the alias before the first dot");
    is($deep[2], 'weird.field', "and keeps the rest of the proto as the field");
};

subtest as_must_be_identifier => sub {
    my $authors = DBIx::QuickORM::Schema::Table->new(name => 'authors', columns => {id => col('id', 1)}, primary_key => ['id']);
    my $abooks  = L(local_table => 'authors', other_table => 'books', local_columns => ['id'], other_columns => ['author_id'], unique => 0);
    my $books   = DBIx::QuickORM::Schema::Table->new(name => 'books', columns => {id => col('id', 1), author_id => col('author_id', 2)}, primary_key => ['id']);
    my $schema  = DBIx::QuickORM::Schema->new(name => 's', tables => {authors => $authors, books => $books});
    my $join    = DBIx::QuickORM::Join->new(schema => $schema, primary_source => $authors);

    like(
        dies { my $x = $join->left_join(link => $abooks, as => 'x.y') },
        qr/may not contain a '\.'/,
        "a caller-supplied alias containing a dot is rejected",
    );
    ok(lives { my $x = $join->left_join(link => $abooks, as => 'good') }, "a dot-free alias is accepted");
    ok(lives { my $x = $join->left_join(link => $abooks, as => 'odd alias') }, "a non-dot alias (quoted as an identifier) is accepted");
};

subtest self_join_primary_ambiguity => sub {
    my $mgr  = L(local_table => 'emp', other_table => 'emp', local_columns => ['manager_id'], other_columns => ['id'], unique => 1, aliases => ['manager']);
    my $dept = L(local_table => 'emp', other_table => 'dept', local_columns => ['dept_id'], other_columns => ['id'], unique => 1);
    my $emp  = DBIx::QuickORM::Schema::Table->new(name => 'emp', columns => {id => col('id', 1), manager_id => col('manager_id', 2), dept_id => col('dept_id', 3)}, primary_key => ['id']);
    my $dt   = DBIx::QuickORM::Schema::Table->new(name => 'dept', columns => {id => col('id', 1)}, primary_key => ['id']);
    my $sc   = DBIx::QuickORM::Schema->new(name => 's2', tables => {emp => $emp, dept => $dt});

    # After the self-join, 'emp' has two aliases; joining a link whose local
    # table is emp without a from must not silently attach to the primary alias.
    my $sj = DBIx::QuickORM::Join->new(schema => $sc, primary_source => $emp)->left_join($mgr);
    like(
        dies { my $x = $sj->left_join($dept) },
        qr/joined multiple times/,
        "joining from an ambiguous primary self-join requires an explicit from",
    );
};

done_testing;
