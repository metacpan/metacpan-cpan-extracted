package DBIx::PgLink::Adapter;

use Carp;
use Moose;
use MooseX::Method;
use DBI qw(:sql_types);
use DBIx::PgLink::Logger qw/trace_msg trace_level/;
use DBIx::PgLink::Types;
use Data::Dumper;

extends 'Moose::Object';

our $VERSION = '0.01';

has 'connector' => (
  is  => 'ro',
  isa => 'DBIx::PgLink::Connector',
  required => 0,
  weak_ref => 1,
);

has 'dbh' => (
  isa     => 'Object', # could be ::db or any DBIx wrapper
  is      => 'rw',
  # delegation bug #1: wrong context for list-returning methods
  # delegation bug #2: reconnection hook cannot use wrapped method, core dump at subsequent call of $next->()
  handles => [ qw/
    err errstr state set_err func
    data_sources do last_insert_id
    selectrow_array selectrow_arrayref selectrow_hashref
    selectall_arrayref selectall_hashref selectcol_arrayref
    prepare prepare_cached
    commit rollback begin_work
    disconnect ping
    get_info table_info column_info primary_key_info primary_key
    foreign_key_info statistics_info tables
    type_info_all type_info
    quote quote_identifier
  /],
);

has 'statement_roles' => (
  isa => 'ArrayRef',
  is  => 'rw',
  auto_deref => 1,
  default => sub { [] },
);


with 'DBIx::PgLink::RoleInstaller';
has '+role_prefix' => ( default => __PACKAGE__ . '::Roles::' );


has 'are_transactions_supported' => (
  isa => 'Bool',
  is  => 'ro',
  lazy => 1,
  default => sub { 
    # borrowed from DBIx::SQLEngine
    my $self = shift;
    my $dbh = $self->dbh;
    eval {
      local $SIG{__DIE__};
      $dbh->begin_work;
      $dbh->rollback;
    };
    return ( $@ ) ? 0 : 1;
  },
);

has 'are_routines_supported' => (is=>'ro', isa=>'Bool', default=>0);
has 'routine_can_be_overloaded' => (is=>'ro', isa=>'Bool', default=>0);
has 'include_catalog_to_qualified_name' => (is=>'ro', isa=>'Bool', default=>0);
has 'include_schema_to_qualified_name' => (is=>'ro', isa=>'Bool', default=>1);
has 'require_parameter_type' => (is=>'ro', isa=>'Bool', default=>1); # performance option, typed binding ~2x times slower

sub connect {
  my $self = shift;
  my $attr = $_[-1];
  if (ref $attr ne 'HASH') {
    $attr = {};
    push @_, $attr;
  }
  $attr->{RaiseError} = 1;
  $attr->{PrintError} = 0;
  $attr->{AutoCommit} = 1 unless exists $attr->{AutoCommit};
  # appends a stack trace to all errors
  $attr->{HandleError} = sub { $_[0]=Carp::longmess($_[0]); 0; }; 

  trace_msg('INFO', 'connect') if trace_level >= 2;
  $self->dbh( DBI->connect(@_) );
  $self->initialize_session;
  return $self->dbh;
}


sub dbi_method {
  my $self = shift;
  my $dbi_handle = shift; # dbh or sth
  my $method = shift;
  return $dbi_handle->$method(@_);
}

# protected statement-returning methods
for my $func (qw/
  prepare prepare_cached
  table_info column_info primary_key_info foreign_key_info statistics_info
/) {
  around $func => sub {
    my $next = shift;
    my $self = shift;
    trace_msg('INFO', "$func") if trace_level >= 3;
    my $sth = $self->dbi_method($self->dbh, $func, @_);
    return unless $sth;
    my $st = $self->new_statement(
      class  => 'DBIx::PgLink::Adapter::st', 
      parent => $self, 
      sth    => $sth,
    );
    return $st;
  };
}

sub new_statement {
  my ($self, %p) = @_;
  my $class = $p{class};
  my $st = $class->new(%p);
  for my $role ($self->statement_roles) {
    $role->meta->apply($st);
  }
  return $st;
}


# list-returning methods and other protected methods
for my $func (qw/
  data_sources func do primary_key tables type_info
  selectrow_array selectrow_arrayref selectrow_hashref
  selectall_arrayref selectall_hashref selectcol_arrayref
  commit rollback begin_work
/) {
  around $func => sub {
    my $next = shift;
    my $self = shift;
    trace_msg('INFO', "$func") if trace_level >= 3;
    return $self->dbi_method($self->dbh, $func, @_);
  };
}

sub is_transaction_active {
  my $self = shift;
  return ! $self->dbh->{'AutoCommit'};
}

