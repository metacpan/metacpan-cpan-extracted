package DBIx::PgLink::Local;

# NOTE: this is general-purpose light-weight non-Moose class
# NOTE: at compile time PL/Perl subroutines are not functional
# NOTE: all non-critical messages logged with INFO severity

use strict;
use warnings;
use Exporter;
use Carp;
use Tie::Cache::LRU;
use DBIx::PgLink::Logger;

our $VERSION = '0.01';

our @ISA = qw(Exporter);
our @EXPORT = qw(pg_dbh);

use constant 'pg_dbh' => bless \(my $anon_scalar), __PACKAGE__; # singleton

use constant 'default_plan_cache_size' => 100;
our %cached_plans;

our $quote_ident_only_if_necessary = 1; # little slower, but no excessive quoting ("foo","bar",etc.)

sub prepare {
  my $self = shift;
  return DBIx::PgLink::Local::st->prepare(@_);
}


sub _attr_types {
  # in  : $attr
  # out : list of types 
  my $self = shift;
  my $attr = shift;
  my $t = ref $attr eq 'HASH' ? $attr->{types} : undef;
  my $r = ref $t;
  return map { uc } (
      $r eq '' && $t ? ($t)   # { types => 'INT4' }
    : $r eq 'SCALAR' ? ($$t)  # { types => \$type }
    : $r eq 'ARRAY'  ? @{$t}  # { types => ['TEXT', 'INT4'] }
    : $r eq 'HASH'   ?        # { types => {1=>'TEXT', 2=>'INT4'} }
      map { $t->{$_} } sort { $a<=>$b } keys %{$t}
    : ()
  );
}


sub _query_key {
  my $self = shift;
  my $query = shift;
  my $attr = shift;
  my @types = $self->_attr_types($attr);
  $query .= "\nparams(" . join(",", @types) . ")" if @types;
  return $query;
}


sub prepare_cached {
  my $self = shift;
  my $query = shift;
  my $attr = shift;

  if ($attr->{no_cache}) {
    return DBIx::PgLink::Local::st->prepare($query, $attr);
  }

  unless (tied %cached_plans) {
    my $cache_size = 
       eval { 
         my $rv = main::spi_exec_query(q/SELECT current_setting('plperl.plan_cache_size')/);
         $rv->{rows}->[0]->{current_setting};
       } # fails if custom_variable_classes not include 'plperl'
       || default_plan_cache_size;
    tie %cached_plans, 'Tie::Cache::LRU', $cache_size;
  }

  my $key = $self->_query_key($query, $attr);

  if (exists $cached_plans{$key}) {
    trace_msg("INFO", "Reuse plan for '$key'") if trace_level >= 3;
    return $cached_plans{$key};
  } else {
    return $cached_plans{$key} = DBIx::PgLink::Local::st->prepare($query, $attr);
  }
}


sub do {
  my $self = shift;
  my $query = shift;
  my $attr = shift;
  $attr->{no_cursor} = 1 unless exists $attr->{no_cursor}; # don't create cursor
  $attr->{no_parse} = 1 unless @_; # skip parsing if no parameter values

  if ($query !~ /^\s*(SELECT|INSERT|UPDATE|DELETE)/) {
    $attr->{no_cache}  = 1 unless exists $attr->{no_cache};  # don't cache plan for DDL
  }

  my $sth = $self->prepare_cached($query, $attr);
  return $sth->execute(@_);
}


sub selectall_arrayref {
  my $self = shift;
  my $query = shift;
  my $attr = shift;
  carp "selectall_arrayref() can return only array of hashes, use Slice=>{} attribute"
    unless defined $attr->{Slice} && ref $attr->{Slice} eq 'HASH';
  # @_ = parameters
  $attr->{no_cursor} = 1;
  my $sth = $self->prepare_cached($query, $attr);
  $sth->execute(@_);
  return $sth->fetchall_arrayref({});
}


sub selectrow_array {
  confess "list context of selectrow_array() does not implemented" if wantarray;
  my $self = shift;
  my $query = shift;
  my $attr = shift;
  # @_ = parameters
  $attr->{no_cursor} = 1;
  my $sth = $self->prepare_cached($query, $attr);
  $sth->execute(@_);
  return $sth->fetchrow_array;
}


