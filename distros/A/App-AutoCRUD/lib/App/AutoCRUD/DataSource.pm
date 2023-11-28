package App::AutoCRUD::DataSource;

use strict;
use warnings;

use Moose;
use Carp;
use DBI;
use Clone           qw/clone/;
use List::MoreUtils qw/part/;
use Scalar::Does    qw/does/;
use Data::Reach     qw/reach/;
use SQL::Abstract::FromQuery 0.10;

use namespace::clean -except => 'meta';

has 'app'          => (is => 'ro', isa => 'App::AutoCRUD', required => 1,
                       weak_ref => 1, handles => [qw/ dir/]);
has 'name'         => (is => 'ro', isa => 'Str',
                       builder => '_name', lazy => 1);
has 'config'       => (is => 'ro', isa => 'HashRef', reader => 'config_data',
                       builder => '_config', lazy => 1);
has 'dbh'          => (is => 'ro', isa => 'DBI::db',
                       builder => '_dbh',  lazy => 1);
has 'schema'       => (is => 'ro', isa => 'Str|Object',
                       builder => '_schema', lazy => 1);
has 'query_parser' => (is => 'ro', isa => 'SQL::Abstract::FromQuery',
                       builder => '_query_parser', lazy => 1);
has 'tablegroups'  => (is => 'ro', isa => 'ArrayRef',
                       builder => '_tablegroups', lazy => 1);

# indirectly generated through the _schema builder method
has 'generated_schema' => (is => 'ro', isa => 'Str', init_arg => undef);
has 'loaded_class'     => (is => 'ro', isa => 'Str', init_arg => undef);



#======================================================================
# ATTRIBUTE BUILDERS
#======================================================================

sub _dbh {
  my $self = shift;
  my $dbh;

  # create a connection from specifications found in config
  if (my $connect_spec = $self->config(qw/dbh connect/)) {
    if (does($connect_spec, 'ARRAY')) {
      # regular DBI connect using the given list of arguments
      $dbh = DBI->connect(@$connect_spec)
        or die "can't connect to " . join(", ", @$connect_spec);
    }
    elsif (does($connect_spec, 'CODE')) {
      $dbh = $connect_spec->()
        or die "coderef connection to " . self->name . " failed";
    }
    elsif (does($connect_spec, '""')) {
      # config was a string : treat it as a line of Perl code
      local $@;
      $dbh = eval $connect_spec
        or die $@;
    }
    else {
      die "can't connect to " . $self->name . " (wrong config/dbh info)";
    }
  }

  # or recover existing connection in schema
  elsif (my $schema = $self->{schema}) { # bypass encapsulation to avoid
                                         # circular calls with ->_schema()
    $dbh = $schema->dbh;
  }

  # report failure if no connection found
  $dbh
    or die "no DBI/connect information in config for " . $self->name;

  return $dbh;
}

sub _schema {
  my $self = shift;

  my $required_class = $self->config('require');
  my $schema_class   = $self->config('schema_class') || $required_class;

  # if external code is required, load it
  if ($required_class && 
        !($schema_class && $self->app->is_class_loaded($schema_class))) {
    $self->{loaded_class} = $self->app->try_load_class($required_class)
      or die "Can't locate $required_class";
    $schema_class = $self->config('schema_class') || $self->{loaded_class};
  }

  # generate class on the fly if needed
  if (!$schema_class) {
    $schema_class = (ref $self) . "::_Auto_Schema::" . $self->name;

    if (! $self->app->is_class_loaded($schema_class)) {
      # build a schema generator from the DBI connection
      my $dbh = $self->dbh;
      require DBIx::DataModel::Schema::Generator;
      my $generator = DBIx::DataModel::Schema::Generator->new(
        -schema => $schema_class,
       );
      my @args = map {$self->config('dbh', $_)} qw/db_catalog db_schema db_type/;
      $generator->parse_DBI($self->dbh, @args);

      # generate and store perl code
      $self->{generated_schema} = $generator->perl_code;

      # eval source code on the fly
      eval $self->{generated_schema};
    }
  }

  return $schema_class;
}




sub _query_parser {
  my $self = shift;

  return SQL::Abstract::FromQuery->new;
}


