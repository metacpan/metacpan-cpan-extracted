use strict;
use warnings;
use Test::More;

# Offline regression for karr #20: after #16 re-activated the ASE BCP
# _insert_bulk override, bulk/populate over a FreeTDS-backed DBD::Sybase died
# (server msg 226 "BULK INSERT not allowed within multi-statement transaction"
# and msg 1622 "Type '7' not implemented" -- the latter is a FreeTDS blk-library
# limitation that cannot be worked around from Perl).
#
# Fix: under FreeTDS, DBIO::Sybase::Storage::ASE::_init does NOT create a
# _bulk_storage. The _insert_bulk eligibility check is
#   $self->_bulk_storage && $self->_get_dbh->{syb_has_blk}
# so a missing _bulk_storage makes _insert_bulk fall back to the regular
# (core) array-insert path -- restoring the pre-#16 behaviour for FreeTDS while
# keeping BCP active for real Sybase OpenClient.
#
# The decision is driven purely by ->_using_freetds, so it is checkable without
# a live server: stub that flag plus the live-DB connection primitives that
# _init touches, run _init, and assert on whether _bulk_storage was built.

use_ok 'DBIO::Sybase::Storage::ASE';

# Run _init against an in-memory object, neutralising only the parts of _init
# that genuinely require a server (the base ::DBI::_init, the FreeTDS version
# probe, and the DSN-rewriting reconnect in _set_max_connect). _using_freetds is
# the actual decision input under test, so we drive it explicitly.
sub init_with_freetds {
  my ($freetds) = @_;

  my $obj = DBIO::Sybase::Storage::ASE->new;
  $obj->_dbi_connect_info([ 'dbi:Sybase:host=nohost' ]);

  no warnings 'redefine';
  local *DBIO::Sybase::Storage::ASE::_using_freetds         = sub { $freetds };
  local *DBIO::Sybase::Storage::ASE::_using_freetds_version = sub { $freetds ? 0 : undef };
  local *DBIO::Sybase::Storage::ASE::_set_max_connect       = sub { };
  local *DBIO::Storage::DBI::_init                          = sub { };

  $obj->_init;

  return $obj;
}

# FreeTDS: BCP is disabled -> no bulk storage -> _insert_bulk falls back.
{
  my $obj = init_with_freetds(1);

  ok !defined($obj->_bulk_storage),
    'FreeTDS: _init does not create a _bulk_storage (BCP disabled)';

  ok defined($obj->_writer_storage),
    'FreeTDS: _writer_storage is still created (regular insert path intact)';
}

# OpenClient (non-FreeTDS): BCP stays active -> bulk storage is created.
{
  my $obj = init_with_freetds(0);

  ok defined($obj->_bulk_storage),
    'OpenClient: _init creates a _bulk_storage (BCP remains active)';
}

done_testing;
