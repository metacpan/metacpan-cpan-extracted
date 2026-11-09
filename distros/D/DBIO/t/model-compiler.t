use strict; use warnings;
use Test::More;
use DBIO::Schema::ModelCompiler ();

# A fake adapter: deterministic base -> native, no real DB.
{
  package Fake::Adapter;
  use base 'DBIO::Adapter::Base';
  my %N = (
    integer => 'BIGINT', text => 'CLOB', boolean => 'BOOL',
    double  => 'DBL', blob => 'BIN', timestamp => 'TS',
  );
  # Like an engine whose timestamp takes a fractional-seconds precision: the
  # size of a timestamp goes into the native type when the column carries one.
  sub to_native {
    my ($self, $col) = @_;
    my $b = $col->{base_type};
    return "CHAR($col->{size})"                 if $b eq 'char';
    return "NUM($col->{precision},$col->{scale})" if $b eq 'numeric';
    return "TS($col->{size})" if $b eq 'timestamp' && defined $col->{size};
    return $N{$b};
  }
}

# A minimal schema defined in base types.
{
  package T::Result::User;
  use base 'DBIO::Core';
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    id     => { data_type => 'integer', is_auto_increment => 1 },
    name   => { data_type => 'char', size => 64 },
    bio    => { data_type => 'text', is_nullable => 1 },
    status => { data_type => 'char', size => 8, default_value => 'new' },
    seen    => { data_type => 'timestamp',   size => 3 },
    synced  => { data_type => 'timestamptz', size => 0 },
    created => { data_type => 'datetime' },
  );
  __PACKAGE__->set_primary_key('id');

  package T::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(User => 'T::Result::User');
}

T::Schema->storage_type('+DBIO::Test::Storage');
my $schema = T::Schema->connect(sub { die "compile() must not connect" });
my $model  = DBIO::Schema::ModelCompiler
  ->new(adapter => Fake::Adapter->new)
  ->compile($schema);

my $t = $model->{tables}{users};
ok $t, 'users table present';
is_deeply( $t->{primary_key}, ['id'], 'primary key' );

my %col = map { $_->{column_name} => $_ } @{ $t->{columns} };
is( $col{id}{native_type},    'BIGINT',   'integer -> BIGINT via adapter' );
is( $col{id}{is_pk},          1,          'id is pk' );
is( $col{id}{auto_increment}, 1,          'id auto_increment' );
is( $col{name}{native_type},  'CHAR(64)', 'char(64) -> CHAR(64)' );
is( $col{name}{not_null},     1,          'name not null' );
is( $col{bio}{native_type},   'CLOB',     'text -> CLOB' );
is( $col{bio}{not_null},      0,          'bio nullable' );
is( $col{status}{default},   'new',      'default value carried through' );
is( $col{id}{not_null},       1,          'pk column not null' );

# The compiled type of a timestamp is the type the same column is deployed
# as: an adapter that writes the precision gets it. Without it the compiled
# model says TS where the table says TS(3), and a diff between the two
# proposes to alter a column nobody changed.
is( $col{seen}{native_type},    'TS(3)', 'timestamp size 3 -> TS(3): the precision reaches the adapter' );
is( $col{synced}{native_type},  'TS(0)', 'timestamptz size 0 -> TS(0): 0 is a precision' );
is( $col{created}{native_type}, 'TS',    'datetime without size -> TS' );

done_testing;