sub initialize_session { 1 }

# for Reconnect role
sub always_valid_query {
  "SELECT 1"
}

sub check_where_condition { 1 }


has 'is_plperl' => ( 
  is  => 'ro',
  isa => 'Bool',
  lazy => 1,
  default => sub {
    eval "main::NOTICE";
    return !$@;
  }
);

sub require_plperl {
  my ($self, $who) = @_;
  die "$who can be used in PL/Perl environment only"
    unless $self->is_plperl;
}


# most of DBI catalog methods returns statement handle
# here we define wrapper subs that returns reference to array of hashes 
# and call expand_xxx method on every hash item
# Expanded metadata may contain additional fields consumed by Accessor

sub table_info_arrayref {
  my $self = shift;
  my $sth = $self->table_info(@_);
  return [] unless $sth;
  my @result = ();
  while (my $i = $sth->fetchrow_hashref) {
    $self->expand_table_info($i)
    and push @result, $i;
  }
  $sth->finish;
  return \@result;
}


sub routine_info_arrayref {
  my $self = shift;
  my $sth = $self->routine_info(@_);
  return [] unless $sth;
  my @result = ();
  while (my $i = $sth->fetchrow_hashref) {
    $self->expand_routine_info($i)
    and push @result, $i;
  }
  $sth->finish;
  return \@result;
}


sub column_info_arrayref {
  my $self = shift;
  my $sth = $self->column_info(@_);
  return [] unless $sth;
  my @result = ();
  while (my $i = $sth->fetchrow_hashref) {
    $self->expand_column_info($i)
    and push @result, $i;
  }
  $sth->finish;
  return \@result;
}


# create column_info-like structure from statement description, returns refarray of hashes
# NOTE: some drivers cannot have more than one open statement
#       call type_info() once *before* this method
sub column_info_from_statement_arrayref {
  my ($self, $catalog, $schema, $table, $sth) = @_;
  my @result;
  my %ti;
  if ($sth->isa('DBIx::PgLink::Adapter::st')) {
    $sth = $sth->sth; # get the real DBI::st
  }
  for my $f (0..$sth->{NUM_OF_FIELDS}-1) {
    my $type = $sth->{TYPE}->[$f];
    unless (defined $ti{$type}) {
      $ti{$type} = ($self->type_info($type))[0]; #!!! first row only
    }
    push @result, {
      TABLE_CAT        => $catalog,
      TABLE_SCHEM      => $schema,
      TABLE_NAME       => $table,
      COLUMN_NAME      => $sth->{NAME}->[$f],
      DATA_TYPE        => $type,
      TYPE_NAME        => $ti{$type}->{TYPE_NAME},
      COLUMN_SIZE      => $sth->{PRECISION}->[$f],
      DECIMAL_DIGITS   => $sth->{SCALE}->[$f],
      NUM_PREC_RADIX   => $sth->{SCALE}->[$f],
      NULLABLE         => $sth->{NULLABLE}->[$f],
      ORDINAL_POSITION => $f+1,
      IS_NULLABLE      => $sth->{NULLABLE}->[$f] ? 'YES' : 'NO',
    };
  }
  return \@result;
}


sub primary_key_info_arrayref {
  my $self = shift;
  my $sth = $self->primary_key_info(@_) or return;
  return [] unless $sth;
  my @result = ();
  while (my $i = $sth->fetchrow_hashref) {
    $self->expand_primary_key_info($i)
    and push @result, $i;
  }
  $sth->finish;
  return \@result;
}

# add or fix catalog information for Accessor
sub expand_table_info { 1 }
sub expand_routine_info { 1 }
sub expand_column_info { 1 }
sub expand_primary_key_info { 1 }
sub expand_routine_argument_info { 1 }

sub unquote_identifier {
  my ($self, $i) = @_;
  # don't support full-qualified name with schema!
  if ($i =~ /^"(.*)"$/) {
    $i = $1;
    $i =~ s/""/"/g;
  }
  return $i;
}

sub trim_trailing_spaces {
  $_[0] =~ s/ +$//;
}


