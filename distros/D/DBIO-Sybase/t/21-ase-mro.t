use strict;
use warnings;
use Test::More;

use mro ();
use B ();

# Offline regression for karr #16: the ASE trait classes
# (IdentityRetrieval, BulkInsert, TxnManager, LOBWriter) override methods that
# also live in the deep DBIO::Storage::DBI hierarchy reached via
# DBIO::Sybase::Storage. If they are linearised AFTER core in the C3 MRO their
# overrides are silently shadowed and never run -- which made last_insert_id
# return 0 over FreeTDS (identical PK collisions across rows on live ASE).
#
# This is a pure compile-time property of the @ISA ordering in
# DBIO::Sybase::Storage::ASE, so it is checkable without a live server: a
# resolved method must dispatch to the ASE trait, not to DBIO::Storage::DBI.

use_ok 'DBIO::Sybase::Storage::ASE';

# Resolve which package a method name actually dispatches to for the ASE class.
sub resolved_pkg {
  my ($class, $method) = @_;
  my $cv = $class->can($method) or return undef;
  return B::svref_2object($cv)->GV->STASH->NAME;
}

my %expected = (
  # method            => trait class that MUST win over DBIO::Storage::DBI
  last_insert_id      => 'DBIO::Sybase::Storage::ASE::IdentityRetrieval',
  _execute            => 'DBIO::Sybase::Storage::ASE::IdentityRetrieval',
  _insert_bulk        => 'DBIO::Sybase::Storage::ASE::BulkInsert',
  _exec_txn_begin     => 'DBIO::Sybase::Storage::ASE::TxnManager',
);

for my $method (sort keys %expected) {
  my $got = resolved_pkg('DBIO::Sybase::Storage::ASE', $method);
  is $got, $expected{$method},
    "DBIO::Sybase::Storage::ASE->$method resolves to the ASE trait, "
    . 'not the shadowing DBIO::Storage::DBI';
}

# And belt-and-suspenders: every ASE trait must precede DBIO::Storage::DBI in
# the C3 linearisation.
{
  my $isa = mro::get_linear_isa('DBIO::Sybase::Storage::ASE');
  my %pos = map { $isa->[$_] => $_ } 0 .. $#$isa;
  my $core_pos = $pos{'DBIO::Storage::DBI'};

  ok defined $core_pos, 'DBIO::Storage::DBI is in the ASE MRO';

  for my $trait (qw/
    DBIO::Sybase::Storage::ASE::IdentityRetrieval
    DBIO::Sybase::Storage::ASE::BulkInsert
    DBIO::Sybase::Storage::ASE::TxnManager
    DBIO::Sybase::Storage::ASE::LOBWriter
  /) {
    ok( (defined $pos{$trait} && defined $core_pos && $pos{$trait} < $core_pos),
      "$trait precedes DBIO::Storage::DBI in the C3 MRO" );
  }
}

done_testing;