sub selectrow_hashref {
  my $self = shift;
  my $query = shift;
  my $attr = shift;
  $attr->{no_cursor} = 1;
  # @_ = parameters
  my $sth = $self->prepare_cached($query, $attr);
  $sth->execute(@_);
  return $sth->fetchrow_hashref;
}


sub selectall_hashref {
  my $self = shift;
  my $query = shift;
  my $key_field = shift;
  my $attr = shift;
  $attr->{Slice} = {};
  my $data = $self->selectall_arrayref($query, $attr, @_);
  my $result;
  for my $row (@{$data}) {
    $result->{$row->{$key_field}} = $row;
  }
  return $result;
}


sub quote {
  my $self = shift;
  my $q = shift;
  return 'NULL' unless defined $q;
  $q =~ s/'/''/g;
  $q = "'$q'";
  if ($q =~ s/\\/\\\\/g) {
    # work with any 'standard_conforming_strings' value
    $q = 'E' . $q; #if pg_server_version() >= 80100;
  }
  return $q;
};


my $quote_ident_sth;

sub quote_identifier {
  my $self = shift;
  my @id = @_;

  # no catalog/attr
  for (@id) { # quote the elements
    next unless defined;
    if ($quote_ident_only_if_necessary) {
      $quote_ident_sth = $self->prepare_cached('SELECT quote_ident($1)', {no_cursor=>1})
        unless $quote_ident_sth;
      $quote_ident_sth->execute($_);
      $_ = $quote_ident_sth->fetchrow_array;
    } else {# quote all
      s/"/""/g; # escape embedded quotes
      $_ = qq{"$_"};
    }
  }  
  # join the dots, ignoring any null/undef elements (ie schema)
  my $quoted_id = join '.', grep { defined } @id;
  return $quoted_id;
}


#------------------------------ utils

sub pg_flush_plan_cache {
  my $self = shift;
  my $key_regex = shift || qr//;
  delete @cached_plans{ grep /$key_regex/, keys %cached_plans };
}


