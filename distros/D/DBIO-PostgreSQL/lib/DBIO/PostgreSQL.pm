package DBIO::PostgreSQL;
# ABSTRACT: PostgreSQL-specific schema management for DBIO
our $VERSION = '0.900004';

use strict;
use warnings;

use base 'DBIO::Base';

use Carp ();
use DBIO::PostgreSQL::Storage ();
use DBIO::PostgreSQL::Extension ();

__PACKAGE__->mk_classdata('_pg_schemas' => []);
__PACKAGE__->mk_classdata('_pg_schema_classes' => {});
__PACKAGE__->mk_classdata('_pg_extensions' => []);
__PACKAGE__->mk_classdata('_pg_extension_schemas' => {});
__PACKAGE__->mk_classdata('_pg_extension_classes' => {});
__PACKAGE__->mk_classdata('_pg_search_path' => undef);
__PACKAGE__->mk_classdata('_pg_settings' => {});


sub pg_schemas {
  my $class = shift;
  if (@_) {
    my $classes = $class->_pg_schema_classes;
    my @bound = sort keys %$classes;
    Carp::croak(sprintf
      'pg_schemas() must be called before pg_schema_class(); bound already: %s',
      join(', ', @bound))
      if @bound;
    my %seen;
    $class->_pg_schemas([ grep { !$seen{$_}++ } @_ ]);
  }
  return @{ $class->_pg_schemas };
}


sub pg_schema_class {
  my ($class, $name, $pg_schema_class) = @_;
  my $classes = { %{ $class->_pg_schema_classes } };
  if ($pg_schema_class) {
    my @declared = $class->pg_schemas;
    Carp::croak(sprintf
      'pg_schema_class() for %s: pg_schemas() does not name it; declared: %s',
      $name, join(', ', @declared))
      if @declared and !grep { $_ eq $name } @declared;
    $classes->{$name} = $pg_schema_class;
    $class->_pg_schema_classes($classes);
  }
  return $classes->{$name};
}


sub pg_extensions {
  my $class = shift;
  if (@_) {
    my (@names, %schemas, %classes);
    my @args = @_;
    while (@args) {
      my $name = shift @args;
      Carp::croak(sprintf
        'pg_extensions(): an extension name is expected, got %s',
        defined $name ? (ref $name ? 'a ' . ref($name) . ' reference' : "'$name'") : 'undef')
        if !defined $name || ref $name || !length $name;
      push @names, $name;
      next unless @args && ref $args[0];
      my $opts = shift @args;
      Carp::croak("pg_extensions(): the options of extension '$name' are a hashref")
        unless ref $opts eq 'HASH';
      my @unknown = grep { $_ ne 'schema' && $_ ne 'class' } sort keys %$opts;
      Carp::croak(sprintf
        "pg_extensions(): extension '%s' has no option %s; the options are 'schema' and 'class'",
        $name, join(', ', map { "'$_'" } @unknown))
        if @unknown;
      Carp::croak("pg_extensions(): extension '$name' has an empty options hashref; give 'schema' or 'class'")
        unless keys %$opts;
      if (exists $opts->{schema}) {
        my $schema = $opts->{schema};
        Carp::croak("pg_extensions(): extension '$name' needs a 'schema', a plain non-empty string")
          unless defined $schema && !ref $schema && length $schema && $schema !~ /\0/;
        $schemas{$name} = $schema;
      }
      if (exists $opts->{class}) {
        my $extension_class = $opts->{class};
        Carp::croak("pg_extensions(): extension '$name' needs a 'class', a class name")
          unless defined $extension_class && !ref $extension_class
            && $extension_class =~ /\A[A-Za-z_]\w*(?:::\w+)*\z/;
        $classes{$name} = $extension_class;
      }
    }
    $class->_pg_extensions(\@names);
    $class->_pg_extension_schemas(\%schemas);
    $class->_pg_extension_classes(\%classes);
  }
  return @{ $class->_pg_extensions };
}


sub pg_extension_schemas {
  my ($class) = @_;
  return { %{ $class->_pg_extension_schemas } };
}


sub pg_extension_classes {
  my ($class) = @_;
  return { %{ $class->_pg_extension_classes } };
}