sub routine_info { 
  my ($self, $catalog, $schema, $routine, $type) = @_;
  # generic INFORMATION_SCHEMA (supported by Pg and MSSQL, but not very useful)

  my $type_cond = do {
    if (!defined $type || $type eq '%') {
      ''
    } elsif ($type =~ /('\w+',)*('\w+')/) {
      "AND ROUTINE_TYPE IN ($type)"
    } else {
      "AND ROUTINE_TYPE IN ('" . join("','", split /,/, $type) . "')"
    }
  };

  my $sth = eval {
    $self->prepare(<<END_OF_SQL);
SELECT
  SPECIFIC_CATALOG,
  SPECIFIC_SCHEMA,
  SPECIFIC_NAME,
  ROUTINE_CATALOG,
  ROUTINE_SCHEMA,
  ROUTINE_NAME,
  ROUTINE_TYPE,
  DATA_TYPE
FROM INFORMATION_SCHEMA.ROUTINES
WHERE SPECIFIC_CATALOG like ?
  AND SPECIFIC_SCHEMA like ?
  AND SPECIFIC_NAME like ?
  $type_cond
ORDER BY 1,2,3
END_OF_SQL
  };
  return undef if $@;
  $sth->execute($catalog, $schema, $routine);
  return $sth;
}


sub routine_argument_info_arrayref { 
  my ($self, $routine_info) = @_;
  # no INFORMATION_SCHEMA catalog for routine input arguments
  # NOTE: should returns AoH for single routine
  return [];
}


sub routine_column_info_arrayref { 
  my ($self, $routine_info) = @_;
  # NOTE: should returns AoH for single routine
  # NOTE: not supported by Pg
  my $sth = eval {
    $self->prepare(<<END_OF_SQL);
SELECT *
FROM INFORMATION_SCHEMA.ROUTINE_COLUMNS
WHERE TABLE_CATALOG = ?
  AND TABLE_SCHEMA = ?
  AND TABLE_NAME = ?
ORDER BY 1,2,3
END_OF_SQL
  };
  return [] if $@;
  $sth->execute(
    $routine_info->{SPECIFIC_CATALOG}, 
    $routine_info->{SPECIFIC_SCHEMA}, 
    $routine_info->{SPECIFIC_NAME}, 
  );
  my @result = ();
  while (my $i = $sth->fetchrow_hashref) {
    $self->expand_column_info($i)
    and push @result, $i;
  }
  $sth->finish;
  return \@result;
}


method 'format_routine_call' => named(
  catalog      => {isa=>'StrNull',required=>0},
  schema       => {isa=>'StrNull',required=>0},
  routine      => {isa=>'Str',required=>1},
  routine_type => {isa=>'Str',required=>1},
  returns_set  => {isa=>'Str',required=>0},
  arguments    => {isa=>'ArrayRef',required=>0, default=>[]},
) => sub {
  my ($self, $p) = @_;

  my $result = 'SELECT ';
  $result .= '* FROM ' if $p->{returns_set};
  $result .= $self->quote_identifier($p->{catalog}, $p->{schema}, $p->{routine}) 
    . '(' . join(',', map { '?' } @{$p->{arguments}} ) . ')';
  return $result;
};


sub get_number_of_rows {
  my ($self, $catalog, $schema, $object, $type) = @_;
  return selectrow_array("SELECT count(*) FROM " . $self->quote_identifier($schema, $object) );
  # descendants can use estimated row count
}

# -------------- conversion


# octal escape all bytes (PL/Perl cannot return raw binary data)
# SLOW!
my @byte_oct;
sub to_pg_bytea {
  return unless defined $_[1] && length($_[1]) > 0;
  unless (@byte_oct) {
    for my $c (0..255) {
      $byte_oct[$c] = sprintf('\%03o', $c);
    }
  }
  my $b = '';
#  use bytes;
  for (my $i = 0; $i < length($_[1]); $i++) {
    $b .= $byte_oct[ord(substr($_[1],$i,1))];
  }
  $_[1] = $b;
}


1;



package DBIx::PgLink::Adapter::st;

use Moose;
use DBIx::PgLink::Logger qw/trace_msg trace_level/;

our $VERSION = '0.01';

extends 'Moose::Object';

has 'parent' => (
  isa => 'DBIx::PgLink::Adapter',
  is  => 'ro',
  required => 1,
  is_weak => 1,
);

has 'sth' => (
  isa => 'Object', #'DBI::st',
  is => 'ro',
  handles => [ qw/
    err errstr state set_err func
    bind_param bind_param_inout bind_param_array
    execute execute_array execute_for_fetch
    fetch fetchrow_arrayref fetchrow_array fetchrow_hashref fetchall_arrayref fetchall_hashref
    finish rows
    bind_col bind_columns dump_results
  /],
);

# protected methods
for my $func (qw/
    func execute execute_array execute_for_fetch
    fetch fetchrow_arrayref fetchrow_array fetchrow_hashref fetchall_arrayref fetchall_hashref
/) {
  around $func => sub {
    my $next = shift;
    my $self = shift;
    trace_msg('INFO', "$func") if trace_level >= 3;
    return $self->parent->dbi_method($self->sth, $func, @_);
  };
}

#sub DESTROY {
#  my $self = shift;
#  warn "destroing sth for $self->{sth}->{Statement}\n";
#}

