use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;
use DBIO::Test::Storage;

# karr #67 -- ADR 0030, second future_io refinement: the generic-base STOP
# boundary.
#
# See t/test/17_async_future_io_mro_walk.t for the rest of the MRO-walk RED
# suite; this case is split into its own file/process on purpose.
#
# The decided fix makes future_io walk mro::get_linear_isa(ref($self)) for a
# ::Async sibling, most-specific first -- but the walk must STOP strictly
# BEFORE the generic DBIO::Storage::DBI base itself (concretely: stop when
# $pkg eq 'DBIO::Storage::DBI', never probing 'DBIO::Storage::DBI::Async' or
# anything further up). A hypothetical generic add-on that claims future_io
# for every driver by planting a base-level ::Async is EXACTLY what karr #65
# already banned for the registry/explicit-registration path; this walk must
# not reopen that hole by convention.
#
# To exercise that boundary honestly this test PLANTS a package literally
# named DBIO::Storage::DBI::Async straight into the real DBIO::Storage::DBI
# namespace -- simulating such an add-on -- and proves a driver chain with no
# adapter of its own still croaks instead of silently adopting it. Perl
# package definitions are process-global and this one can't be undone, so it
# is kept in its own .t: prove forks a fresh perl per test file, which is the
# only way to guarantee this plant never coexists in the same process as
# 17's fake hierarchy (or any other test).
#
# This is a pure regression guard, not a RED case: it is already green today
# (today's single-candidate rule never goes near DBIO::Storage::DBI::Async
# either) and must STAY green after the fix lands -- it protects the stop
# boundary from ever being implemented as "stop AFTER trying
# DBIO::Storage::DBI" instead of "stop BEFORE".
#
# Mock only (DBIO::Test::Storage, no real DBD).

# The planted generic "base adapter": a legitimate-looking DBIO::Storage::Async
# sitting one rung ABOVE the required stop boundary.
{
  package DBIO::Storage::DBI::Async;
  use base 'DBIO::Storage::Async';
}

# A driver chain with NO adapter of its own or on any named ancestor -- only
# the planted generic one exists, past the stop boundary.
{
  package Karr67Guard::Storage;
  use base 'DBIO::Test::Storage';
  use mro 'c3';
}

my $schema  = DBIO::Test->init_schema;
my $storage = Karr67Guard::Storage->new($schema);
$storage->_async_mode('future_io');   # Test::Storage defaults to 'immediate'
delete $storage->{_async_storage_obj};
$storage->_connect_info([ { host => 'localhost' } ]);

my $async = eval { $storage->async };
my $err   = $@;

ok !defined($async) && $err,
  'GREEN today and after the fix: walk stops before the generic '
  . 'DBIO::Storage::DBI base -- must not adopt the planted '
  . 'DBIO::Storage::DBI::Async';
like $err, qr/does not support future_io/,
  'GREEN today and after the fix: standard future_io croak wording';
unlike $err, qr/\QDBIO::Storage::DBI::Async\E/,
  'GREEN today and after the fix: the planted generic base is never even '
  . 'named as a tried candidate -- the walk stops strictly BEFORE '
  . 'DBIO::Storage::DBI, not at/after it';

done_testing;
