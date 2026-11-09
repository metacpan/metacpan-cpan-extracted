# ABSTRACT: a static connect info refuses an attribute that is neither a DBIO option nor a DBI attribute by name
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Storage::DBI;

# OFFLINE (karr k327; maintainer's decision 2026-10-09, point (b)).
#
# WHY: connect($dsn, $u, $p, { limit_dialect => 'Top' }) used to land silently
# in _dbio_connect_attributes and do nothing -- dbio-mssql ran tests for years
# that exercised a dialect switch which never existed. A static connect info is
# fully known at connect_info, so a key that no one reads is refused there,
# naming the key (never the value). What passes: DBIO options, and DBI
# attributes by name (uppercase first letter, private_, dbi_, dbd_, the DBD's
# prefix from the DSN), and sslmode (karr k306, pinned by
# 35-static-sslmode-passes-through.t). The DBD is the one the DSN given names:
# $ENV{DBI_DSN} lends no prefix, since connect info without a DSN is refused
# before any attribute is judged (karr k306,
# 37-static-without-dsn-refused.t). A dbh_maker has no attributes applied and
# no DSN: nothing is checked there.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

my $DSN = 'dbi:ExampleP:dbname=k327';

sub info {
  my ($form, %attrs) = @_;
  return $form eq 'hash' ? [ { dsn => $DSN, user => 'u', password => 'p', %attrs } ]
       : $form eq 'dbi'  ? [ $DSN, 'u', 'p', { %attrs } ]
       :                   [ $DSN, 'u', 'p', {}, { %attrs } ];
}

for my $form (qw( hash dbi extra )) {
  my $storage = DBIO::Storage::DBI->new(undef);
  throws_ok { $storage->connect_info(info($form, limit_dialect => 'Top-secret-value')) }
    qr/Unknown connect attribute\(s\) 'limit_dialect'/, "$form form: limit_dialect refused";
  unlike $@, qr/Top-secret-value/, "$form form: the value is not in the message";

  throws_ok { $storage->connect_info(info($form, zzz_a => 1, zzz_b => 2)) }
    qr/'zzz_a', 'zzz_b'/, "$form form: all unknown keys are named";

  lives_ok {
    $storage->connect_info(info($form,
      sslmode => 'require', AutoCommit => 1, private_x => 1, dbi_y => 1, dbd_z => 1,
      quote_char => '"', on_connect_do => ['SELECT 1'], async => 'immediate',
      ignore_version => 1, limit_dialect => undef, empty => '',
    ));
  } "$form form: sslmode, DBI attributes, DBIO options, undef/empty values pass";
}

{
  my $storage = DBIO::Storage::DBI->new(undef);
  throws_ok { $storage->connect_info([ 'dbi:Pg:dbname=x', 'u', 'p', { pg_enable_utf8 => 1, mysql_x => 1 } ]) }
    qr/'mysql_x'/, "another DBD's prefix is refused";
  lives_ok { $storage->connect_info([ 'dbi:Pg:dbname=x', 'u', 'p', { pg_enable_utf8 => 1 } ]) }
    "the DSN's own DBD prefix passes";

  throws_ok { $storage->connect_info([ 'dbi:Nonexistent:x', 'u', 'p', { foo_bar => 1 } ]) }
    qr/'foo_bar'/, 'an unknown DBD gives no prefix';
}

{
  local $ENV{DBI_DSN} = 'dbi:Pg:dbname=x';
  my $storage = DBIO::Storage::DBI->new(undef);
  throws_ok { $storage->connect_info([ undef, 'u', 'p', { pg_enable_utf8 => 1 } ]) }
    qr/Connect info without a DSN/,
    'no DSN given: refused for that, $ENV{DBI_DSN} does not stand in for it';
}

{
  my $storage = DBIO::Storage::DBI->new(undef);
  lives_ok { $storage->connect_info([ sub { }, { limit_dialect => 'Top', quote_char => '"' } ]) }
    'coderef form: no DSN to judge by, not checked';
  lives_ok { $storage->connect_info([ { dbh_maker => sub { }, limit_dialect => 'Top' } ]) }
    'dbh_maker hash form: not checked';
}

done_testing;
