use strict;
use warnings;
use Test::More;

use DBI ();
use DBIO::MySQL::Storage;

# OFFLINE half of karr k120 (t/167 has the live half), found by the shared Bind
# table (t/161, core ADR 0060): two ways a value reached the server changed.
#
# WHY IT MATTERS. (1) DBD::MariaDB treats every bound value as text unless told
# otherwise and encodes the bytes above 0x7F of a BLOB value as UTF-8: 256 bytes
# came back as 384. (2) DBD::mysql with mysql_enable_utf8mb4 sends a string
# held in Perl's 8-bit form ("\x{fc}") as the single byte 0xFC, which the server
# refuses as an incorrect string value (or stores cut when not strict); the same
# text with a character above 0xFF arrives whole. Claims:
#   a. binary types bind as SQL_BINARY, text and unknown types as nothing;
#   b. under DBD::mysql with the utf8 attribute a high 8-bit string is upgraded
#      to characters, a copy of it: the caller's value is not changed;
#   c. ... not a value bound as binary, not an ASCII one, not a reference, not
#      undef, not a string already flagged as characters;
#   d. a handle without the attribute, or another DBD, is left alone.

my $s = bless {}, 'DBIO::MySQL::Storage';

for my $t (qw(blob tinyblob mediumblob longblob binary varbinary bytea BLOB)) {
  is_deeply $s->bind_attribute_by_data_type($t), { TYPE => DBI::SQL_BINARY() }, "a: $t binds as binary";
}
is $s->bind_attribute_by_data_type($_), undef, "a: $_ binds as nothing" for qw(text varchar integer json);

{
  package FakeSth;
  sub new { bless { got => [] }, shift }
  sub bind_param { my ($self, $i, $v, $a) = @_; push @{ $self->{got} }, [ $i, $v, $a ]; 1 }
}

sub bound {
  my ($driver, $attrs, $bind, $bind_attrs) = @_;
  my $storage = bless { _dbh => { Driver => { Name => $driver }, %$attrs } }, 'DBIO::MySQL::Storage';
  my $sth = FakeSth->new;
  $storage->_bind_sth_params($sth, $bind, $bind_attrs);
  return $sth->{got};
}

my $latin = "\x{fc}";                    # not flagged: Perl's 8-bit form
ok !utf8::is_utf8($latin), 'the test value is the 8-bit form';
my $flagged = "\x{20ac}";
my $bytes = "\x{83}\x{a2}";
my @bind = map { [ {}, $_ ] } $latin, $flagged, 'ascii', undef, $bytes, [1];

my $got = bound(mysql => { mysql_enable_utf8mb4 => 1 }, \@bind, [ undef, undef, undef, undef, { TYPE => 1 }, undef ]);
ok utf8::is_utf8($got->[0][1]), 'b: the 8-bit string is upgraded to characters';
is $got->[0][1], $latin, '... and is the same text';
ok !utf8::is_utf8($latin), '... the caller\'s value is not changed';
ok !utf8::is_utf8($bind[0][1]), '... nor is its bind entry';
ok utf8::is_utf8($got->[1][1]) && $got->[1][1] eq $flagged, 'c: a string of characters stays';
is $got->[2][1], 'ascii', 'c: ASCII stays';
ok !defined $got->[3][1], 'c: undef stays';
ok !utf8::is_utf8($got->[4][1]), 'c: a value bound as binary stays bytes';
is $got->[5][1], $bind[5][1], 'c: a reference stays';

$got = bound(mysql => {}, \@bind, []);
ok !utf8::is_utf8($got->[0][1]), 'd: without the attribute the string is left alone';
$got = bound(MariaDB => { mariadb_auto_reconnect => 0 }, \@bind, []);
ok !utf8::is_utf8($got->[0][1]), 'd: DBD::MariaDB does it itself, nothing is done here';

done_testing;
