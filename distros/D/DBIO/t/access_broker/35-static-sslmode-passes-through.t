# ABSTRACT: sslmode in a static connect info, without a broker, reaches DBI->connect as an attribute
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Storage::DBI;
use DBIO::AccessBroker;

# OFFLINE (karr k306; maintainer's decision 2026-10-09, point (a)).
#
# WHY: a static connect info has no broker to judge it. A client parameter in
# it -- sslmode -- is handed unchanged to DBI->connect as a DBI attribute; the
# DBD reads it or not, as it knows the name. That is the documented behaviour
# (Storage::DBI connect_info), and this file pins it: the NAME sslmode is let
# through on purpose. A later check that rejects unknown attributes (karr
# k327) must keep sslmode passing here, or change this test knowingly.
#
# The behaviour was there before this ticket, so there is no red-before-fix
# state: the test pins what stays, and the last block pins the stricter rule
# that stays for a broker (karr k298, k307).
#
#   1. { dsn => ..., sslmode => ... } : in _dbio_connect_attributes and in the
#      attribute hash of DBI->connect.
#   2. [ $dsn, $user, $pass, { sslmode => ... } ]: the same.
#   3. A broker answering a hash with sslmode still throws.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

{
  package T::Driver::Storage;
  use base 'DBIO::Storage::DBI';
  DBIO::Storage::DBI->register_driver(ExampleP => __PACKAGE__);
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

{
  package T::HashBroker;
  use base 'DBIO::AccessBroker';
  sub connect_info_for {
    return { dsn => 'dbi:ExampleP:dbname=k306-db', user => 'u', password => 'p', sslmode => 'require' };
  }
}

my $DSN = 'dbi:ExampleP:dbname=k306-db';

my %FORM = (
  'a hash with a dsn' => [ { dsn => $DSN, user => 'u', password => 'p', sslmode => 'require' } ],
  'the DBI form'      => [ $DSN, 'u', 'p', { sslmode => 'require' } ],
);

for my $class ('DBIO::Storage::DBI', 'T::Driver::Storage') {
  for my $label (sort keys %FORM) {
    my $t = "$class, $label";
    my $storage = $class->new(undef);
    local @CONNECTS;

    lives_ok { $storage->connect_info([ @{ $FORM{$label} } ]) } "$t: connect_info takes it";
    is $storage->_dbio_connect_attributes->{sslmode}, 'require',
      "$t: sslmode is in the connect attributes";

    lives_ok { $storage->_connect } "$t: connecting does not refuse it";
    is scalar @CONNECTS, 1, "$t: DBI->connect is called";
    is $CONNECTS[0][0], $DSN, "$t: with the DSN";
    is $CONNECTS[0][3]{sslmode}, 'require', "$t: and sslmode among the attributes, unchanged";
  }
}

{
  my $storage = T::Driver::Storage->new(undef);
  local @CONNECTS;
  lives_ok { $storage->connect_info([ T::HashBroker->new ]) }
    'a broker answering a hash with sslmode: connect_info configures the storage';
  throws_ok { $storage->_connect } qr/sslmode/,
    'the same sslmode in a broker hash answer still throws when connecting';
  is scalar @CONNECTS, 0, 'and DBI->connect is not called';
}

done_testing;
