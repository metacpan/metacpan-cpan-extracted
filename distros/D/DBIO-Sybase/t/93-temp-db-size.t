use strict;
use warnings;
use Test::More;

use DBIO::Sybase::Deploy;

# karr k69, part B: the temporary database is made as large as the schema to be
# deployed into it needs, not as large as the server's `default database size`
# (the size of model, 24 MB on the ASE 16.0 SP02 this was measured on, which
# DBIO::Test::Schema -- 36 tables, 733 pages of 16K -- does not fit into).
#
# CLAIMED:
#
#   1. The objects counted are the ones DBIO::Sybase::DDL writes: a table once
#      however many sources map to it, never a view, its primary key, its
#      unique indexes (column flag, unique constraint) and its declared
#      indexes -- the last two not again when they repeat a unique index.
#   2. The size is (2 * tables + other indexes) * 8 pages (a table and its key
#      take an extent of 8 pages each, so does every further index) plus the
#      pages model has in use plus a reserve, in the server's page size, up to
#      the next 4 MB, and never below the size of model.
#   3. CREATE DATABASE is sent with that size; with `temp_db_size` given it is
#      sent with the size given and the server is not asked what the
#      calculation would have needed: the attribute replaces the calculation,
#      it is not a minimum.
#   4. A server without the room (Msg 1810) is reported by what was asked for
#      and what to do, together with the server's own message.
#
# Fully offline: a real schema class whose sources are counted, a handle that
# answers the one question about model and logs what it is sent.

{
  package K69B::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
}
{
  package K69B::Schema::Result::Thing;
  use DBIO::Cake;

  table 'thing';
  col id    => integer;
  col a     => varchar(20);
  col b     => varchar(20);
  col code  => varchar(20), is_unique => 1;

  primary_key 'id';
  unique ab_uq => ['a', 'b'];

  idx code_idx => ['code'];          # the column flag has it
  idx pk_idx   => ['id'];            # the primary key has it
  idx ab_idx   => ['a', 'b'];        # the constraint has it
  idx ab_uq    => ['a', 'b'];        # the constraint, by its name
  idx ba_idx   => ['b', 'a'];        # another order: an index of its own
  idx a_idx    => ['a'];             # an index of its own
}
{
  # no primary key
  package K69B::Schema::Result::Heap;
  use DBIO::Cake;

  table 'heap';
  col n => integer;
}
{
  # a second source of the table thing: one table
  package K69B::Schema::Result::ThingAgain;
  use base 'DBIO::Core';
  __PACKAGE__->table('thing');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
  __PACKAGE__->set_primary_key('id');
}
{
  package K69B::Schema::Result::ThingView;
  use base 'DBIO::Core';
  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->table('thing_view');
  __PACKAGE__->result_source_instance->view_definition('SELECT id FROM thing');
  __PACKAGE__->add_columns(id => { data_type => 'integer' });
}
K69B::Schema->register_class($_ => "K69B::Schema::Result::$_")
  for qw(Thing Heap ThingAgain ThingView);

# --- 1. what is counted ------------------------------------------------------
{
  my ($tables, $indexes) = DBIO::Sybase::Deploy->_temp_db_objects('K69B::Schema');
  is $tables, 2, 'counted: thing (two sources, one table) and heap; the view is not a table';
  is $indexes, 4,
    'counted: besides the keys, code (column flag), ab_uq (constraint), ba_idx and a_idx -- '
  . 'not the declarations that repeat a unique index';
}

# --- 2. the calculation ------------------------------------------------------
# 16K pages, a model of 1536 pages of which 850 are in use (the measured server).
{
  my $size = sub { DBIO::Sybase::Deploy->_temp_db_megabytes(@_) };

  # (2 * 36 + 15) * 8 = 696 pages; + 25% + 64 = 934; + 850 of model = 1784
  # pages of 16K = 27.9 MB, up to 28.
  is $size->(36, 15, 16384, 1536, 850), 28,
    'DBIO::Test::Schema on the measured server: 28 MB, which it was measured to fit into (208 pages left)';

  # the size of model is the least a database can be
  is $size->(1, 0, 16384, 1536, 850), 24, 'a tiny schema: not below the size of model';

  # always a multiple of 4
  is $size->($_, 3, 16384, 1536, 850) % 4, 0, "$_ tables: a multiple of 4 MB" for 1, 50, 77, 120;

  # a bigger schema is a bigger database, and grows with the schema
  my @sizes = map { $size->($_, $_, 16384, 1536, 850) } 40, 80, 160;
  ok $sizes[0] < $sizes[1] && $sizes[1] < $sizes[2], 'the more tables, the larger: ' . join(', ', @sizes);

  # the page size of the server goes in: the same pages are less bytes on 2K pages
  my $small = $size->(100, 20, 2048, 12288, 6800);
  my $large = $size->(100, 20, 16384, 1536, 850);
  ok $small < $large, "2K pages ($small MB) need less than 16K pages ($large MB) for the same schema";
}

