# ABSTRACT: A sync storage with a broker attached holds no copy of the broker's answer
use strict;
use warnings;

use Test::More;
use Scalar::Util qw(blessed reftype refaddr);

use DBI;
use DBIO::Storage::DBI;
use DBIO::AccessBroker;

# OFFLINE (karr k266, the sync twin of k252). The async side keeps no copy of
# the AccessBroker's answer: every connection asks the broker again. The sync
# DBI storage kept it -- DSN, user, PASSWORD -- in _dbi_connect_info, from
# connect_info on and again after every connection. A copy of an answer the
# broker may have rotated away is only ever stale, and holding the password
# is a risk for nothing.
#
# What this file claims, with a broker attached:
#   1. After connect_info and after every connection nothing in the storage
#      holds a value of the answer: the stored connect info stays empty.
#   2. Every connection still asks the broker and is opened with the answer
#      of that moment.
#   3. _dbi_connect_info, the read side other code asks for the DSN (driver
#      detection) and the DBI attributes, is the broker's current answer,
#      derived at the moment it is read and not kept.
#   4. A storage without a broker keeps its connect info as before.
#
# THE SUBSTITUTIONS: DBI->connect is replaced by a recorder returning a
# stand-in handle; no database is involved.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

{
  package T::CountBroker;
  use base 'DBIO::AccessBroker';
  sub new { bless { calls => 0 }, shift }
  sub connect_info_for {
    my $n = ++$_[0]{calls};
    return [ "dbi:Fake:k266-dsn-$n", "k266-user-$n", "k266-secret-$n", {} ];
  }
}

{
  package T::Handle;
  sub new   { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]->{ $_[1] } }
}

our @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { shift; push @CONNECTS, [ @_ ]; T::Handle->new };
}

my $ANSWER = qr/k266-(?:dsn|user|secret)/;

sub holds {
  my ($x, $re, $seen) = @_;
  $seen ||= {};
  return 0 unless defined $x;
  return $x =~ $re ? 1 : 0 unless ref $x;
  return 0 if blessed($x) && $x->isa('DBIO::AccessBroker');
  return 0 if $seen->{ refaddr $x }++;
  my $type = reftype $x;
  my @inside = $type eq 'HASH'                      ? %$x
             : $type eq 'ARRAY'                     ? @$x
             : $type eq 'SCALAR' || $type eq 'REF'  ? $$x
             :                                        ();
  return scalar grep { holds($_, $re, $seen) } @inside;
}

ok holds({ deep => [ 'k266-secret-9' ] }, $ANSWER), 'the scanner finds a value of an answer';

my $broker  = T::CountBroker->new;
my $storage = DBIO::Storage::DBI->new(undef);
$storage->connect_info([ $broker ]);

ok !holds($storage, $ANSWER), '1. after connect_info nothing in the storage holds a value of the answer';
is $storage->{_dbi_connect_info}, undef, '... the stored connect info is empty';

local @CONNECTS;
$storage->_connect;
$storage->_connect;
ok !holds($storage, $ANSWER), '... and after connections as well';
is $storage->{_dbi_connect_info}, undef, '... the stored connect info is still empty';

is scalar @CONNECTS, 2, '2. every connection is opened';
isnt $CONNECTS[0][0], $CONNECTS[1][0], '... each with the answer of its moment';
like $CONNECTS[1][2], qr/^k266-secret-\d+$/, '... password included';

my $dsn = $storage->_dbi_connect_info->[0];
like $dsn, qr/^dbi:Fake:k266-dsn-\d+$/, '3. _dbi_connect_info gives the DSN of the broker';
my $dsn2 = $storage->_dbi_connect_info->[0];
isnt $dsn2, $dsn, '... of the answer of the moment, not a kept one';
ok !holds($storage, $ANSWER), '... and reading it keeps nothing';
is ref $storage->_dbi_connect_info->[3], 'HASH', '... with the DBI attributes';

my $static = DBIO::Storage::DBI->new(undef);
$static->connect_info([ 'dbi:Fake:static', 'u', 'p' ]);
is_deeply [ @{ $static->_dbi_connect_info }[0 .. 2] ], [ 'dbi:Fake:static', 'u', 'p' ],
  '4. a storage without a broker keeps its connect info';

done_testing;