sub _tablegroups {
  my ($self) = @_;

  # get table info from database
  my $dbh    = $self->dbh;
  my $sth    = $dbh->table_info($self->config(qw/dbh db_catalog/),
                                $self->config(qw/dbh db_schema/),
                                undef,
                                $self->config(qw/dbh db_type/) || 'TABLE',
                               );
  my $tables = $sth->fetchall_hashref('TABLE_NAME');

  # merge with descriptions from config
  foreach my $table (keys %$tables) {
    my $descr = $self->config(tables => $table => 'descr');
    $tables->{$table}{descr} = $descr if $descr;
  }

  # grouping: merge with table info from config
  my $tablegroups = clone $self->config('tablegroups') || [];
  foreach my $group (@$tablegroups) {
    # tables declared in this group are removed from the global %$tables ..
    my @declared_table_names = @{$group->{tables}};
    my @extracted_tables     = map {delete $tables->{$_}} @declared_table_names;

    # .. and their full definitions take place of the declared names
    $group->{tables} = [ grep {$_} @extracted_tables ];
  }

  # deal with remaining tables (
  if (my @other_tables = sort keys %$tables) {

    # Filter out based on the regexps in filters include & exclude
    if (my $filter_include = $self->config(qw/filters include/)) {
      @other_tables = grep { $_ =~ /$filter_include/ } @other_tables;
    }
    if (my $filter_exclude = $self->config(qw/filters exclude/)) {
      @other_tables = grep { $_ !~ /$filter_exclude/ } @other_tables;
    }

    # if some unclassified tables remain after the filtering
    if (@other_tables) {
      push @$tablegroups, {
        name   => 'Unclassified tables', 
        descr  => 'Present in database but unlisted in config',
        tables => [ @{$tables}{@other_tables} ],
      };
    }
  }

  return $tablegroups;
}


sub _config {
  my $self = shift;
  my $config = $self->app->config(datasources => $self->name)
    or die "no config for datasource " . $self->name;

  # shallow copy
  $config = { %$config };

  if (my $struct = $config->{structure}) {
    # get the structure config
    my $struct_config = $self->app->config(structures => $struct)
      or die "no config for structure $struct";

    # copy structure into datasource config
    $config->{$_} = $struct_config->{$_} foreach keys %$struct_config;
        
  }

  return $config;
}



#======================================================================
# METHODS
#======================================================================

sub config {
  my ($self, @path) = @_;
  return reach $self->config_data, @path;
}


sub descr {
  my ($self) = @_;
  return $self->config('descr');
}

sub prepare_for_request {
  my ($self, $req) = @_;

  # if schema is in single-schema mode, make sure it is connected to
  # the proper database
  my $schema = $self->schema;
  $schema->dbh($self->dbh) unless ref $schema;
}


sub primary_key {
  my ($self, $table) = @_;

  return $self->_meta_table($table)->primary_key;
}


sub colgroups {
  my ($self, $table) = @_;

  # if info already in cache, return it
  my $colgroups = $self->{colgroups}{$table};
  return $colgroups if $colgroups;

  # paths from this table
  my $meta_table = $self->_meta_table($table);
  my %paths      = $meta_table->path;

  # primary_key
  my @pk = $meta_table->primary_key;

  # get column info from database
  my $db_catalog = $self->config(qw/dbh db_catalog/);
  my $db_schema  = $self->config(qw/dbh db_schema/);
  my $sth        = $self->dbh->column_info($db_catalog, $db_schema,
                                           $table, undef);
  my $columns    = $sth->fetchall_hashref('COLUMN_NAME');

  # TMP HACK, Oracle-specific. Q: How to design a good abstraction for this ?
  $columns = $self->_columns_from_Oracle_synonym($db_schema, $table)
    if ! keys %$columns and $self->dbh->{Driver}{Name} eq 'Oracle';

  # mark primary keys
  $columns->{$_}{is_pk} = 1 foreach @pk;

  # attach paths (in alphabetic order) to relevant columns
  foreach my $path (map {$paths{$_}} sort keys %paths) {
    # name of column(s) from which this path starts
    my %path_on             = $path->on;
    my ($col_name, @others) = keys %path_on;

    # for the moment, don't handle assoc on multiple columns (TODO)
    next if @others;

    my $col = $columns->{$col_name} or next;
    my $path_subdata = { name        => $path->name,
                         to_table    => $path->to->db_from,
                         foreign_key => $path_on{$col_name} };
    push @{$col->{paths}}, $path_subdata;
  }

  # grouping: merge with column info from config
  $colgroups = clone $self->config(tables => $table => 'colgroups') || [];
  foreach my $group (@$colgroups) {
    my @columns;
    foreach my $column (@{$group->{columns}}) {
      my $col_name = $column->{name};
      my $db_col = delete $columns->{$col_name} or next;
      push @columns, {%$db_col, %$column};
    }
    $group->{columns} = \@columns;
  }

  # deal with remaining columns (present in database but unlisted in
  # config); sorted with primary keys first, then alphabetically.
  my $sort_pk = sub {   $columns->{$a}{is_pk} ? -1
                      : $columns->{$b}{is_pk} ?  1
                      :                         $a cmp $b};
  if (my @other_cols = sort $sort_pk keys %$columns) {
    # build colgroup
    push @$colgroups, {name    => 'Unclassified columns', 
                       columns => [ @{$columns}{@other_cols} ]};
  }

  # cache result and return
  $self->{colgroups}{$table} = $colgroups;
  return $colgroups;
}