sub pg_search_path {
  my $class = shift;
  if (@_) {
    $class->_pg_search_path([@_]);
  }
  return @{ $class->_pg_search_path // [ 'public' ] };
}


sub pg_search_path_declared {
  my ($class) = @_;
  return defined $class->_pg_search_path ? 1 : 0;
}


sub pg_settings {
  my $class = shift;
  if (@_) {
    $class->_pg_settings($_[0]);
  }
  return $class->_pg_settings;
}


sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::PostgreSQL::Storage');
  $self->_register_extension_layers;
  return $self->next::method(@info);
}

# The storage layer (ADR 0032) of every declared extension whose class names
# one is registered with core's register_storage_layer, ahead of the composition
# core makes in connection(). The classes are loaded and checked for their
# interface here -- the layer has to be chosen before the storage is built --
# but their driver assertion waits for the first use of the connection. An
# extension chooses a layer, never the driver: the driver is the one this
# component pinned above.
sub _register_extension_layers {
  my ($self) = @_;
  my $list = DBIO::PostgreSQL::Extension->resolve_list($self, check_driver => 0)
    or return;
  for my $entry ($list->entries) {
    my $layer = $entry->{class}->storage_layer;
    $self->register_storage_layer($layer) if defined $layer;
  }
  return;
}


sub pg_deploy {
  my ($self, %args) = @_;

  my $storage = $self->storage;
  my $named   = $storage && $storage->can('dbio_deploy_class')
    ? $storage
    : 'DBIO::PostgreSQL::Storage';
  my $deploy_class = $named->dbio_deploy_class;
  $self->ensure_class_loaded($deploy_class);

  return $deploy_class->new(
    schema => $self,
    %args,
  );
}


sub pg_install_ddl {
  my ($self) = @_;
  require DBIO::PostgreSQL::DDL;
  return DBIO::PostgreSQL::DDL->install_ddl($self);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL - PostgreSQL-specific schema management for DBIO

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

=head2 Schema class

  package MyApp::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('PostgreSQL');

  __PACKAGE__->pg_schemas(qw( public auth ));

Or use the C<-pg> shortcut, which pins
C<+DBIO::PostgreSQL::Storage> as the storage type directly:

  package MyApp::Schema;
  use DBIO Schema => -pg;

=head2 Result classes

  package MyApp::Schema::Result::Artist;
  use DBIO;

  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100 },
  );
  __PACKAGE__->set_primary_key('id');

For result classes with PostgreSQL-native features, use C<-pg> to load
L<DBIO::PostgreSQL::Result>:

  package MyApp::Schema::Result::User;
  use DBIO -pg;

  __PACKAGE__->pg_schema('auth');
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    id   => { data_type => 'uuid', default_value => \'gen_random_uuid()' },
    name => { data_type => 'varchar', size => 100 },
    tags => { data_type => 'text[]' },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->pg_index('idx_users_name' => { columns => ['name'] });
  __PACKAGE__->pg_index('idx_users_tags' => { using => 'gin', columns => ['tags'] });

=head2 Connecting

  my $schema = MyApp::Schema->connect($dsn, $user, $pass);

The classic C<use base> form is still supported:

  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');

This driver component may equally be named as a base class alongside extension
components in a single C<use base>, with L<DBIO::Schema> last:

  package MyApp::Schema;
  use base qw( DBIO::PostgreSQL DBIO::PostgreSQL::Age DBIO::Schema );

The order of the components among themselves is free (this component before or
after an extension component both linearise), as long as no component in the
list inherits another one. An extension component that B<inherits> a driver
component makes the merge unsatisfiable: the driver would have to both precede
and follow the extension, so one stacking order dies with C<Inconsistent
hierarchy during C3 merge> while the other still loads. That is a rule about how
extension components are written, not a limit of this form; see ADR 0032
section 7 (addendum 2026-08-07) in the C<dbio> distribution.

C<load_components> does not expose that conflict: it de-duplicates through
L<Class::C3::Componentised>, so a driver component inherited by an extension is
loaded once and the ordering never becomes contradictory. Stacking with
C<use base> has no such step. Both forms are in use across the family; the
C<load_components> one is the more forgiving of a mis-declared extension.

=head1 DESCRIPTION

L<DBIO::PostgreSQL> is the PostgreSQL driver component for DBIO.

When this component is loaded into a schema class, C<connection()> sets
L<DBIO::Schema/storage_type> to C<+DBIO::PostgreSQL::Storage>, which enables
PostgreSQL-specific storage behavior automatically.

This distribution also provides PostgreSQL-native DDL/deploy helpers and
introspection/diff tooling.