1;

__END__

=pod

=head1 NAME

DBIx::PgLink::Adapter - DBI wrapper for DBIx::PgLink suite


=head1 SYNOPSIS


    use DBIx::PgLink::Adapter;
    $db = DBIx::PgLink::Adapter->new();

    $db->install_roles(qw/NestedTransaction TraceDBI/);

    $db->install_roles('Reconnect');
    $db->reconnect_retries(10);

    $db->connect("dbi:Pg:host=127.0.0.1;db=postgres", "postgres", "", { RaiseError=>1, AutoCommit=>1 });

    $db->do("SET client_min_messages=INFO");

    $db->dbh->{'pg_enable_utf8'} = 1;

    $st = $db->prepare("SELECT * FROM pg_database");
    $st->execute;
    @row = $st->fetchrow_array;

See also L<DBIx::PgLink>


=head1 DESCRIPTION

Class wraps DBI database handle and provides base for further extending.

Used L<Moose> object system.

=head2 Extending

Extending can be made by subclassing for specific data source type
and/or by adding roles.

Subclasses of C<DBIx::PgLink::Adapter> may implement missing or broken functionality
of DBD driver or underlying driver/database.

Roles (a.k.a. traits or mixins) supply additional functionality
and may be composed in any combinations (in theory).
Adapter can load role:
1) in compile-time via C<with> clause
2) in run-time via C<install_role> subroutine or via direct meta-class manipulation.

Descendant adapter classes and extra roles can have any name.


=head1 DATABASE OBJECT

=head2 METHODS

=over

=item new(%attr)

Default constructor.

=item connect($data_source, $user, $password, \%attr)

Connect to DBI datasource. Returns database handle.

=item C<install_roles>

Apply roles to current object.
Role name can be full package name or just last portion,
which defaults to 'DBIx::PgLink::Roles::' namespace.

=item err errstr state set_err func
data_sources do last_insert_id
selectrow_array selectrow_arrayref selectrow_hashref
selectall_arrayref selectall_hashref selectcol_arrayref
prepare prepare_cached
commit rollback begin_work
disconnect ping
get_info table_info column_info primary_key_info primary_key
foreign_key_info statistics_info tables
type_info_all type_info
quote quote_identifier

Methods of DBI database handle. Can be overrided and extended.

All methods that should return statement handle returns
instance of <DBIx::PgLink::Adapter::st> class instead.

=item C<is_transaction_active>

Utility function. Return true if connection is in transaction.

=item C<format_routine_call>

  $sql = $adapter->format_routine_call($catalog, $schema, $routine, $returns_set, \@args);

Generate SQL query for routine call.

C<$returns_set> is boolean, pass true if routine returns set.

C<\@args> is array of hashes for routine arguments. 
For database that supports named arguments each entry must contains 'arg_name' value.

Generic implementation use 'SELECT' keyword with positional call syntax (PostgreSQL-compatible).

=back


=head2 ATTRIBUTES

B<NOTE:> DBI attributes are not imported. Use C<dbh> attribute for direct access.

=over

=item connector

Weak reference to optional parent of L<DBIx::PgLink::Connector> class.
Read only.

=item dbh

Wrapped DBI database handle.

=back


=head1 STATEMENT OBJECT

Statement object created by C<prepare> database method.

=head2 METHODS

=over

=item err errstr state set_err trace trace_msg func
    bind_param bind_param_inout bind_param_array
    execute execute_array execute_for_fetch
    fetchrow_arrayref fetchrow_array fetchrow_hashref
    fetchall_arrayref fetchall_hashref
    finish rows
    bind_col bind_columns dump_results

Methods of DBI statement handle. Can be overrided and extended.


=back

=head2 ATTRIBUTES

=over

=item parent

Link to I<Adapter> instance. Read only.

=item sth

Wrapped DBI statement handle. Read only.

=back

=head1 Why another DBIx wrapper?

I need this features:

1) Cross-database support
2) Easy extending
3) Mixin/trait-like composing of functionality in run time
4) Set of ready pluggable modules. Particular interest in disconnection handling.

=over

=item DBIx::SQLEngine with DBIx::AnyDBD

+ Good cross-database support
- Too ORM-ish. Overkill for data access from one relational engine to another RDBMS.

=item DBIx::Roles

+ Good set of predifined roles
- No cross-database support

=back

=head1 CAVEATS

Class construction is really SLOW. It is a price for extensibility. See L<Moose::Cookbook::WTF>.

=head1 SEE ALSO

L<DBI>,
L<DBIx::PgLink>
L<Moose>

=head1 AUTHOR

Alexey Sharafutdinov E<lt>alexey.s.v.br@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