sub _columns_from_Oracle_synonym {
  my ($self, $db_schema, $syn_name) = @_;

  my $dbh = $self->dbh;
  my $sql = "SELECT TABLE_OWNER, TABLE_NAME FROM ALL_SYNONYMS "
          . "WHERE OWNER=? AND SYNONYM_NAME=?";
  my ($owner, $table) = $dbh->selectrow_array($sql, {}, $db_schema, $syn_name)
    or return {};

  my $sth = $dbh->column_info(undef, $owner, $table, undef);
  return $sth->fetchall_hashref('COLUMN_NAME')
}



sub _meta_table {
  my ($self, $table) = @_;

  my $meta_table = $self->schema->metadm->db_table($table)
    or die "no table in schema corresponds to '$table'";
  return $meta_table;
}




1;

__END__

=head1 NAME

App::AutoCRUD::DataSource - 

=head1 DESCRIPTION

This class encapsulates all information needed by the AutoCRUD application
for communicating with one particular I<datasource>. The information
comes partly from the configuration file, and partly from the
requests made to the database schema.


=head1 ATTRIBUTES

=head2 app

Weak reference to the application that hosts this datasource.

=head2 name

Unique name identifying this datasource within the AutoCRUD application.
This name will be part of URLs addressing this datasource.

=head2 config

Copy of the configuration tree (see L<App::AutoCRUD::ConfigDomain>)
for this specific datasource.

=head2 dbh

L<DBI> database handle, which encapsulates the connection to the
database.  The dbh is created on demand, from connection parameters or
from a coderef specified in the configuration tree (see
L<App::AutoCRUD::ConfigDomain/dbh>); alternatively, it
can also be supplied from the calling program, or grabbed from the
schema. Once created, the dbh is readonly and cannot be changed (even
if the schema itself was bound to another dbh by a remote module -- the
dbh will be forced again before processing the HTTP request).


=head2 schema

An instance or a subclass of L<DBIx::DataModel::Schema>.
Usually this is loaded from parameters specified in the configuration tree;
if such parameters are absent, the fallback behavior is to generate
a class on the fly, using L<DBIx::DataModel::Schema::Generator>.


=head2 query_parser

An instance of L<SQL::Abstract::FromQuery>, for parsing the content
of search forms.

=head2 tablegroups

Information about tables in that datasource. This is an ordered list
of I<tablegroups>, where each tablegroup is a hashref with a B<name>,
a B<descr> (description), and an ordered list of I<tables>.
Each table in that list contains information as returned by
the L<DBI/table_info> method, plus an additional B<descr> field.

The tablegroups structure comes from the configuration data. If tables
are found in the database, but not mentioned in the configuration, they are
automatically inserted into a group called "Unclassified".


=head1 METHODS

=head2 config

  my $data = $datasource->config(@path);

Returns the config subtree at location C<@path> under this datasource.

=head2 descr

Returns the description string for this datasource, as specified in config.

=head2 prepare_for_request

  $datasource->prepare_for_request($req);

Called from L<App::AutoCRUD/call> before serving
a request. This is a hook for subclasses to provide application-specific
behaviour if needed (like for example resetting the database connection
or supplying user credentials from the HTTP request).
The argument C<$req> is an instance of L<Plack::Request>.

=head2 primary_key

Proxy method to L<DBIx::DataModel::Meta::Source/primary_key>.

=head2 colgroups

  my $colgroups = $datasource->colgroups($table_name);

Returns an arrayref of I<column groups>, as specified in config (or guessed
from the database meta-information, if the config says nothing).

Each column group is a hashref with keys C<name> (containing a string)
and C<columns> (containing an arrayref of I<columns>).

Each column is a hashref as returned from L<DBI/column_info>, i.e. containing
keys C<TABLE_NAME>, C<COLUMN_NAME>, C<DATA_TYPE>, C<COLUMN_SIZE>, etc.
In addition, some other keys are inserted into this hashref : 

=over

=item is_pkey

Boolean indicating that this column is part of the primary key

=item paths

An arrayref of I<paths> to other tables. Each path is a hashref with
keys C<name> (name of this path), C<to_table> (name of the associated table),
C<foreign_key> (name of the associated column in the remote table).

=back