=head1 METHODS

=head2 pg_schemas

Get or set the list of PostgreSQL schema names tracked by this schema class.

Declaring any restricts L<DBIO::PostgreSQL::Deploy> to these schemas: its
C<diff> introspects only them, and -- extensions being database-level, outside
every schema -- it creates declared extensions that are missing but drops none
it does not declare. With no schema declared the deploy owns the whole
database and drops every extension not declared via L</pg_extensions>. A
restricted deploy built with C<< manage_extensions_when_restricted => 1 >>
drops them too
(L<DBIO::PostgreSQL::Deploy/manage_extensions_when_restricted>).

The names are kept, and answered, in the order they were declared; a name
given twice stands once, at its first place. The install script creates the
schemas and the types of their L</pg_schema_class> bindings in that order.

Only this list restricts the deploy of the class. A L</pg_schema_class>
binding never does. A connection that names its namespace restricts the
deploy made for it to that namespace, whatever this list holds
(L</ONE SCHEMA CLASS IN SEVERAL NAMESPACES>).

Call it B<before> L</pg_schema_class>: it croaks, naming the bound schemas,
when a binding already exists. Setting it again while nothing is bound
replaces the list; reading it is always allowed.

=head2 pg_schema_class

Get or set the class mapped to a specific PostgreSQL schema name.

    __PACKAGE__->pg_schemas(qw( public auth ));
    __PACKAGE__->pg_schema_class('auth' => 'MyApp::DB::PgSchema::Auth');

This binding is the one source of the namespace
L<DBIO::PostgreSQL::DDL> installs the PgSchema class's enums, types and
functions into.

It does not restrict the deploy; only L</pg_schemas> does. With a
L</pg_schemas> list declared, the name must be on it: a binding for another
name croaks, naming it. With none declared, a bound class is installed, its
namespace after the declared ones in name order, and the deploy stays
unrestricted.

Call it after L</pg_schemas>.

=head2 pg_extensions

Get or set PostgreSQL extensions to include during deploy/DDL operations.

    __PACKAGE__->pg_extensions('vector');

    # an extension in a schema of its own
    __PACKAGE__->pg_extensions('pgcrypto', vector => { schema => 'extensions' });

Declared extensions are emitted as C<CREATE EXTENSION IF NOT EXISTS> before
any schema or table DDL, so extension-backed types (e.g. C<vector(N)> from
pgvector) deploy into the temporary database used by test-deploy-and-compare.
The extension must be installed on the server; L<DBIO::PostgreSQL::Deploy>
probes C<pg_available_extensions> before deploying and fails with an
actionable error naming the extension if it is not.

A name may be followed by a hashref with the keys C<schema> and C<class>:

=over 4

=item C<schema>

The schema the extension is installed in (C<CREATE EXTENSION ... WITH
SCHEMA>), a plain non-empty string.

=item C<class>

The extension class (a L<DBIO::Extension>) of an extension outside the
family; it wins over the driver's table. See L</Extension classes>.

=back

Any other key, an empty hashref, a second hashref for one name, a hashref
without a name before it, a C<schema> that is not a plain non-empty string and
a C<class> that is not a class name croak. The list in list context is the
names only, in the order they were declared; the schemas are
L</pg_extension_schemas> and the classes L</pg_extension_classes>.

=head3 Extension classes

The declaration is the list of the extensions a schema has (ADR 0066 of DBIO
core): an extension is not pulled in by loading a component, and a schema that
does not declare C<age> has no AGE rules, whatever is loaded in the process.
The driver resolves each declared name to its class when the deploy needs the
list:

=over 4

=item *

A name the family has a class for -- C<age>, C<postgis>, C<postgis_topology>
-- gets it from the fixed table of L<DBIO::PostgreSQL::Extension>. A
distribution that is not installed refuses, naming the distribution.

=item *

C<< name => { class => 'My::Extension' } >> names the class of an extension
outside the family, and wins over the table.

=item *

Any other name (C<citext>, C<pgcrypto>, C<vector>, ...) gets
L<DBIO::PostgreSQL::Extension>, which has no rules: the extension is installed
and kept, nothing else is done for it.

=back

What a class may do, the addresses it names, and what a deploy does with an
extension: L<DBIO::PostgreSQL::Deploy/EXTENSIONS>.

