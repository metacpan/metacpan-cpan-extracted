use strict;
use warnings;
use Test::More;

use DBIO::Test::Schema;

# karr k63, case bind-non-ascii. A Perl string without the UTF-8 flag is a
# sequence of Latin-1 code points, but DBD::Oracle sends it as bytes. The
# storage upgrades a bind whose data type is a character type, on a copy, and
# leaves a binary type and a bind without a data type as they are. The
# upgrade sits in the one core seam for changed values, _adjust_bind_values
# (karr k66): the binds of a statement and each row of a populate pass it.
# Offline: fake statement handles record what reaches them.

{
  package T::Sth;
  sub new { bless { got => [] }, shift }
  sub bind_param { push @{ $_[0]{got} }, [ @_[1, 2] ]; 1 }
  sub bind_param_inout { push @{ $_[0]{got} }, [ @_[1, 2] ]; 1 }
  sub got { $_[0]{got} }
}

my $schema = DBIO::Test::Schema->clone;
$schema->storage_type('+DBIO::Oracle::Storage');
my $connected = $schema->connect("dbi:Oracle:never", "u", "p");
my $storage   = $connected->storage;

sub sent {
  my ($type, $value) = @_;
  my @meta = defined $type ? ({ sqlt_datatype => $type }) : ({});
  my $bind = $storage->_adjust_bind_values(T::Sth->new, [ [ @meta, $value ] ], [ undef ]);
  return $bind->[0][1];
}

for my $type ('char', 'varchar', 'varchar2', 'VARCHAR2(20 CHAR)', 'nchar', 'nvarchar',
              'nvarchar2', 'text', 'clob', 'nclob', 'long', 'varchar(255)') {
  my $v = sent($type, "\x{fc}");
  ok utf8::is_utf8($v), "$type: the bind is upgraded";
  is ord $v, 0xFC, "$type: still the same character";
}

for my $type ('blob', 'raw', 'long raw', 'binary', 'varbinary', 'bytea', 'integer', 'number') {
  my $v = sent($type, "\x{fc}");
  ok !utf8::is_utf8($v), "$type: sent as it is";
  is $v, "\x{fc}", "$type: value unchanged";
}

{
  my $v = sent(undef, "\x{fc}");
  ok !utf8::is_utf8($v), 'no data type: sent as it is';
}

{
  my $orig = "\x{fc}";
  my $v = sent('varchar', $orig);
  ok utf8::is_utf8($v), 'the copy is upgraded';
  ok !utf8::is_utf8($orig), 'the caller\'s string is not touched';
}

is sent('varchar', undef), undef, 'NULL stays NULL';
is sent('varchar', 'abc'), 'abc', 'ASCII is unchanged';

{
  my $bind = [ [ { sqlt_datatype => 'varchar' }, "\x{e4}" ] ];
  my $out  = $storage->_adjust_bind_values(T::Sth->new, $bind, [ undef ]);
  ok !utf8::is_utf8($bind->[0][1]), 'the bind array of the caller keeps its string';
  isnt $out, $bind, 'the answer is a new list ...';
  isnt $out->[0], $bind->[0], '... of new pairs';
  is $out->[0][0], $bind->[0][0], '... that keep the meta';
}

{
  my $target = "\x{fc}";
  my $out = $storage->_adjust_bind_values(
    T::Sth->new, [ [ { sqlt_datatype => 'varchar' }, \$target ] ], [ undef ]);
  is $out->[0][1], \$target, 'a scalar reference (bind_param_inout) stays the very same reference';
}

# statements bound one by one reach the seam through core's _bind_sth_params
{
  my $sth = T::Sth->new;
  $storage->_bind_sth_params($sth,
    [ [ { sqlt_datatype => 'varchar' }, "\x{fc}" ], [ { sqlt_datatype => 'blob' }, "\x{fc}" ] ],
    [ undef, undef ]);
  ok utf8::is_utf8($sth->got->[0][1]), 'bound one by one: the character bind is upgraded';
  ok !utf8::is_utf8($sth->got->[1][1]), '... the binary one is not';
}

# the bulk path, through core's own _dbh_execute_for_fetch: the values of each
# row come from the data rows by slot and pass the seam one row at a time
{
  package T::BulkSth;
  sub new { bless { rows => [] }, shift }
  sub bind_param { 1 }
  sub errstr { '' }
  sub err { 0 }
  sub finish { 1 }
  sub execute_for_fetch {
    my ($s, $fetch, $status) = @_;
    while (my $row = $fetch->()) { push @{ $s->{rows} }, $row }
    return scalar @{ $s->{rows} };
  }
}

{
  my $sth   = T::BulkSth->new;
  my $proto = [
    [ { sqlt_datatype => 'varchar', _bind_data_slice_idx => 0 }, undef ],
    [ { sqlt_datatype => 'blob',    _bind_data_slice_idx => 1 }, undef ],
  ];
  my $data = [ [ "\x{fc}", "\x{fc}" ], [ "abc", "\x{e4}" ] ];
  $storage->_dbh_execute_for_fetch($connected->source("Artist"), $sth, $proto, [qw(a b)], $data);
  my @rows = @{ $sth->{rows} };
  is scalar @rows, 2, 'populate: both rows reach the statement';
  ok utf8::is_utf8($rows[0][0]), 'populate: the character slot is upgraded';
  ok !utf8::is_utf8($rows[0][1]), 'populate: the binary slot is not';
  is $rows[1][0], 'abc', 'populate: ASCII unchanged';
  ok !utf8::is_utf8($rows[1][1]), 'populate: second row, binary slot not upgraded';
  ok !utf8::is_utf8($data->[0][0]), 'populate: the caller\'s rows are not touched';
}

is(DBIO::Oracle::Storage->can('_bind_sth_params'), DBIO::Storage::DBI->can('_bind_sth_params'),
  'the storage overrides no bind method of core: the seam is _adjust_bind_values');

done_testing;
