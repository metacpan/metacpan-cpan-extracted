use strict;
use warnings;
use Test::More;

# OFFLINE test: the storage's dbio_deploy_class is the one place that names
# the deploy class, and the storage has no install route of its own (karr
# k104, core ADR 0064).
#
# WHY: a schema is installed by the class its storage names in
# dbio_deploy_class. Core asks there from $schema->deploy and from
# $storage->deploy. A storage layer does not answer there (core ADR 0066,
# section 4): the driver storage is the one owner. A second place that names the class --
# pg_deploy writing DBIO::PostgreSQL::Deploy out, a deploy of this storage
# going to pg_deploy -- installs the same schema with one class by one way
# and with another class by the next, and the extension's part of the install
# is silently missing on one of them.
#
# What this file claims:
#   1. $schema->pg_deploy is an object of the class the schema's storage
#      names -- under a registered storage layer too, which names none -- and
#      hands its arguments to the constructor;
#   2. a schema class that has no storage yet gets the class the driver's
#      storage names, and so does a connected schema: change the name there
#      and both follow;
#   3. $storage->deploy($schema) installs through the class the storage
#      names, for a schema with the component as for one without;
#   4. DBIO::PostgreSQL::Storage defines neither deploy nor
#      deployment_statements: both are core's (ADR 0064, points 1 and 3).
#
# NOT CLAIMED: what a real install puts into a database -- that is
# t/128-storage-deploy-class-live.t.
#
# THE SUBSTITUTIONS: the layer's ensure_connected does nothing and
# DBI->connect dies, so no server is asked; the layer's deploy class records
# the schema it is handed instead of installing it.

use DBI;
use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::Deploy;

{
  package T128::Result::Widget;
  use base 'DBIO::Core';
  __PACKAGE__->table('widget');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100 },
  );
  __PACKAGE__->set_primary_key('id');
}

# A deploy class of an extension: it records what it is to install.
{
  package T128::Deploy;
  our @installed;
  sub new { my ($class, %args) = @_; bless {%args}, $class }
  sub install { push @installed, $_[0]{schema}; 1 }
}
$INC{'T128/Deploy.pm'} = __FILE__;

# The storage layer of that extension, a plain package as every layer is.
{
  package T128::Layer;
  sub ensure_connected  { 1 }
}
$INC{'T128/Layer.pm'} = __FILE__;

{
  package T128::Comp;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
}
T128::Comp->register_class(Widget => 'T128::Result::Widget');
{
  package T128::CompLayered;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_storage_layer('T128::Layer');
}
T128::CompLayered->register_class(Widget => 'T128::Result::Widget');
{
  # Does NOT load the PostgreSQL component: the shortcut declares the driver
  # and nothing else (a schema always has one, core ADR 0067).
  package T128::PlainLayered;
  use DBIO 'Schema', -pg;
  __PACKAGE__->register_storage_layer('T128::Layer');
}
T128::PlainLayered->register_class(Widget => 'T128::Result::Widget');

my $connects = 0;
{
  no warnings 'redefine';
  *DBI::connect = sub { $connects++; die "DBI->connect was reached\n" };
}

sub connected_schema {
  my ($class) = @_;
  return $class->connect('dbi:Pg:dbname=appdb;host=db.example', 'app', 's3cret');
}

# ---------------------------------------------------------------------------
# 1. pg_deploy asks the storage.
# ---------------------------------------------------------------------------

{
  my $schema = connected_schema('T128::Comp');
  is $schema->storage->dbio_deploy_class, 'DBIO::PostgreSQL::Deploy',
    'the PostgreSQL storage names DBIO::PostgreSQL::Deploy';

  my $deploy = $schema->pg_deploy(temp_db_prefix => '_t128_');
  is ref $deploy, 'DBIO::PostgreSQL::Deploy', '... and pg_deploy is an object of it';
  is $deploy->schema, $schema, '... for the schema it was asked of';
  is $deploy->temp_db_prefix, '_t128_', '... with the arguments pg_deploy was given';
}

{
  my $schema = connected_schema('T128::CompLayered');
  isa_ok $schema->storage, 'DBIO::PostgreSQL::Storage', 'the storage under a layer';
  ok !defined &T128::Layer::dbio_deploy_class, 'the layer defines no dbio_deploy_class';
  is $schema->storage->dbio_deploy_class, 'DBIO::PostgreSQL::Deploy',
    '... the storage under it names the deploy class of the driver';

  my $deploy = $schema->pg_deploy(temp_db_prefix => '_t128_');
  is ref $deploy, 'DBIO::PostgreSQL::Deploy', '... and pg_deploy is an object of that class';
  is $deploy->schema, $schema, '... for the schema it was asked of';
  is $deploy->temp_db_prefix, '_t128_', '... with the arguments pg_deploy was given';
}

# ---------------------------------------------------------------------------
# 2. One place names the class.
# ---------------------------------------------------------------------------

{
  is(T128::Comp->storage, undef, 'a schema class that was never connected has no storage');
  is(ref T128::Comp->pg_deploy, DBIO::PostgreSQL::Storage->dbio_deploy_class,
    '... and its pg_deploy is an object of the class the driver storage names');

  no warnings 'redefine';
  local *DBIO::PostgreSQL::Storage::dbio_deploy_class = sub { 'T128::Deploy' };

  is(ref T128::Comp->pg_deploy, 'T128::Deploy',
    'with another name in dbio_deploy_class: pg_deploy of the schema class follows');
  is(ref connected_schema('T128::Comp')->pg_deploy, 'T128::Deploy',
    '... and pg_deploy of a connected schema');
}

# ---------------------------------------------------------------------------
# 3. $storage->deploy installs through the class the storage names.
# ---------------------------------------------------------------------------

for my $case (
  [ 'T128::CompLayered',  'with the component' ],
  [ 'T128::PlainLayered', 'without the component' ],
) {
  my ($class, $label) = @$case;
  my $schema = connected_schema($class);
  @T128::Deploy::installed = ();
  $connects = 0;
  # the driver storage names the class; the layer over it names none
  no warnings 'redefine';
  local *DBIO::PostgreSQL::Storage::dbio_deploy_class = sub { 'T128::Deploy' };

  ok eval { $schema->storage->deploy($schema); 1 }, "\$storage->deploy, a schema $label: lives"
    or diag $@;
  is_deeply \@T128::Deploy::installed, [ $schema ],
    '... and the deploy class the storage names was handed the schema, once';
  is $connects, 0, '... nothing else went to a server';
}

# ---------------------------------------------------------------------------
# 4. The routing is core's.
# ---------------------------------------------------------------------------

for my $method (qw( deploy deployment_statements )) {
  no strict 'refs';
  ok !defined &{"DBIO::PostgreSQL::Storage::$method"},
    "DBIO::PostgreSQL::Storage defines no $method of its own";
  is(DBIO::PostgreSQL::Storage->can($method), DBIO::Storage::DBI->can($method),
    "... \$storage->$method is DBIO::Storage::DBI's");
}

done_testing;