A name without a hashref declares no schema, and every C<CREATE EXTENSION> is
written C<WITH SCHEMA> all the same (unqualified it would land in
the first schema of the session's C<search_path>, C<ag_catalog> after the
activation of C<age>). The schema is, in this order: the declared one; the one
the extension's control file fixes (C<age> in C<ag_catalog>,
C<postgis_topology> in C<topology>, C<postgis_tiger_geocoder> in C<tiger>,
C<pg_cron> and C<plpgsql> in C<pg_catalog>), which
L<DBIO::PostgreSQL::Deploy> reads from the server
(C<pg_available_extension_versions>) for the install, the diff and its
temporary database, and so does C<deploy_async> of the C<future_io> transport
(over a pooled connection, before the DDL is built) -- a declared
schema other than the fixed one is refused, naming extension and both schemas,
before any statement; C<public>. For an
extension with a fixed schema the statement carries no clause: the server
installs it there whatever the C<search_path>, and creates the schema.
L</pg_install_ddl> and L<DBIO::PostgreSQL::DDL/install_ddl> called directly ask
no server and do not know a control file: an extension with a fixed schema has to declare
that schema on that way, or its C<WITH SCHEMA public> is refused by the
server. A deploy takes an installed extension for correct wherever the
database has it. Only a declared schema is compared.

What a declared schema does:

=over 4

=item *

The schema, unless it is C<public>, has to be declared by L</pg_schemas>;
otherwise the install script is refused, naming extension and schema. That
holds without a list as well: a schema only the extension names is neither
created nor guessed at. Declaring L</pg_schemas> makes the deploy
B<restricted> -- it then drops no extension it does not declare, unless built
with L<DBIO::PostgreSQL::Deploy/manage_extensions_when_restricted>. The
install creates the schema, ahead of the extension.

=item *

An extension the database has in another schema is moved there by
C<ALTER EXTENSION ... SET SCHEMA> when it is relocatable (C<pgcrypto>,
C<vector>, C<pg_trgm>, C<citext>, C<hstore>, C<uuid-ossp>, C<btree_gist>).
Its types, functions and operators go along, and so do the columns and
indexes that use them. A function body that names the old schema
(C<public.gen_random_uuid()>) is text for the server and is B<not> rewritten:
it breaks after the move and has to be written again.

=item *

An extension that is not relocatable (C<postgis>, C<postgis_topology>,
C<age>) is never moved: the diff is refused, naming the extension, both
schemas and the way out, before a statement is written.

=back

An extension present in the database but not declared here is dropped by a
L<DBIO::PostgreSQL::Deploy> diff only when the deploy is unrestricted; a
deploy restricted by L</pg_schemas> leaves it in place, unless it is built
with L<DBIO::PostgreSQL::Deploy/manage_extensions_when_restricted>.

=head2 pg_extension_schemas

    my $schemas = __PACKAGE__->pg_extension_schemas;   # { vector => 'extensions' }

The schemas L</pg_extensions> declared, as a hashref extension name to schema
name. Only the extensions that named one are in it. A copy: changing it
declares nothing.

=head2 pg_extension_classes

    my $classes = __PACKAGE__->pg_extension_classes;   # { vector => 'MyApp::DB::Extension::Vector' }

The classes L</pg_extensions> declared with the option C<class>, as a hashref
extension name to class name. Only the extensions that named one are in it; the
others get the class of the driver's table or the plain class
(L</Extension classes>). A copy: changing it declares nothing.

=head2 pg_search_path

    __PACKAGE__->pg_search_path(qw( auth public ));

Get or set the PostgreSQL C<search_path> list the connections of the schema
work with. Without a declaration the getter answers C<public> and nothing is
set on a connection.

A declared path is the C<search_path> of B<every connection> of the schema:
the sync connection and each connection of an async pool (C<< async =>
'future_io' >>) are sent C<SET search_path TO ...>, by
L<DBIO::PostgreSQL::Storage/_apply_connection_schema>, ahead of
C<on_connect_call> and C<on_connect_do>.

=over 4

=item *

B<Order.> The declared entries come first, in their order. Behind them stand
the schemas the extensions of L</pg_extensions> name with a schema (an
extension that names none adds nothing: write C<public> into the list where it
is wanted), then the C<search_path> entries of the extensions' activation (for
example C<ag_catalog>). Each schema stands once, at its first place.

=item *

B<The connect key C<schema>> wins: such a connection has its namespace first,
then the schemas of the extensions (L</ONE SCHEMA CLASS IN SEVERAL
NAMESPACES>), and this list is not read there (ADR 0008).

