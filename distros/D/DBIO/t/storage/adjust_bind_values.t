use strict;
use warnings;

# The seam _adjust_bind_values($sth, $bind, $bind_attrs) is the one place a
# driver changes the values it binds. Every path that binds -- the per-statement
# _bind_sth_params (create, search, update) and the populate fast path
# (_dbh_execute_for_fetch) -- must run the values through it, so that populate
# in void context writes what create writes. DBIO::Test::Storage replaces
# _insert_bulk and _prepare_sth, so the real binding methods are driven here
# with a recording statement handle.

use Test::More;

use lib 't/lib';
use DBIO::Test;

{
  package Local::RecordingSth;

  sub new { bless { bound => {}, rows => [] }, shift }

  sub bind_param {
    my ($self, $i, $v, $attr) = @_;
    $self->{bound}{$i} = [ $v, $attr ];
    1;
  }

  sub execute_for_fetch {
    my ($self, $fetch) = @_;
    while (my $row = $fetch->()) { push @{ $self->{rows} }, $row }
    scalar @{ $self->{rows} };
  }

  sub finish { 1 }
  sub err { undef }
  sub errstr { undef }
}

{
  package Local::UpcasingStorage;
  our @ISA = ('DBIO::Test::Storage');

  # a driver's value adjustment: copy the pairs, never write into the originals
  sub _adjust_bind_values {
    my ($self, $sth, $bind, $bind_attrs) = @_;
    return [ map {
      [ $_->[0], ( defined $_->[1] and !ref $_->[1] ) ? uc $_->[1] : $_->[1] ]
    } @$bind ];
  }
}

my $schema = DBIO::Test->init_schema;
my $storage = $schema->storage;
my $source  = $schema->source('Artist');

# default seam: identity, the very list it was given
{
  my $bind = [ [ { dbic_colname => 'name' }, 'abc' ] ];
  is $storage->_adjust_bind_values(undef, $bind, [ undef ]), $bind,
    'default _adjust_bind_values hands $bind back unchanged';
}

bless $storage, 'Local::UpcasingStorage';

# per-statement path: _bind_sth_params
{
  my $sth  = Local::RecordingSth->new;
  my $meta = { dbic_colname => 'name', sqlt_datatype => 'varchar' };
  my $bind = [ [ $meta, 'abc' ] ];

  $storage->_bind_sth_params($sth, $bind, [ 12 ]);

  is_deeply $sth->{bound}{1}, [ 'ABC', 12 ],
    '_bind_sth_params binds the adjusted value with its attribute';
  is $bind->[0][1], 'abc', "the caller's bind value is untouched";
}

# bulk path: _dbh_execute_for_fetch, as populate in void context reaches it
{
  my $sth = Local::RecordingSth->new;
  my $proto_bind = [
    [ { dbic_colname => 'name', sqlt_datatype => 'varchar', _bind_data_slice_idx => 0 }, undef ],
    [ { dbic_colname => 'rank', sqlt_datatype => 'integer', _bind_data_slice_idx => 1 }, undef ],
  ];
  my $data = [ [ 'one', 1 ], [ 'two', 2 ] ];

  $storage->_dbh_execute_for_fetch($source, $sth, $proto_bind, [ qw(name rank) ], $data);

  is_deeply $sth->{rows}, [ [ 'ONE', 1 ], [ 'TWO', 2 ] ],
    'populate rows reach execute_for_fetch through _adjust_bind_values';
  is_deeply $data, [ [ 'one', 1 ], [ 'two', 2 ] ],
    "the caller's populate data is untouched";
}

done_testing;
