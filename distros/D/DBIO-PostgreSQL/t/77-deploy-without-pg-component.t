use strict;
use warnings;
use Test::More;

# OFFLINE test for karr k87: DBIO::PostgreSQL::Deploy on a schema that does
# NOT load the DBIO::PostgreSQL component.
#
# WHY IT MATTERS: karr k82 made install_ddl answer a component-less schema from
# the component class's own defaults (DBIO::PostgreSQL::DDL::_schema_decl).
# Deploy itself still asked the schema directly for pg_extensions (the
# extension prerequisite check, run by install and by the temp deploy behind
# diff) and pg_schemas (the introspector's schema_filter, used by diff) --
# methods only the component provides -- so DBIO::PostgreSQL::Deploy->new(
# schema => $plain_schema) died before install_ddl was ever reached.
#
# WHAT IT PINS: Deploy treats a component-less schema exactly like a
# component-loaded one that declares nothing, by the same mechanism k82
# established, so the two cannot drift apart:
#   - _check_extensions_available lives and asks the catalog nothing;
#   - _new_introspect lives and hands the introspector the same schema_filter
#     (none, i.e. unfiltered);
#   - install sends the same statements to the database handle.
# Each seam is also shown to react to a real declaration, so "does nothing"
# is measured, not assumed.

use DBIO::PostgreSQL ();
use DBIO::PostgreSQL::Deploy;

# -----------------------------------------------------------------------
# Mocks: a handle that records what reaches it, and a Deploy subclass that
# hands it out (the schema classes below are never connected).
# -----------------------------------------------------------------------
{
  package DeployNoPg::DBH;
  sub new { my ($c, @avail) = @_; bless { avail => \@avail, catalog => 0, do => [] }, $c }
  sub selectcol_arrayref { $_[0]->{catalog}++; [ @{ $_[0]->{avail} } ] }
  sub do { push @{ $_[0]->{do} }, $_[1]; 1 }
}
{
  package DeployNoPg::Deploy;
  use base 'DBIO::PostgreSQL::Deploy';
  sub _dbh { $_[0]->{mock_dbh} }
}

sub make_deploy {
  my ($schema, @avail) = @_;
  my $dbh = DeployNoPg::DBH->new(@avail);
  return (DeployNoPg::Deploy->new(schema => $schema, mock_dbh => $dbh), $dbh);
}

# A plain result class shared by every schema below.
{
  package DeployNoPg::Result::Widget;
  use base 'DBIO::Core';
  __PACKAGE__->table('widget');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  # Does NOT load the PostgreSQL component.
  package DeployNoPg::Plain;
  use base 'DBIO::Schema';
}
DeployNoPg::Plain->register_class(Widget => 'DeployNoPg::Result::Widget');
{
  # Loads the component and declares nothing.
  package DeployNoPg::Comp;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}
DeployNoPg::Comp->register_class(Widget => 'DeployNoPg::Result::Widget');
{
  # Loads the component and declares an extension and a namespace.
  package DeployNoPg::Declaring;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_extensions('vector');
  __PACKAGE__->pg_schemas('auth');
}

# -----------------------------------------------------------------------
# 0. The premise
# -----------------------------------------------------------------------
ok !DeployNoPg::Plain->can($_), "the component-less schema has no $_"
  for qw(pg_extensions pg_schemas);

# -----------------------------------------------------------------------
# 1. The extension prerequisite check (install, and the temp deploy of diff)
# -----------------------------------------------------------------------
{
  my ($deploy, $dbh) = make_deploy('DeployNoPg::Plain');
  my $ok = eval { $deploy->_check_extensions_available };
  is $ok, 1, '_check_extensions_available lives on a component-less schema'
    or diag "died: $@";
  is $dbh->{catalog}, 0, '... and asks the catalog nothing';

  my ($c_deploy, $c_dbh) = make_deploy('DeployNoPg::Comp');
  is $c_deploy->_check_extensions_available, 1,
    'same answer as a component-loaded schema declaring nothing';
  is $c_dbh->{catalog}, 0, '... which asks the catalog nothing either';

  my ($d_deploy, $d_dbh) = make_deploy('DeployNoPg::Declaring');
  ok !eval { $d_deploy->_check_extensions_available; 1 },
    'a declared, unavailable extension still fails the check';
  like $@, qr/"vector"/, '... naming it';
  is $d_dbh->{catalog}, 1, '... after asking the catalog';
}

# -----------------------------------------------------------------------
# 2. The introspector's schema_filter (diff: live and temp database)
# -----------------------------------------------------------------------
{
  my ($deploy, $dbh) = make_deploy('DeployNoPg::Plain');
  my $intro = eval { $deploy->_new_introspect($dbh) };
  ok $intro, '_new_introspect lives on a component-less schema'
    or diag "died: $@";

  my ($c_deploy, $c_dbh) = make_deploy('DeployNoPg::Comp');
  my $c_intro = $c_deploy->_new_introspect($c_dbh);
  is_deeply $intro && $intro->schema_filter, $c_intro->schema_filter,
    '... with the same schema_filter as a component-loaded schema declaring nothing';
  is $c_intro->schema_filter, undef, '... namely none (unfiltered)';

  my ($d_deploy, $d_dbh) = make_deploy('DeployNoPg::Declaring');
  is_deeply $d_deploy->_new_introspect($d_dbh)->schema_filter, ['auth'],
    'a declared namespace still scopes the introspector';
}

# -----------------------------------------------------------------------
# 3. install end to end: the same statements reach the handle
# -----------------------------------------------------------------------
{
  # The schema classes are never connected, so core's _execute_ddl finds no
  # storage to bracket with and emits its one-shot non-transactional notice.
  # Expected here and irrelevant to the claim; anything else still warns.
  local $SIG{__WARN__} = sub {
    warn @_ unless $_[0] =~ /^non-transactional DDL on DeployNoPg::Deploy/;
  };

  my ($deploy, $dbh) = make_deploy('DeployNoPg::Plain');
  ok eval { $deploy->install; 1 }, 'install lives on a component-less schema'
    or diag "died: $@";

  my ($c_deploy, $c_dbh) = make_deploy('DeployNoPg::Comp');
  $c_deploy->install;

  ok scalar @{ $c_dbh->{do} }, 'install sent statements to the handle';
  is_deeply $dbh->{do}, $c_dbh->{do},
    '... and the component-less schema sent exactly the same ones';
  is $dbh->{catalog}, 0, '... without a catalog query';
}

done_testing;