=item *

B<Nothing declared>: nothing is sent; the connection has the path the server,
the role or the DSN (C<options=-csearch_path=...>) give it, plus the entries of
an extension's activation. Declaring C<public> is a declaration.

=item *

B<The application's own statements win.> C<on_connect_do> and
C<on_connect_call> run after the declared path, so a C<SET search_path> there
replaces it. The declared path replaces one the DSN gave.

=back

The install script does not write the list: L<DBIO::PostgreSQL::DDL/install_ddl>
no longer closes with C<SET search_path TO ...>, which changed the path of the
session that ran it. A table or a view without a C<pg_schema> is created in the
first existing schema of the path the installing session has -- on a connection
of this schema, the declared one.

The entries are schema names and are quoted where they need it, so
C<MySchema> stays C<MySchema>; C<$user> is written as the server wants it,
C<"$user">. Write a name without quotes: an entry already in double quotes is
refused, naming the unquoted form (see L<DBIO::PostgreSQL::DDL/NAMES AND
VALUES>), when the install script is written and when a connection is set up.

=head2 pg_search_path_declared

    if ($schema_class->pg_search_path_declared) { ... }

True when L</pg_search_path> was given a list, C<public> included; false for
the default. The storage sets a path on a connection only for a declared one.

=head2 pg_settings

    __PACKAGE__->pg_settings({
        default_text_search_config => 'pg_catalog.german',
    });

Get or set, as a hashref, the configuration parameters the install stores on
the database.

L<DBIO::PostgreSQL::DDL/install_ddl> writes one statement per entry that
runs C<ALTER DATABASE ... SET key = 'value'> for the database the script runs
in -- a C<DO> block that asks the server for the name
(C<current_database()>), since the script is written without one and also
runs in the temporary database of L<DBIO::PostgreSQL::Deploy/diff>. The value
is written as one string literal. The key is a name, quoted where it needs it
like an entry of L</pg_search_path>; a dotted key is a dotted name, each part
for itself, so C<app.current_user_id> is written as it is and C<DateStyle>
as C<"DateStyle">. Write a key without quotes: one with a part already in
double quotes is refused, naming the unquoted form, and so is an empty key or
one with an empty part (see L<DBIO::PostgreSQL::DDL/NAMES AND VALUES>).

What that means on the server:

=over 4

=item *

The setting is a default for B<new> sessions of that database. The session
that runs the install does not get it.

=item *

The role that installs has to be allowed to set the parameter on the
database -- PostgreSQL asks for the owner of the database or a superuser,
depending on the parameter. Otherwise the install fails with the server's
error, as it does for a parameter the server does not know.

=item *

A value is one literal, so a parameter that takes a list gets one element:
C<< search_path => 'auth, public' >> names a single schema called
C<auth, public>.

=back

B<Install only.> The settings of a database are not part of the model
L<DBIO::PostgreSQL::Deploy/diff> compares, so an upgrade neither sets a value
that changed in the declaration nor resets one that is no longer declared.

=head2 connection

Overrides L<DBIO/connection> to force
C<+DBIO::PostgreSQL::Storage> as C<storage_type>.

It also registers, with L<DBIO::Schema/register_storage_layer>, the storage
layer (ADR 0032) that the class of a declared extension names in its
C<storage_layer> (AGE: its storage with C<cypher> and C<create_graph>), ahead
of the composition core makes in this method; core composes the async mirror of
the layer over a pool transport. The classes of the list are loaded and
checked for their interface version here, since the layer is chosen before the
storage exists; the assertion of their driver waits for the first use of the
connection. An extension chooses a layer, never the driver.

What the declared extensions want of every new connection -- C<LOAD> of a
library, schemas for the C<search_path> -- is applied by the storage, for the
sync connection and for each connection of an async pool
(L<DBIO::PostgreSQL::Storage/_apply_connection_schema>); the C<search_path>
is L<DBIO::PostgreSQL::Util/connection_search_path>.

=head2 pg_deploy

    my $deploy = $schema->pg_deploy;
    my $deploy = $schema->pg_deploy(temp_db_prefix => '_myapp_tmp_');

Returns a deploy object for the schema: an instance of the class the schema's
storage names in L<DBIO::PostgreSQL::Storage/dbio_deploy_class>. That is
L<DBIO::PostgreSQL::Deploy> -- the class C<< $schema->deploy >> installs
through. The arguments go to its constructor beside C<schema>.

