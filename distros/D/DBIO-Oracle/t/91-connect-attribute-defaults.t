use strict;
use warnings;
use Test::More;

use DBIO::Oracle::Storage ();

# karr k63. The connection attributes this driver sets when the connect_info
# names none.
#
# CLAIM: a CLOB or BLOB read longer than DBD::Oracle's LongReadLen of 80 died
# at the fetch, and a string with a character outside the client character set
# (NLS_LANG) came back as U+FFFD, a silent corruption. After: LongReadLen is
# 16 MiB and the character sets are AL32UTF8 unless the connect_info says
# otherwise; LongTruncOk stays off (a truncated value is loud); a value the
# application names always wins.

my $storage = DBIO::Oracle::Storage->new(undef);

my $defaults = $storage->_default_dbi_connect_attributes;
is $defaults->{LongReadLen}, 16 * 1024 * 1024, 'LongReadLen defaults to 16 MiB';
ok !$defaults->{LongTruncOk}, 'LongTruncOk stays off: a truncation is loud';
is $defaults->{ora_charset},  'AL32UTF8', 'ora_charset defaults to AL32UTF8';
is $defaults->{ora_ncharset}, 'AL32UTF8', 'ora_ncharset defaults to AL32UTF8';
is $defaults->{RaiseError}, 1, 'the base defaults are kept';

sub args_for {
  my @info = @_;
  my $s = DBIO::Oracle::Storage->new(undef);
  $s->connect_info(\@info);
  return $s->_dbi_connect_info->[3];
}

my $plain = args_for('dbi:Oracle:x', 'u', 'p');
is $plain->{LongReadLen}, 16 * 1024 * 1024, 'a connect_info without it gets the LongReadLen default';
is $plain->{ora_charset}, 'AL32UTF8', '... and the character set';

my $own = args_for('dbi:Oracle:x', 'u', 'p',
  { LongReadLen => 100, ora_charset => 'WE8ISO8859P1', ora_ncharset => 'AL16UTF16' });
is $own->{LongReadLen}, 100, 'a LongReadLen the connect_info names wins';
is $own->{ora_charset}, 'WE8ISO8859P1', 'an ora_charset it names wins';
is $own->{ora_ncharset}, 'AL16UTF16', 'an ora_ncharset it names wins';
ok !$own->{LongTruncOk}, 'LongTruncOk is still off';

# --- live: the defaults reach the server, no NLS_LANG, no LongReadLen given ---

my @live = @ENV{qw(DBIO_TEST_ORA_DSN DBIO_TEST_ORA_USER DBIO_TEST_ORA_PASS)};
SKIP: {
  skip 'Set $ENV{DBIO_TEST_ORA_DSN}, _USER and _PASS (and have DBD::Oracle) for the live half', 4
    unless length($live[0] // '') and eval { require DBD::Oracle; 1 };

  {
    package T91::Live;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('Oracle');
  }
  my $schema = T91::Live->connect(@live);
  my $dbh = $schema->storage->dbh;

  is $dbh->{LongReadLen}, 16 * 1024 * 1024, 'the live handle has the LongReadLen default';

  my $text = "Gr\x{fc}\x{df}e \x{20ac} \x{65e5}\x{672c}\x{8a9e}";
  my ($back) = $dbh->selectrow_array('SELECT TO_CHAR(?) FROM dual', undef, $text);
  is $back, $text, 'a string with wide characters round-trips with no NLS_LANG set';

  my $sql = 'SELECT ' . join(' || ', (q{TO_CLOB(RPAD('a', 4000, 'a'))}) x 25) . ' FROM dual';
  my ($clob) = $dbh->selectrow_array($sql);
  is length($clob), 100_000, 'a CLOB of 100000 characters is read in full, not cut at 80 or dead at the fetch';
  is $clob, 'a' x 100_000, '... and is the value';
}

done_testing;
