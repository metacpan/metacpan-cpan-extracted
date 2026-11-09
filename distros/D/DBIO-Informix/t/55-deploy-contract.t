use strict;
use warnings;
use Test::More;

# Offline Deploy-contract test — no live DB. Verifies that
# DBIO::Informix::Deploy is correctly wired into DBIO::Deploy::Base,
# exposing the three class-name hooks (_ddl_class / _introspect_class /
# _diff_class) and the throwaway-database dialect (_create_temp_db / _drop_temp_db). The deploy lifecycle
# (install / diff / apply / upgrade) is inherited unchanged from the
# base and is exercised end-to-end by the live tests in t/10-informix.t
# (gated on DBIO_TEST_INFORMIX_DSN).

use_ok 'DBIO::Informix::Deploy';
use_ok 'DBIO::Deploy::Base';

# Inheritance
ok( DBIO::Informix::Deploy->isa('DBIO::Deploy::Base'),
  'DBIO::Informix::Deploy inherits from DBIO::Deploy::Base' );

# Inherited lifecycle methods must be available (no need to override)
for my $method (qw/install diff apply upgrade/) {
  ok( DBIO::Informix::Deploy->can($method),
    "Deploy inherits $method from DBIO::Deploy::Base" );
}

# Class-name hooks — the base dispatches through these
is( DBIO::Informix::Deploy->_ddl_class,        'DBIO::Informix::DDL',        '_ddl_class' );
is( DBIO::Informix::Deploy->_introspect_class, 'DBIO::Informix::Introspect', '_introspect_class' );
is( DBIO::Informix::Deploy->_diff_class,       'DBIO::Informix::Diff',       '_diff_class' );

# Informix-specific seam: the throwaway-database dialect on top of the shared
# TempDatabase orchestration (_build_target_model)
ok( DBIO::Informix::Deploy->can('_build_target_model'),
  'Deploy has _build_target_model (Informix compares in a throwaway database)' );
ok( DBIO::Informix::Deploy->isa('DBIO::Deploy::Base::TempDatabase'),
  'Deploy builds on the shared throwaway-database orchestration' );
for my $method (qw/_create_temp_db _drop_temp_db _temp_dsn _admin_dbh/) {
  ok( defined &{"DBIO::Informix::Deploy::$method"}, "Deploy implements $method itself" );
}

# Inherited schema accessor
ok( DBIO::Informix::Deploy->can('schema'),
  'Deploy inherits schema accessor from base' );

done_testing;