A schema that has no storage yet, and one whose storage names no deploy class
(L<DBIO::Replicated>), gets the class L<DBIO::PostgreSQL::Storage> names.

=head2 pg_install_ddl

Generates PostgreSQL-native DDL statements for the schema. Called on a schema
connected with the connect key C<schema>, it is the script of that
connection's namespace
(L<DBIO::PostgreSQL::DDL/A CONNECTION THAT NAMES ITS NAMESPACE>).

=head1 ONE SCHEMA CLASS IN SEVERAL NAMESPACES

A schema class that names no namespace -- no L</pg_schema_class>, no
C<pg_schema> in a result class, table names without a schema -- is installed
into, and read from, whichever namespace a connection names with the connect
key C<schema>:

  my $tenant_a = MyApp::Schema->connect($dsn, $user, $pass, { schema => 'tenant_a' });
  my $tenant_b = MyApp::Schema->connect($dsn, $user, $pass, { schema => 'tenant_b' });

  $tenant_a->pg_deploy->install;    # creates tenant_a, installs into it
  $tenant_b->pg_deploy->install;    # the same classes, in tenant_b

  $tenant_a->resultset('User')->all;    # tenant_a.users

The key is one name, and it is the connection's: nothing of it is kept in the
class, so the same class is connected for any number of namespaces at once.
Every connection of such a schema has the namespace first in its
C<search_path> -- the sync connection and each connection of an async pool
(C<< async => 'future_io' >>) -- set before C<on_connect_call> and
C<on_connect_do> run (L<DBIO::PostgreSQL::Storage/_set_connection_schema>).

=over 4

=item *

B<The search path> is the namespace, then the schemas of the extensions
L</pg_extensions> declares, each once, in the order of the extensions:
for an extension that names no schema the one its control file fixes (the
server answers: C<ag_catalog> for age, C<topology> for postgis_topology),
else C<public>; C<public> when no extension is declared. So the types, functions and operators of the
extensions are found without their schema. L</pg_search_path> is not read on
such a connection (a connection without the key has it as its path).

=item *

B<Extensions> belong to the database, not to a namespace. The install creates
each C<WITH SCHEMA> -- the schema it names, else the one its control file
fixes, C<public> otherwise -- and
refuses one whose schema is the namespace of the connection.

=item *

B<The install> creates the namespace when it is not there
(looked up in C<pg_namespace> first, so a role without C<CREATE> on the database can install into a namespace that is there) and sets the C<search_path> itself, ahead of
the first object. See
L<DBIO::PostgreSQL::DDL/A CONNECTION THAT NAMES ITS NAMESPACE>.

=item *

B<The deploy> of such a connection is restricted to its namespace: its diff
compares that namespace alone, and drops no extension. See
L<DBIO::PostgreSQL::Deploy>.

=item *

What a declaration writes as SQL -- a view's definition, a default, a
C<pg_extra_ddl> statement -- names its objects without a schema, like the
tables, and reaches the namespace through the C<search_path>.

=back

A schema class that manages several namespaces of its own stays with
L</pg_schemas> and L</pg_schema_class> and is connected without the key: on a
connection that names its namespace, the install refuses a
L</pg_schema_class> binding, a result class with a C<pg_schema> and a table
name that carries its schema.

=head2 Types and functions on such a connection

Declare them without a schema; they land in the namespace like the tables,
through the C<search_path> the install script sets. Two declarations do that
today: an enum column with C<< extra => { list => [...] } >> (its type
C<{table}_{column}_enum> is created, and used, unqualified) and raw SQL in
L<DBIO::PostgreSQL::Result/pg_extra_ddl> (written as given, after the table; a
function there lands in the namespace, a type only for what comes after the
table). L<DBIO::PostgreSQL::PgSchema> (C<pg_enum>, C<pg_type>,
C<pg_function>) is reached only through a L</pg_schema_class> binding, which
such a connection refuses, so there is no schema-level declaration of enums,
composite types or functions for a connection with the key. The SQL of a
function is written as given and not read: a body or a C<CREATE FUNCTION
other.f> that names a schema reaches that schema, not the namespace.

=head1 PGVECTOR

pgvector support covers declaring vector columns, querying them by distance,
indexing them, and converting their values. The extension must be installed on
the server and declared via L</pg_extensions>:

  __PACKAGE__->pg_extensions('vector');

