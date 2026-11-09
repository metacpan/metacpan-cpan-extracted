use strict;
use warnings;
use utf8;

use Test::More;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Schema;

# LIVE, DBD::ODBC only (karr k81, the reading half of karr k58). A character
# string written through a schema that declares MSSQL must come back as the
# same characters -- with the UTF-8 flag on -- and not as the bytes of its
# UTF-8 form (length of an a-umlaut 2, the flag off), which is a silently
# wrong value for every caller that compares or prints it.
#
# DBD::ODBC built without Unicode support (odbc_has_unicode 0) hands a
# SQL_CHAR value back as bytes unless odbc_utf8_on is set. The storage sets it
# once it has asked the connection that its client character set is UTF-8 (the
# question the write path asks), when the connect info does not say. An
# explicit odbc_utf8_on in the connect info stays what the caller chose.
# $ENV{DBIO_TEST_MSSQL_ODBC_DSN}, _USER and _PASS. Offline: t/124.

my ($DSN, $USER, $PASS) = @ENV{ map { "DBIO_TEST_MSSQL_ODBC_$_" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_ODBC_DSN}, _USER and _PASS to run this test'
  unless $DSN and defined $USER and defined $PASS;

plan skip_all => 'DBD::ODBC test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_mssql_odbc')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_mssql_odbc');

binmode $_, ':encoding(UTF-8)' for map { Test::More->builder->$_ } qw(output failure_output todo_output);

{
  package T::K81R::Result::Uni;
  use base 'DBIO::Core';
  __PACKAGE__->table('k81_read_uni');
  __PACKAGE__->add_columns(
    id  => { data_type => 'integer', is_auto_increment => 1 },
    tag => { data_type => 'varchar', size => 40, is_nullable => 1 },
    v   => { data_type => 'varchar(100)', is_nullable => 1 },
    nv  => { data_type => 'nvarchar', size => 100, is_nullable => 1 },
    nvm => { data_type => 'nvarchar', size => -1, is_nullable => 1 },
    nt  => { data_type => 'ntext', is_nullable => 1 },
    b   => { data_type => 'varbinary', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package T::K81R::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
  __PACKAGE__->register_class(Uni => 'T::K81R::Result::Uni');
}

my $admin = DBI->connect($DSN, $USER, $PASS, { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
$admin->do("IF OBJECT_ID('k81_read_uni', 'U') IS NOT NULL DROP TABLE k81_read_uni");
$admin->do('CREATE TABLE k81_read_uni (id INT IDENTITY PRIMARY KEY, tag VARCHAR(40) NULL,'
  . ' v VARCHAR(100) NULL, nv NVARCHAR(100) NULL, nvm NVARCHAR(MAX) NULL,'
  . ' nt NTEXT NULL, b VARBINARY(100) NULL)');
END { eval { $admin->do("IF OBJECT_ID('k81_read_uni', 'U') IS NOT NULL DROP TABLE k81_read_uni") } if $admin }

my %VALUE = (
  umlaut => "\x{e4}\x{f6}\x{fc}\x{df}",
  euro   => "\x{20ac}",
  cjk    => "\x{4e2d}\x{6587}\x{65e5}\x{672c}\x{8a9e}",
  emoji  => "\x{1F600}\x{1F4A9}",
  mix    => "a\x{e4}\x{4e2d}\x{1F600}z",
);

local $SIG{__WARN__} = sub { warn $_[0] unless $_[0] =~ /compiled against buggy FreeTDS version/ };

my $schema = T::K81R::Schema->connect($DSN, $USER, $PASS);
$schema->storage->ensure_connected;
my $rs = $schema->resultset('Uni');

plan skip_all => 'DBD::ODBC is built with Unicode support: it decodes by itself'
  if $schema->storage->dbh->{odbc_has_unicode};

sub is_chars {
  my ($got, $want, $name) = @_;
  ok defined $got && utf8::is_utf8($got) && $got eq $want, $name
    or diag sprintf 'got %d characters (%s, flag %s), wanted %d',
      length($got // ''), join(' ', map { sprintf '%x', ord } split //, ($got // '')),
      utf8::is_utf8($got // '') ? 'on' : 'off', length $want;
}

for my $column (qw(nv nvm nt)) {
  for my $name (sort keys %VALUE) {
    my $value = $VALUE{$name};
    $rs->create({ tag => "$column-$name", $column => $value });
    my $row = $rs->search({ tag => "$column-$name" })->single;
    is_chars $row->get_column($column), $value, "$column/$name: a lookup by tag returns the characters";
  }
}

# VARCHAR: what the code page of the database has
for my $name (qw(umlaut euro)) {
  $rs->create({ tag => "v-$name", v => $VALUE{$name} });
  is_chars $rs->search({ tag => "v-$name" })->single->get_column('v'), $VALUE{$name},
    "varchar/$name: the characters of the code page come back as characters";
}

# the other ways to read
{
  my $value = $VALUE{mix};
  $rs->create({ tag => 'ways', nv => $value });
  my ($first) = $rs->search({ tag => 'ways' })->all;
  is_chars $first->get_column('nv'), $value, 'all';
  is_chars $rs->search({ tag => 'ways' })->next->get_column('nv'), $value, 'next';
  is_chars $rs->search({ tag => 'ways' })->get_column('nv')->first, $value, 'get_column->first';
  my ($hri) = $rs->search({ tag => 'ways' }, { result_class => 'DBIO::ResultClass::HashRefInflator' })->all;
  is_chars $hri->{nv}, $value, 'HashRefInflator';
  is_chars $rs->search({ nv => $value })->first->get_column('nv'), $value,
    'a condition on the value finds the row, which reads back as characters';
}

# tags are ASCII and stay ASCII
is $rs->search({ tag => 'ways' })->single->get_column('tag'), 'ways', 'an ASCII value is unchanged';

# a binary value is bytes, with the flag off, whatever odbc_utf8_on says
{
  my $bytes = join '', map { chr } 0xC3, 0xBC, 0x00, 0xFF, 0x80;
  $rs->create({ tag => 'bin', b => $bytes });
  my $got = $rs->search({ tag => 'bin' })->single->get_column('b');
  ok !utf8::is_utf8($got) && $got eq $bytes, 'a binary column comes back as the bytes it was written as';
}

# the caller's own choice wins
{
  my $own = T::K81R::Schema->connect($DSN, $USER, $PASS, { odbc_utf8_on => 0 });
  $own->storage->ensure_connected;
  ok !$own->storage->dbh->{odbc_utf8_on}, 'an explicit odbc_utf8_on => 0 in the connect info is kept';
  my $got = $own->resultset('Uni')->search({ tag => 'nv-umlaut' })->single->get_column('nv');
  ok !utf8::is_utf8($got) && length($got) == 8, '... and reads the bytes, as it asked for';
  $own->storage->disconnect;
}

ok $schema->storage->dbh->{odbc_utf8_on}, 'the storage set odbc_utf8_on (client character set is UTF-8)';

$schema->storage->disconnect;
done_testing;
