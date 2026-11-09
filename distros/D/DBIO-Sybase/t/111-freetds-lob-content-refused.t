use strict;
use warnings;
use Test::More;

use DBIO::Sybase::Storage::ASE::LOBWriter;

# karr k97 (conformance Bind list). FreeTDS cannot write the content of a
# TEXT or IMAGE column: ct_data_info fails ("text pointer is not set or is
# undefined"), after the INSERT went out with its placeholder, so a row stood
# in the table without the value and the caller got an exception from the
# middle of the write. The writer refuses before it sends anything, naming
# table and column, when a LOB with content is to be written through FreeTDS.
# What needs no content written -- NULL, the empty string, literal SQL, a
# column that is no LOB -- and every value under a client library that can write
# it (not FreeTDS) is left alone.

{
  package K97::Source;
  sub new  { bless {}, shift }
  sub name { 'doc' }
}
{
  package K97::Storage;
  our @ISA = ('DBIO::Sybase::Storage::ASE::LOBWriter');
  sub new { bless { freetds => $_[1] }, $_[0] }
  sub _using_freetds { $_[0]{freetds} }
  sub _is_lob_column { $_[2] =~ /^(?:body|txt)\z/ }
}

my $src = K97::Source->new;

{
  my $storage = K97::Storage->new(1);
  my %fields  = (id => 1, body => 'abc', other => 'x');
  my $err = eval { $storage->_remove_blob_cols($src, \%fields); 1 } ? '' : "$@";
  isa_ok $@, 'DBIO::Exception' if $err;
  like $err, qr/table doc, column body: .*is refused: FreeTDS cannot write the content of a TEXT or IMAGE column/s,
    'LOB content through FreeTDS is refused, naming table and column';
  is_deeply \%fields, { id => 1, body => 'abc', other => 'x' },
    '... and the caller\'s values are untouched';

  my @data = ([ 1, 'abc' ], [ 2, undef ]);
  $err = eval { $storage->_remove_blob_cols_array($src, [qw(id txt)], \@data); 1 } ? '' : "$@";
  like $err, qr/table doc, column txt: .*is refused/s, 'the bulk form refuses as well';
  is_deeply \@data, [ [ 1, 'abc' ], [ 2, undef ] ], '... leaving the rows as they were';

  for my $value (undef, '', \'NULL') {
    my %f = (id => 1, body => $value);
    ok eval { $storage->_remove_blob_cols($src, \%f); 1 },
      'no content to write (' . (ref $value ? 'literal SQL' : defined $value ? "''" : 'undef') . '): not refused'
      or diag $@;
  }
  my %f = (id => 1, other => 'long text, but no LOB');
  ok eval { $storage->_remove_blob_cols($src, \%f); 1 }, 'a column that is no LOB: not refused';
}
{
  my $storage = K97::Storage->new(0);
  my %fields  = (id => 1, body => 'abc');
  my $blobs = eval { $storage->_remove_blob_cols($src, \%fields) };
  is_deeply $blobs, { body => 'abc' }, 'where the client library can write it, the content is handed on';
}

done_testing;