C<CREATE EXTENSION IF NOT EXISTS vector> is emitted before any schema or table
DDL, so C<vector(N)> columns deploy into the temporary database used by
test-deploy-and-compare. L<DBIO::PostgreSQL::Deploy> probes
C<pg_available_extensions> first and fails with an actionable error naming the
extension if it is missing.

=head2 Declaring columns

  __PACKAGE__->add_columns(
    embedding => { data_type => 'vector(3)' },       # dense vector
    half      => { data_type => 'halfvec(3)' },      # half-precision dense
    sparse    => { data_type => 'sparsevec(1000)' }, # sparse vector
  );

C<vector(N)> and C<halfvec(N)> are dense vectors; C<sparsevec(N)> is sparse.
Declaring a pgvector column promotes the source's C<resultset_class> to
L<DBIO::PostgreSQL::ResultSet> (so C<nearest_neighbors> is available) and
enables value inflation/deflation (see L</Value handling>).

=head2 Querying

Distance queries go through the C<vector()> DSL from
L<DBIO::PostgreSQL::Vector>:

  use DBIO::PostgreSQL::Vector qw(vector);

  # KNN — nearest neighbors by cosine distance
  $rs->search(
    {},
    {
      order_by => vector('me.embedding')->cosine_distance([0.1, 0.2])->as_order,
      rows     => 5,
    },
  );

  # Distance range filter
  $rs->search( vector('me.embedding')->l2_distance($v)->lt(5) );

The query vector travels as a bind placeholder cast to the column's type
(C<?::vector> by default, or C<?::sparsevec> automatically for a sparsevec
hashref query vector; C<cast =E<gt> 'halfvec'> overrides for C<halfvec>/C<bit>
columns). For the common KNN shape, use
L<DBIO::PostgreSQL::ResultSet/nearest_neighbors>:

  $rs->nearest_neighbors(
    embedding => [0.1, 0.2, 0.3],
    distance  => 'cosine',
    rows      => 10,
  );

=head2 Indexing

C<hnsw> has no default operator class for C<vector>, so an C<hnsw> index on a
vector column must name one:

  __PACKAGE__->pg_index('idx_items_embedding' => {
    using     => 'hnsw',
    columns   => ['embedding'],
    opclasses => { embedding => 'vector_cosine_ops' },
  });

C<ivfflat> does have a default for C<vector>, C<vector_l2_ops>, and uses it
when no operator class is named; any other distance has to be named there too.

C<vector_l2_ops> serves C<<< <-> >>>, C<vector_cosine_ops> serves C<<< <=> >>>,
C<vector_ip_ops> serves C<<< <#> >>> (with C<halfvec_*> / C<sparsevec_*> /
C<bit_*> families for the other column types). C<hnsw> and C<ivfflat> support
C<vector> columns up to 2000 dimensions. Ordering by an operator no index
covers is not an error — PostgreSQL falls back to a sequential scan; C<EXPLAIN>
is the only real confirmation that an index serves a query.

=head2 Value handling

pgvector columns inflate/deflate by default: an ArrayRef deflates to
C<[0.1,0.2]> and inflates back on fetch; a sparsevec HashRef deflates to
C<{i:v,...}/N> and inflates to C<< { dims => N, values => {...} } >>. The
conversion is idempotent — a plain string passes through verbatim. Opt out per
column with C<inflate_pgvector =E<gt> 0>. See
L<DBIO::PostgreSQL::InflateColumn::Vector>.

=head1 MIGRATION NOTES

The PostgreSQL storage class was split out of the historical DBIx::Class
monolithic distribution:

=over 4

=item *

Old: C<DBIx::Class::Storage::DBI::Pg>

=item *

New: C<DBIO::PostgreSQL::Storage>

=back

A schema declares the driver with this component or C<use DBIO 'Schema', -pg>;
core picks no storage class from the DSN (core ADR 0067).

=head1 TESTING

Integration tests in this distribution use:

  DBIO_TEST_PG_DSN
  DBIO_TEST_PG_USER
  DBIO_TEST_PG_PASS

SQLMaker-focused tests can run offline via L<DBIO::Test> with:

  storage_type => 'DBIO::PostgreSQL::Storage'

Replicated-path tests can reuse the same harness with:

  replicated   => 1,
  storage_type => 'DBIO::PostgreSQL::Storage'

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
