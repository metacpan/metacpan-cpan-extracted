use strict;
use warnings;
use Test::More;

use DBIO::Sybase::DDL;

# install_ddl emits the source's unique constraints (karr k56). It read only
# the column flags is_unique / is_single_unique_key and ignored
# add_unique_constraint, so a deployed database had none of those constraints
# -- and, installed from the same DDL, the compare database neither, so no
# diff noticed. Each becomes a CREATE UNIQUE INDEX named after the constraint.
{
  package K56::Thing;
  use base 'DBIO::Core';
  __PACKAGE__->table('thing');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    code => { data_type => 'varchar', size => 8, is_unique => 1 },
    a    => { data_type => 'integer' },
    b    => { data_type => 'integer' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->add_unique_constraint(thing_ba   => [qw/b a/]);   # kept, column order kept
  __PACKAGE__->add_unique_constraint(thing_x_ab => [qw/a b/]);   # same set as thing_ba
  __PACKAGE__->add_unique_constraint(thing_code => ['code']);    # the column flag's set
  __PACKAGE__->add_unique_constraint(thing_id   => ['id']);      # the key's set

  package K56::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Thing => 'K56::Thing');
}

my @idx = grep { /INDEX/ } split /\n\n/, DBIO::Sybase::DDL->install_ddl('K56::Schema');

is_deeply \@idx, [
  'CREATE UNIQUE INDEX thing_code_idx ON thing (code);',
  'CREATE UNIQUE INDEX thing_ba ON thing (b, a);',
], 'one unique index per distinct unique column set: the flag, then the constraint';

# What the list above leaves out, spelled out: 'primary' (the key's own
# constraint), thing_id (the key's set), thing_code (the flag's set) and
# thing_x_ab (thing_ba's set; the first by constraint name wins).
ok !(grep { /\b(?:primary|thing_id|thing_code|thing_x_ab)\b/ } @idx),
  'no index for the key, nor a second one over an already unique set';

done_testing;