# --- 3. what is sent ---------------------------------------------------------
{
  package K69B::Dbh;
  sub new { bless { AutoCommit => 1, db => 'testdb', log => [], asked => 0, %{ $_[1] // {} } }, $_[0] }
  sub selectrow_array {
    my ($self, $sql) = @_;
    return $self->{db} if $sql =~ /db_name\(\)\s*$/i;
    return 1 if $sql =~ /status2/;
    if ($sql =~ /\@\@maxpagesize/ and $sql =~ /\bmodel\b/) {
      $self->{asked}++;
      return @{ $self->{model} // [ 16384, 1536, 850 ] };
    }
    die "unexpected query: $sql";
  }
  sub do {
    my ($self, $sql) = @_;
    push @{ $self->{log} }, $sql;
    $self->{err} = undef;
    $self->{db} = $1 if $sql =~ /^USE\s+(\S+)$/i;
    if ($sql =~ /^CREATE DATABASE/ and $self->{no_room}) {
      $self->{err} = 1810;
      die "DBD::Sybase::db do failed: Server message number=1810 severity=17 state=1 line=1 "
        . "server=MYSYBASE text=CREATE DATABASE failed. Could not allocate enough space.\n";
    }
    1;
  }
  sub err { $_[0]{err} }
}

sub deploy { DBIO::Sybase::Deploy->new(schema => 'K69B::Big', @_) }
sub create_sql { my ($d) = grep { /^CREATE DATABASE/ } @{ $_[0]{log} }; $d }

{
  package K69B::Big;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
}
for my $n (1 .. 36) {
  my $class = sprintf 'K69B::Big::Result::T%02d', $n;
  { no strict 'refs'; @{"${class}::ISA"} = ('DBIO::Core') }
  $class->table(sprintf 'big%02d', $n);
  $class->add_columns(id => { data_type => 'integer' }, v => { data_type => 'integer', is_nullable => 1 });
  $class->set_primary_key('id');
  $class->add_unique_constraint(sprintf('big%02d_v', $n) => ['v']) if $n <= 15;
  K69B::Big->register_class(sprintf('T%02d', $n) => $class);
}

{
  my $dbh  = K69B::Dbh->new;
  my $name = deploy()->_create_temp_db($dbh);
  # (2 * 36 + 15) * 8 = 696 pages ... 28 MB, as in 2.
  is create_sql($dbh), "CREATE DATABASE $name ON default = '28M'",
    'the size is calculated from the schema and sent with CREATE DATABASE';
  is $dbh->{asked}, 1, '... after asking the server about model once';
}

{
  my $dbh  = K69B::Dbh->new({ model => [ 2048, 12288, 6800 ] });
  my $name = deploy()->_create_temp_db($dbh);
  like create_sql($dbh), qr/^CREATE DATABASE \Q$name\E ON default = '\d+M'$/,
    'the page size of the server is the one it answered';
  my ($mb) = create_sql($dbh) =~ /'(\d+)M'/;
  ok $mb < 28, "... 2K pages: $mb MB for the same schema, less than on 16K pages";
}

for my $given (['64M', '64M'], ['96m', '96M'], [48, '48M'], ['1G', '1G']) {
  my ($in, $out) = @$given;
  my $dbh  = K69B::Dbh->new;
  my $name = deploy(temp_db_size => $in)->_create_temp_db($dbh);
  is create_sql($dbh), "CREATE DATABASE $name ON default = '$out'",
    "temp_db_size => $in: that size, and not the calculated one";
  is $dbh->{asked}, 0, '... without asking the server about model';
}

{
  # the attribute replaces the calculation even where it is less than it
  my $dbh  = K69B::Dbh->new;
  my $name = deploy(temp_db_size => '4M')->_create_temp_db($dbh);
  is create_sql($dbh), "CREATE DATABASE $name ON default = '4M'",
    'temp_db_size is not a minimum: a size below the calculated one is sent as it is';
  is deploy(temp_db_size => '8M')->temp_db_size, '8M', 'temp_db_size is an accessor';
  is deploy()->temp_db_size, undef, '... undef where none is given';
}

for my $bad ('big', '12 M', '-4M', '4MB', '', '28M; DROP DATABASE master') {
  my $dbh = K69B::Dbh->new;
  my $ok  = eval { deploy(temp_db_size => $bad)->_create_temp_db($dbh); 1 };
  ok !$ok, "temp_db_size => '$bad' is refused ...";
  is scalar(grep { /^CREATE DATABASE/ } @{ $dbh->{log} }), 0, '... before anything is sent';
}

# --- 4. no room --------------------------------------------------------------
{
  my $dbh = K69B::Dbh->new({ no_room => 1 });
  my $ok  = eval { deploy()->_create_temp_db($dbh); 1 };
  my $err = "$@";
  ok !$ok, 'no room for the database: it dies';
  like $err, qr/\b28M\b/, '... naming the size that was asked for';
  like $err, qr/temp_db_size/, '... and the attribute that sets another';
  like $err, qr/number=1810\b/, '... with the server\'s own message';
  is $dbh->{db}, 'testdb', '... the handle is back in its database';
}

done_testing;