sub pg_to_perl_array {
  my $self = shift;
  my $pg_array = shift; # as string
  return () unless defined $pg_array && $pg_array ne '' && $pg_array ne '{}';

  if ($pg_array =~ /^\{([^{"]*)\}$/) { 

    # simple, one-dimensional array
    return map { $_ eq 'NULL' ? undef : $_ } split ',', $1;

  } else { 

    # quoted or multidimensional array
    # not fast, but reliable SQL conversion
    # WARNING: treats any array as TEXT[]

    # get dimensions of array
    my $dim = $self->selectrow_array('SELECT array_dims($1)', {types=>'_TEXT'}, $pg_array);

    if ($dim =~ /^\[\d+:\d+\]$/) { 

      # single dimension, get set of scalars
      my $a = $self->selectall_arrayref(<<'END_OF_SQL', {Slice=>{}, types=>'_TEXT'}, $pg_array);
SELECT $1[i] as i
FROM pg_catalog.generate_series(1, array_upper($1, 1)) as a(i)
END_OF_SQL

      return map { $_->{i} } @{$a};

    } else {

      # nested array, get set of array slices
      my $a = $self->selectall_arrayref(<<'END_OF_SQL', {Slice=>{}, types=>'_TEXT'}, $pg_array);
SELECT $1[i:i] as i
FROM pg_catalog.generate_series(1, array_upper($1, 1)) as a(i)
END_OF_SQL

      return map { 
        my $i = $_->{i}; 
        $i =~ /^\{(.*)\}$/; # chop extra {}
        my @b = $self->pg_to_perl_array($1);
        \@b;
      } @{$a};

    }
  }
}


sub pg_from_perl_array {
  my $self = shift;
  return 
    '{' 
    . join(',', 
      map { 
        (ref $_ eq 'ARRAY') # nested array
          ? $self->pg_from_perl_array(@{$_})
          : defined $_
            ?  do { # quote all values
              my $a = $_;
              $a =~ s/"/\\"/g;
              '"' . $a . '"'
            }
            : 'NULL'
      } @_
    ) 
    . '}';
}


# HASH pseudotype, store hash as TEXT[] as 'key','value' pairs
sub pg_to_perl_hash {
  my ($self, $pg_array) = @_;
  my %result = pg_dbh->pg_to_perl_array($pg_array);
  return \%result;
}

sub pg_from_perl_hash {
  my ($self, $hashref) = @_;
  return $self->pg_from_perl_array(%{$hashref});
}


sub pg_to_perl_encoding { 
  my $self = shift;
  my $enc = shift;
  $enc =~ s/^WIN(\d+)$/cp$1/;
  $enc = {
    #pg          #perl
    SQL_ASCII => 'ascii',
    UNICODE   => 'utf8',
    KOI8      => 'koi8-r',
    ALT       => 'cp866',
    WIN       => 'cp1251',
    #TODO
  }->{$enc} || $enc;
  return $enc;
}

sub pg_from_perl_boolean {
  my $self = shift;
  my $b = shift;
  return defined $b ? $b ? 't' : 'f' : undef;
}

sub pg_to_perl_boolean {
  my $self = shift;
  my $b = shift;
  return defined $b ? $b eq 't' ? '1' : '0' : undef;
}


my $pg_server_version; # cached
sub pg_server_version {
  my $self = shift;
  return $pg_server_version if $pg_server_version;
  my $ver = pg_dbh->selectrow_array("SELECT version()");
  my ($major, $minor, $release) = $ver =~ /^PostgreSQL (\d+)\.(\d+)\.(\d+)/;
  return $pg_server_version = $major*10000+$minor*100+$release;
}


my $pg_current_database; # cached
sub pg_current_database {
  my $self = shift;
  return $pg_current_database 
    || ( $pg_current_database = pg_dbh->selectrow_array("SELECT current_database()"));
}

# session_user, not cached because can be changed by SET SESSION AUTHORIZATION
sub pg_session_user {
  my $self = shift;
  return scalar(pg_dbh->selectrow_array("SELECT session_user"));
}


1;




package DBIx::PgLink::Local::st;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use DBIx::PgLink::Logger;

BEGIN {
  # alias pg_dbh constant
  no strict 'refs';
  *pg_dbh = \&DBIx::PgLink::Local::pg_dbh;
}


sub _find_placeholders {
  # in  : $_[0] = query text
  # out : array of placeholder numbers, changed query

  # WARNING: false placeholders in literals and comments are detected

  # $1, $2, ... placeholders, PostgreSQL default
  if ($_[0] =~ /\$\d/) { 
    my %uniq;
    @uniq{ $_[0] =~ m/\$(\d+)/g } = (); 
    return sort { $a <=> $b } keys %uniq;
  } 
  # ? placeholders
  elsif ($_[0] =~ /[?]/) { 
    my $cnt=0;
    # replace ? to $n in-place
    $_[0] =~ s/[?]/'$' . ++$cnt/eg;  
    return (1..$cnt);
  }
  return ();
}

our %TYPE_ALIAS = (
  'int'     => 'INT4',
  'integer' => 'INT4',
  'real'    => 'FLOAT4',
  'float'   => 'FLOAT8',
  'double'  => 'FLOAT8',
  'double precision' => 'FLOAT8',
  'boolean' => 'BOOL',
);
$TYPE_ALIAS{uc $_} = $TYPE_ALIAS{$_} for keys %TYPE_ALIAS;
# standard type aliases also allowed in Pg-8.3

# constructor
sub prepare {
  my ($proto, $query, $attr) = @_;
  $proto = ref $proto || $proto;
  $attr = ref $attr eq 'HASH' ? $attr : {};

  my @types = pg_dbh->_attr_types($attr);

  my $data = {
    Attr      => $attr,
    Statement => $query,
    Types     => \@types,
  };

  my @mapped_types = ();
  if (@types) { 
    for my $t (@types) {
      # spi_prepare do not understand TYPE[] syntax for array
      my ($array, $base) = (0, $t);
      if ($t =~ /^_(.*)$/ || $t =~ /^(.*)\[\]$/) {
        ($array, $base) = (1, $1);
      }
      $base = $TYPE_ALIAS{$base} if exists $TYPE_ALIAS{$base};
      $t = $array ? '_' . $base : $base;

      # special hash pseudotype
      push @mapped_types, $t eq 'HASH' ? '_TEXT' : $t;
    }
  } elsif (!$attr->{no_parse}) { 
    # no types specified, defaults all parameters to TEXT
    # also replace '?' to '$1' in-place
    @mapped_types = map { 'TEXT' } _find_placeholders($query);
  }

  if (trace_level >= 3) {
    trace_msg("INFO", "spi_prepare: $query" 
      . (@types ? "\nBind types: " . join(",", @mapped_types) : "") )
  }

  eval {
    $data->{Plan} = main::spi_prepare($query, @mapped_types);
  };
  confess "spi_prepare failed for $query: $@" if $@ || !$data->{Plan};
  trace_msg("INFO", "  plan=$data->{Plan}") if trace_level >= 3;

  $data->{Boolean} = _attr_arrayref($attr->{boolean});
  $data->{Array}   = _attr_arrayref($attr->{array});
  $data->{Hash}    = _attr_arrayref($attr->{hash});

  return bless $data, $proto;
}


sub _attr_arrayref {
  my $r = shift;
  return [] unless defined $r;
  if (ref $r eq 'ARRAY') {
    return $r;
  } elsif (ref $r eq 'HASH') {
    my @keys = keys %{$r};
    return \@keys;
  }
  return [];
}


sub DESTROY {
  my $self = shift;
  $self->finish;
}


sub finish {
  my $self = shift;
  if (defined $self->{Cursor}) {
    trace_msg("INFO", "spi_close_cursor ($self->{Cursor})") 
      if trace_level >= 3;
    main::spi_cursor_close($self->{Cursor});
  }
  delete @{$self}{qw/Cursor Result Pos/};
}


sub _convert_params {
  my $self = shift;
  return unless @{$self->{Types}};
  my $i = 0;
  for my $param (@_) {
    my $type = $self->{Types}->[$i++];
    if ($type eq 'BOOL') {
      $param = pg_dbh->pg_from_perl_boolean($param);
    } elsif ($type =~ '^_' && ref $param eq 'ARRAY') {
      $param = pg_dbh->pg_from_perl_array(@{$param});
    } elsif ($type eq 'HASH' && ref $param eq 'HASH') {
      $param = pg_dbh->pg_from_perl_hash($param);
    }
  }
}


sub _convert_row {
  my $self = shift;  
  my $row  = shift;  
  return unless $row;
  for my $field (@{$self->{Boolean}}) {
    next unless exists $row->{$field};
    $row->{$field} = pg_dbh->pg_to_perl_boolean($row->{$field});
  }
  for my $field (@{$self->{Array}}) {
    next unless exists $row->{$field};
    my @arr= pg_dbh->pg_to_perl_array($row->{$field});
    $row->{$field} = \@arr;
  }
  for my $field (@{$self->{Hash}}) {
    next unless exists $row->{$field};
    $row->{$field} = pg_dbh->pg_to_perl_hash($row->{$field});
  }
}


sub execute {
  my $self = shift;
    
  $self->finish;

  if ($self->{Attr}->{no_cursor}) {

    # does not use cursor, fetch all rows at once

    if (trace_level >= 4) {
      local $" = ',';
      no warnings;
      trace_msg("INFO", "spi_execute_prepared ($self->{Plan} Bind: @_)") 
    }

    my @param_values = @_;
    $self->_convert_params(@param_values);

    my $rv = eval {
      main::spi_exec_prepared($self->{Plan}, @param_values);
    };
    if ($@) {
      confess "spi_exec_prepared failed: $@\nStatement: $self->{Statement} with "
        . join(",", map { defined $_ ? $_ : '<NULL>' } @param_values);
    }

    return unless ref $rv eq 'HASH';

    $self->{Result} = $rv;
    trace_msg("INFO", "spi_execute_prepared results:\n" . Dumper($rv)) 
      if trace_level >= 4;
    my $result = $rv->{processed};
    $result = '0E0' if defined $result && $result eq '0';

    return $result;

  } else { 
  
    # open cursor

    if (trace_level >= 4) {
      local $" = ',';
      trace_msg("INFO", "spi_query_prepared ($self->{Plan}, Bind: @_)") 
    }

    undef $self->{Cursor};

    my @param_values = @_;
    $self->_convert_params(@param_values);

    $self->{Cursor} = eval {
      main::spi_query_prepared($self->{Plan}, @param_values)
    };
    confess "spi_query_prepared failed: $@\nStatement: $self->{Statement} with " . join(",", @param_values) 
      if $@ || !defined $self->{Cursor};

    return -1; # cannot get row count before fetching all rows
  }

}


sub fetchall_arrayref {
  my $self = shift;
  my $attr = shift;
  carp "fetchall_arrayref() can return only array of hashes, use {} attribute"
    unless defined $attr && ref $attr eq 'HASH';
  if (defined (my $rv = $self->{Result})) {
    $self->_convert_row($_) for @{$self->{Result}->{rows}};
    return $rv->{rows};
  }
  elsif (defined $self->{Cursor}) {
    my @result = ();
    trace_msg("INFO", "fetch all rows by spi_fetchrow($self->{Plan})")
      if trace_level >= 3;
    while (defined (my $row = main::spi_fetchrow($self->{Cursor}))) {
      $self->_convert_row($row);
      push @result, $row;
    }
    return \@result;
  }
  else {
    trace_msg("INFO", "fetch failed: no statement executing for $self->{Statement}") 
      if trace_level >= 3;
  }
}


sub fetchrow_hashref {
  my $self = shift;
  my $result;
  if (defined (my $rv = $self->{Result})) {
    $result = $rv->{rows}->[ $self->{Pos}++ ];
  }
  elsif (defined $self->{Cursor}) {
    trace_msg("INFO", " spi_fetchrow($self->{Cursor})")
      if trace_level >= 4;
    $result = main::spi_fetchrow($self->{Cursor});
  }
  else { # not error
    trace_msg("WARNING", "fetch failed: no statement executing for $self->{Statement}") 
      if trace_level >= 4;
  }
  trace_msg("INFO", "fetchrow_hashref result:\n" . Dumper($result)) 
    if trace_level >= 4;
  $self->_convert_row($result);
  return $result;
}


sub fetchrow_array {
  confess "list context of fetchrow_array() does not implemented" if wantarray;
  my $self = shift;
  my $row = $self->fetchrow_hashref;
  return defined $row ? (each %{$row})[1] : undef;
}

1;

__END__

=head1 NAME

DBIx::PgLink::Local - DBI emulation for local data access in PostgreSQL PL/Perl function

=head1 SYNOPSIS

I<PostgreSQL script>

  CREATE FUNCTION fn() RETURNS ... LANGUAGE plperlu AS $$

    ...

    use DBIx::PgLink::Local;

    $q = pg_dbh->prepare( q<SELECT 'Hello, ' || ? as foo> );
    $q->execute("world");
    while (my $row = $q->fetchrow_hashref) {
      elog 'INFO', $row->{foo}; # prints 'Hello, world'
    }

    ...

    $v = pg_dbh->selectrow_array( 
      'SELECT $1 * $1 as bar',  # query string
      { types=>['INT4'] } ),    # attributes
      3                         # parameter values
    ); 
    elog 'INFO', $v; # prints '9'

    ...

  $$

=head1 DESCRIPTION

B<WARNING: this module works only in PostgreSQL functions written in I<PL/PerlU> language
in PostgreSQL server version 8.2 or higher.>

DBIx::PgLink::Local is a wrapper around PL/Perl Server Programming Interface (SPI) functions.
Module provides only basic functions of L<DBI>. 
For full DBI-compatible driver look at L<DBD::PgSPI>.

Module manage prepared statements and cache query plans.
It is not depend on other L<DBIx::PgLink> code (except L<DBIx::PgLink::Logger>) 
and can be used in any PL/Perl function.

=head1 SUBROUTINES

=over

=item C<pg_dbh>

Returns singleton instance of class DBIx::PgLink::Local. Exported by default.

=back


=head1 METHODS

=over

=item C<quote>

  $sql = pg_dbh->quote($value);

Quote a string literal for use as a literal value in an SQL statement, 
by escaping single quote and backslash characters and adding the single quotes.

=item C<quote_identifier>

  $sql = pg_dbh->quote_identifier( $name );
  $sql = pg_dbh->quote_identifier( $schema, $object );

Quote an identifier (table name etc.) for use in an SQL statement, 
by escaping double quote and adding double quotes.

=item C<prepare>

    $sth = pg_dbh->prepare($statement);
    $sth = pg_dbh->prepare($statement, \%attr);

Prepares a statement for later execution by the database
engine and returns a reference to a statement handle. 
Statement handle is object containing query plan.

Supports $n ("dollar sign numbers") and ? (question mark) placeholder styles.
$n-style is PostgreSQL default and preferred over quotation marks.

Wrapped C<spi_prepare()> function cannot infer parameter data type from the context,
although SQL command C<PREPARE> can.
If no parameter types specified, C<prepare> implicitly detect placeholders 
and assign 'TEXT' type to all of them.

C<prepare> attributes:

=over

=item C<types>

Supply explicit data type names for parameters in C<types> attribute as array-ref:

    $sth = pg_dbh->prepare(
      'SELECT * FROM foo WHERE bar=$1 and baz=$2', 
      { types => [qw/TEXT INT4/] }
    );

Type names are case insensitive.
Examples: 'TEXT', 'INT4', 'INT8', 'FLOAT4', 'FLOAT8'.
In addition 'int', 'integer' are aliased to 'INT4', 'double' to 'FLOAT8'.

B<Only "dollar sign number" placeholders can be used with explicit types.>

See alse "Placeholders" in L<DBD::Pg>.

=item C<boolean>

Array-ref containing field names in result set with boolean type.
Converts PostgreSQL boolean values to Perl ('f' -> 0, 't' -> 1).

Also accepted hashref with field name as key.

=item C<array>

Array-ref containing field names in result set with array type.
Converts PostgreSQL array values to Perl array.

Also accepted hashref with field name as key.

=item C<no_cursor>

Boolean: do not create cursor and fetch all data at once. 
Automatically set for any not SELECT/INSERT/UPDATE/DELETE query.

=item C<no_cache>

Boolean: do not save query plan.
Automatically set for any not SELECT/INSERT/UPDATE/DELETE query.

=item C<no_parse>

Boolean: make no attempt to find placeholders in query and replace '?' marks.
Automatically set for C<do> method with no parameter values.

=back

=item C<prepare_cached>

    $sth = pg_dbh->prepare_cached($statement);
    $sth = pg_dbh->prepare_cached($statement, \%attr);

Like L</prepare> except that the plan for statement will be
stored in a global (session) hash. If another call is made to
C<prepare_cached> with the same C<$query> value,
then the corresponding cached plan will be used.
B<Statement handles are not cached>, it is safe to mix 
different C<prepare_cached> and C<execute> with the same query string.

Cache is managed by LRU algorithm. Default cache size is 100.
Cache size can be configured via PostgreSQL run-time parameter B<plperl.plan_cache_size>.
See I<Customized Options> in PostgreSQL Manual for example how to enable I<plperl> custom variable class.

=item C<do>

  $rows = pg_dbh->do($statement)
  $rows = pg_dbh->do($statement, \%attr)
  $rows = pg_dbh->do($statement, \%attr, @bind_values)

Prepare and execute a single statement. 
Returns the number of rows affected. Plan is cached.

=item C<selectrow_array>

  $scalar = pg_dbh->selectall_arrayref($statement)
  $scalar = pg_dbh->selectall_arrayref($statement, \%attr)
  $scalar = pg_dbh->selectall_arrayref($statement, \%attr, @bind_values)

This utility method combines C<prepare_cached>, C<execute> and C<fetchrow_hashref> into a single call.
In scalar context returns single value from first row of resultset.
If called for a statement handle that has more than one column, it is undefined whether column will be return. 

NOTE: in list context always dies, because of internal limitation.


=item C<selectrow_hashref>

  $hash_ref = $dbh->selectrow_hashref($statement);
  $hash_ref = $dbh->selectrow_hashref($statement, \%attr);
  $hash_ref = $dbh->selectrow_hashref($statement, \%attr, @bind_values);

This utility method combines C<prepare_cached>, C<execute> and C<fetchrow_hashref> into a single call.
It returns the first row of data from the statement.

=item C<selectall_arrayref>

  $ary_ref = pg_dbh->selectall_arrayref($statement)
  $ary_ref = pg_dbh->selectall_arrayref($statement, \%attr)
  $ary_ref = pg_dbh->selectall_arrayref($statement, \%attr, @bind_values)

This utility method combines C<prepare_cached>, C<execute> and C<fetchall_arrayref> into a single call. 
It returns a reference to an array containing a reference to a hash for each row of data fetched.

Note that unlike DBI C<selectall_arrayref> returns arrayref of B<hashes>.

=item C<selectall_hashref>

  $hash_ref = pg_dbh->selectall_hashref($statement, $key_field)
  $hash_ref = pg_dbh->selectall_hashref($statement, $key_field, \%attr)
  $hash_ref = pg_dbh->selectall_hashref($statement, $key_field, \%attr, @bind_values)

This utility method combines C<prepare_cached>, C<execute> and C<fetchrow_hashref> into a single call. 
It returns a reference to a hash containing one entry, at most, for each row, as returned by fetchall_hashref().

=back

=head2 PostgreSQL-only methods

=over

=item C<pg_flush_plan_cache>

  pg_dbh->pg_flush_plan_cache;
  pg_dbh->pg_flush_plan_cache($regex);

Free all or selected prepared query plans from cache. Use after changing of database schema.

=item C<pg_to_perl_array>

  @arr = pg_dbh->pg_to_perl_array('{1,2,3}');

Convert text representation of PostgreSQL array to Perl array.

=item C<pg_from_perl_array>

  $string = pg_dbh->pg_from_perl_array(1,2,3,undef,'hello'); 
  # returns '{"1","2","3",NULL,"hello"}'

Convert Perl array to PostgreSQL array literal.

=item C<pg_to_perl_hash>

  $hashref = pg_dbh->pg_to_perl_hash('{foo,1,bar,2}');

Convert text representation of PostgreSQL array to Perl hash.

This method is particularly useful for PL/Perl array argument conversion,
for PL/Perl stringify it.

=item C<pg_from_perl_hash>

  $string = pg_dbh->pg_from_perl_hash({foo=>1,bar=>2}); 
  # returns '{foo,1,bar,2}'

Convert Perl hash reference to PostgreSQL array literal.

=item C<pg_to_perl_encoding>

Convert name of PostgreSQL encoding to Perl encoding name. See L<Encode>.

=item C<pg_server_version>

Indicates which version of local PostgreSQL that hosts PL/Perl function.
Returns a number with major, minor, and revision together; version 8.2.5 would be 80205

=item C<pg_current_database>

Returns name of local database PostgreSQL that hosts PL/Perl function.

=item C<pg_session_user>

Returns PostgreSQL session user name. 
See I<System Information Functions> chapter of PostgreSQL Manual.

=back


=head1 STATEMENT METHODS

=over

=item C<execute>

  $q->execute;
  $q->execute(@values);

Execute prepared statement. 

When statement prepared with true value of C<no_cursor> attribute, all rows are fetched at once 
(if it is data retrieving operation) and C<execute> returns number of proceeded rows.

When attribute C<no_cursor> is not set, C<execute> open cursor and fetch row-by-row. 
In this mode method always returns -1 because number of affected rows can not be known.

Wrapper of C<spi_exec_prepared> / C<spi_query_prepared>.

=item C<fetchrow_hashref>

  $hash_ref = $q->fetchrow_hashref;

Fetches the next row of data and returns a reference to an hash
holding the field values.
If there are no more rows or if an error occurs, then C<fetchrow_hashref>
returns an C<undef>.

=item C<fetchrow_array>

  $scalar = $q->fetchrow_array;

Fetches the next row of data and return one field value.

NOTE: in list context always dies, because of internal limitation.

=item C<fetchall_arrayref>

  $row_aref = $q->fetchall_arrayref;

The method can be used to fetch all the data to be returned 
from a prepared and executed statement handle. 
It returns a reference to an array that contains one reference per row.
Note that unlike DBI C<fetchall_arrayref> returns arrayref of B<hashes>.

=item C<finish>

  $q->finish;

Indicate that no more data will be fetched from this statement handle 
before it is either executed again or destroyed.

Wrapper of C<spi_cursor_close>.

=back


=head1 CAVEATS

=over

=item *

SQL parsing for parameters in C<prepare> is dumb.

Use explicit types if query contains string like '$1' or '?'
in literal, identifier or comment.

=item *

Full set of selectI<XXX> and fetchI<XXX> methods is not implemented.

In PL/Perl data access layer every data row (tuple) converted to hash, 
and there is no easy way to restore original column order.

=item *

C<selectall_arrayref> and C<fetchall_arrayref> always returns reference to array of hashes

=item *

C<selectrow_array> and C<fetchrow_array> works in scalar context only.

=item *

Data fetching slower than PL/PGSQL.

The tuple->hash conversion take extra time and memory.

=item *

No automatic plan invalidation.

Use C<pg_flush_plan_cache> (or reconnect) after database schema changes.

=item *

Array conversion suppose that C<array_nulls> variable is ON. 

=item *

Lot ot this module code will be obsolete when (and if) L<DBD::PgSPI> 
starts support real prepared statements.

=back


=head1 SEE ALSO

L<DBI>, L<DBD::Pg>, L<Tie::Cache::LRU>, PostgreSQL Manual


=head1 AUTHOR

Alexey Sharafutdinov E<lt>alexey.s.v.br@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
