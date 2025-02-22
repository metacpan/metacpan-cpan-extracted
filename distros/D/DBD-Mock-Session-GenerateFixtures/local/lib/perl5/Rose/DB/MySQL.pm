package Rose::DB::MySQL;

use strict;

use Carp();

use DateTime::Format::MySQL;
use SQL::ReservedWords::MySQL();

TRY:
{
  local $@;
  eval { require DBD::mysql }; # Ignore errors
}

use Rose::DB;

our $VERSION = '0.774';

our $Debug = 0;

use Rose::Class::MakeMethods::Generic
(
  inheritable_scalar => 
  [
    'supports_schema',
    'coerce_autoincrement_to_serial',
  ]
);

__PACKAGE__->supports_schema(1);
__PACKAGE__->coerce_autoincrement_to_serial(1);

#
# Object methods
#

sub registration_schema { shift->database }

sub build_dsn
{
  my($self_or_class, %args) = @_;

  my %info;

  $info{'database'} = $args{'db'} || $args{'database'};
  $info{'host'}     = $args{'host'};
  $info{'port'}     = $args{'port'};

  return
    "dbi:mysql:" . 
    join(';', map { "$_=$info{$_}" } grep { defined $info{$_} }
              qw(database host port));
}

sub dbi_driver { 'mysql' }

sub mysql_auto_reconnect     { shift->dbh_attribute_boolean('mysql_auto_reconnect', @_) }
sub mysql_client_found_rows  { shift->dbh_attribute_boolean('mysql_client_found_rows', @_) }
sub mysql_compression        { shift->dbh_attribute_boolean('mysql_compression', @_) }
sub mysql_connect_timeout    { shift->dbh_attribute_boolean('mysql_connect_timeout', @_) }
sub mysql_embedded_groups    { shift->dbh_attribute('mysql_embedded_groups', @_) }
sub mysql_embedded_options   { shift->dbh_attribute('mysql_embedded_options', @_) }
sub mysql_local_infile       { shift->dbh_attribute('mysql_local_infile', @_) }
sub mysql_multi_statements   { shift->dbh_attribute_boolean('mysql_multi_statements', @_) }
sub mysql_read_default_file  { shift->dbh_attribute('mysql_read_default_file', @_) }
sub mysql_read_default_group { shift->dbh_attribute('mysql_read_default_group', @_) }
sub mysql_socket             { shift->dbh_attribute('mysql_socket', @_) }
sub mysql_ssl                { shift->dbh_attribute_boolean('mysql_ssl', @_) }
sub mysql_ssl_ca_file        { shift->dbh_attribute('mysql_ssl_ca_file', @_) }
sub mysql_ssl_ca_path        { shift->dbh_attribute('mysql_ssl_ca_path', @_) }
sub mysql_ssl_cipher         { shift->dbh_attribute('mysql_ssl_cipher', @_) }
sub mysql_ssl_client_cert    { shift->dbh_attribute('mysql_ssl_client_cert', @_) }
sub mysql_ssl_client_key     { shift->dbh_attribute('mysql_ssl_client_key', @_) }
sub mysql_use_result         { shift->dbh_attribute_boolean('mysql_use_result', @_) }
sub mysql_bind_type_guessing { shift->dbh_attribute_boolean('mysql_bind_type_guessing', @_) }

sub mysql_enable_utf8
{
  my($self) = shift;
  $self->dbh->do('SET NAMES utf8')  if(@_ && $self->has_dbh);
  $self->dbh_attribute_boolean('mysql_enable_utf8', @_)
}

sub mysql_enable_utf8mb4
{
  my($self) = shift;
  $self->dbh->do('SET NAMES utf8mb4')  if(@_ && $self->has_dbh);
  $self->dbh_attribute_boolean('mysql_enable_utf8mb4', @_)
}

sub database_version
{
  my($self) = shift;
  return $self->{'database_version'}  if(defined $self->{'database_version'});

  my $vers = $self->dbh->get_info(18); # SQL_DBMS_VER

  # Convert to an integer, e.g., 5.1.13 -> 5001013
  if($vers =~ /^(\d+)\.(\d+)(?:\.(\d+))?/)
  {
    $vers = sprintf('%d%03d%03d', $1, $2, $3 || 0);
  }

  return $self->{'database_version'} = $vers;
}

sub init_dbh
{
  my($self) = shift;

  $self->{'supports_on_duplicate_key_update'} = undef;

  my $method = ref($self)->parent_class . '::init_dbh';

  no strict 'refs';
  return $self->$method(@_);
}

sub max_column_name_length { 64 }
sub max_column_alias_length { 255 }

sub quote_column_name 
{
  my $name = $_[1];
  $name =~ s/`/``/g;
  return qq(`$name`);
}

sub quote_table_name
{
  my $name = $_[1];
  $name =~ s/`/``/g;
  return qq(`$name`);
}

sub list_tables
{
  my($self, %args) = @_;

  my $types = $args{'include_views'} ? "'TABLE','VIEW'" : 'TABLE';
  my @tables;

  my $schema = $self->schema;

  $schema = $self->database  unless(defined $schema);

  my $error;

  TRY:
  {
    local $@;

    eval
    {
      my $dbh = $self->dbh or die $self->error;

      local $dbh->{'RaiseError'} = 1;
      local $dbh->{'FetchHashKeyName'} = 'NAME';

      my $sth = $dbh->table_info($self->catalog, $schema, '%', $types);

      $sth->execute;

      while(my $table_info = $sth->fetchrow_hashref)
      {
        push(@tables, $self->unquote_table_name($table_info->{'TABLE_NAME'}));
      }
    };

    $error = $@;
  }

  if($error)
  {
    Carp::croak "Could not list tables from ", $self->dsn, " - $error";
  }

  return wantarray ? @tables : \@tables;
}

sub init_date_handler { DateTime::Format::MySQL->new }

sub insertid_param { 'mysql_insertid' }

sub last_insertid_from_sth { $_[1]->{'mysql_insertid'} }

sub format_table_with_alias
{
  my($self, $table, $alias, $hints) = @_;

  my $version = $self->database_version;

  if($hints && $version >= 3_023_012)
  {
    my $sql = "$table $alias ";

    # "ignore index()" and "use index()" were added in 3.23.12 (07 March 2000)
    # "force index()" was added in 4.0.9 (09 January 2003)
    my @types = (($version >= 4_000_009 ? 'force' : ()), qw(use ignore));

    foreach my $index_hint_type (@types)
    {
      my $key = "${index_hint_type}_index";

      if($hints->{$key})
      {
        $sql .= uc($index_hint_type) . ' INDEX (';

        if(ref $hints->{$key} eq 'ARRAY')
        {
          $sql .= join(', ', @{$hints->{$key}});
        }
        else { $sql .= $hints->{$key} }

        $sql .= ')';

        # Only one of these hints is allowed
        last;
      }
    }

    return $sql;
  }

  return "$table $alias";
}

sub format_select_start_sql
{
  my($self, $hints) = @_;

  return 'SELECT'  unless($hints);

  return 'SELECT ' . ($hints->{'comment'} ? "/* $hints->{'comment'} */" : '') .
    join(' ', (map { $hints->{$_} ? uc("sql_$_") : () }
      qw(small_result big_result buffer_result cache no_cache calc_found_rows)),
      (map { $hints->{$_} ? uc($_) : () } qw(high_priority straight_join)));
}

sub format_select_lock
{
  my($self, $class, $lock, $tables_list) = @_;

  $lock = { type => $lock }  unless(ref $lock);

  $lock->{'type'} ||= 'for update'  if($lock->{'for_update'});

  my %types =
  (
    'for update' => 'FOR UPDATE',
    'shared'     => 'LOCK IN SHARE MODE',
  );

  my $sql = $types{$lock->{'type'}}
    or Carp::croak "Invalid lock type: $lock->{'type'}";

  return $sql;
}

sub validate_date_keyword
{
  no warnings;
  !ref $_[1] && ($_[1] =~ /^(?:(?:now|cur(?:date|time)|sysdate)\(\)|
    current_(?:time|date|timestamp)(?:\(\))?|0000-00-00)$/xi ||
    ($_[0]->keyword_function_calls && $_[1] =~ /^\w+\(.*\)$/));
}

sub validate_datetime_keyword
{
  no warnings;
  !ref $_[1] && ($_[1]  =~ /^(?:(?:now|cur(?:date|time)|sysdate)\(\)|
    current_(?:time|date|timestamp)(?:\(\))?|0000-00-00[ ]00:00:00)$/xi ||
    ($_[0]->keyword_function_calls && $_[1] =~ /^\w+\(.*\)$/));
}

sub validate_timestamp_keyword
{
  no warnings;
  !ref $_[1] && ($_[1] =~ /^(?:(?:now|cur(?:date|time)|sysdate)\(\)|
    current_(?:time|date|timestamp)(?:\(\))?|0000-00-00[ ]00:00:00|00000000000000)$/xi ||
    ($_[0]->keyword_function_calls && $_[1] =~ /^\w+\(.*\)$/));
}

*format_timestamp = \&Rose::DB::format_datetime;

sub parse_bitfield
{
  my($self, $val, $size, $from_db) = @_;

  if(ref $val)
  {
    if($size && $val->Size != $size)
    {
      return Bit::Vector->new_Bin($size, $val->to_Bin);
    }

    return $val;
  }

  no warnings 'uninitialized';
  if($from_db && $val =~ /^\d+$/)
  {
    return Bit::Vector->new_Dec($size || (length($val) * 4), $val);
  }
  elsif($val =~ /^[10]+$/)
  {
    return Bit::Vector->new_Bin($size || length $val, $val);
  }
  elsif($val =~ /^\d*[2-9]\d*$/)
  {
    return Bit::Vector->new_Dec($size || (length($val) * 4), $val);
  }
  elsif($val =~ s/^0x// || $val =~ s/^X'(.*)'$/$1/ || $val =~ /^[0-9a-f]+$/i)
  {
    return Bit::Vector->new_Hex($size || (length($val) * 4), $val);
  }
  elsif($val =~ s/^B'([10]+)'$/$1/i)
  {
    return Bit::Vector->new_Bin($size || length $val, $val);
  }
  else
  {
    return undef;
    #return Bit::Vector->new_Bin($size || length($val), $val);
  }
}

sub format_bitfield 
{
  my($self, $vec, $size) = @_;

  $vec = Bit::Vector->new_Bin($size, $vec->to_Bin)  if($size);

  # MySQL 5.0.3 or later requires this crap...
  if($self->database_version >= 5_000_003)
  {
    return q(b') . $vec->to_Bin . q('); # 'CAST(' . $vec->to_Dec . ' AS UNSIGNED)';
  }

  return hex($vec->to_Hex);
}

sub validate_bitfield_keyword { defined $_[1] ? 1 : 0 }

sub should_inline_bitfield_value
{
  # MySQL 5.0.3 or later requires this crap...
  return $_[0]->{'should_inline_bitfield_value'} ||= 
    (shift->database_version >= 5_000_003) ? 1 : 0;
}

sub select_bitfield_column_sql
{
  my($self, $column, $table) = @_;

  # MySQL 5.0.3 or later requires this crap...
  if($self->database_version >= 5_000_003)
  {
    return q{CONCAT("b'", BIN(} . 
           $self->auto_quote_column_with_table($column, $table) .
           q{ + 0), "'")};
  }
  else
  {
    return $self->auto_quote_column_with_table($column, $table) . q{ + 0};
  }
}

sub parse_set
{
  my($self) = shift;

  return $_[0]  if(ref $_[0] eq 'ARRAY');

  if(@_ > 1 && !ref $_[1])
  {
    pop(@_);
    return [ @_ ];
  }

  my $val = $_[0];

  return undef  unless(defined $val);

  my @set = split(/,/, $val);

  return \@set;
}

sub format_set
{
  my($self) = shift;

  my @set = (ref $_[0]) ? @{$_[0]} : @_;

  return undef  unless(@set && defined $set[0]);

  return join(',', map 
  {
    if(!defined $_)
    {
      Carp::croak 'Undefined value found in array or list passed to ',
                  __PACKAGE__, '::format_set()';
    }
    else { $_ }
  }
  @set);
}

sub refine_dbi_column_info
{
  my($self, $col_info) = @_;

  my $method = ref($self)->parent_class . '::refine_dbi_column_info';

  no strict 'refs';
  $self->$method($col_info);

  if($col_info->{'TYPE_NAME'} eq 'timestamp' && defined $col_info->{'COLUMN_DEF'})
  {
    if($col_info->{'COLUMN_DEF'} eq '0000-00-00 00:00:00' || 
       $col_info->{'COLUMN_DEF'} eq '00000000000000')
    {
      # MySQL uses strange "all zeros" default values for timestamp fields.
      # We'll just ignore them, since MySQL will use them internally no
      # matter what we do.
      $col_info->{'COLUMN_DEF'} = undef;
    }
    elsif($col_info->{'COLUMN_DEF'} eq 'CURRENT_TIMESTAMP')
    {
      # Translate "current time" value into something that our date parser
      # will understand.
      #$col_info->{'COLUMN_DEF'} = 'now';

      # Actually, let the database handle this.
      $col_info->{'COLUMN_DEF'} = undef;
    }
  }

  # Put valid SET and ENUM values in standard keys
  if($col_info->{'TYPE_NAME'} eq 'set')
  {

    $col_info->{'RDBO_SET_VALUES'} = $col_info->{'mysql_values'};
  }
  elsif($col_info->{'TYPE_NAME'} eq 'enum')
  {
    $col_info->{'RDBO_ENUM_VALUES'} = $col_info->{'mysql_values'};
  }

  # Consider (big)int autoincrement to be (big)serial
  if($col_info->{'mysql_is_auto_increment'} &&
     ref($self)->coerce_autoincrement_to_serial)
  {
    if($col_info->{'TYPE_NAME'} eq 'int')
    {
      $col_info->{'TYPE_NAME'} = 'serial';
    }
    elsif($col_info->{'TYPE_NAME'} eq 'bigint')
    {
      $col_info->{'TYPE_NAME'} = 'bigserial';
    }
  }

  return;
}

sub supports_arbitrary_defaults_on_insert { 1 }
sub likes_redundant_join_conditions       { 1 }

sub supports_on_duplicate_key_update
{
  my($self) = shift;

  if(defined $self->{'supports_on_duplicate_key_update'})
  {
    return $self->{'supports_on_duplicate_key_update'};
  }

  if($self->database_version >= 4_001_000)
  {
    return $self->{'supports_on_duplicate_key_update'} = 1;
  }

  return $self->{'supports_on_duplicate_key_update'} = 0;
}

sub supports_select_from_subselect
{
  my($self) = shift;

  if(defined $self->{'supports_select_from_subselect'})
  {
    return $self->{'supports_select_from_subselect'};
  }

  if($self->database_version >= 5_000_045)
  {
    return $self->{'supports_select_from_subselect'} = 1;
  }

  return $self->{'supports_select_from_subselect'} = 0;
}

#our %Reserved_Words = map { $_ => 1 } qw(read for case);
#sub is_reserved_word { $Reserved_Words{lc $_[1]} }

*is_reserved_word = \&SQL::ReservedWords::MySQL::is_reserved;

#
# Introspection
#

sub _get_primary_key_column_names
{
  my($self, $catalog, $schema, $table) = @_;

  my $dbh = $self->dbh or die $self->error;

  local $dbh->{'FetchHashKeyName'} = 'NAME';

  my $fq_table =
    join('.', grep { defined } ($catalog, $schema, 
                                $self->quote_table_name($table)));

  my $sth = $dbh->prepare("SHOW INDEX FROM $fq_table");
  $sth->execute;

  my @columns;

  while(my $row = $sth->fetchrow_hashref)
  {
    next  unless($row->{'Key_name'} eq 'PRIMARY');
    push(@columns, $row->{'Column_name'});
  }

  return \@columns;
}

# Bury warning down here to make nice with version extractors
if(defined $DBD::mysql::VERSION && $DBD::mysql::VERSION <= 2.9)
{
  warn "WARNING: Rose::DB may not work correctly with DBD::mysql ",
       "version 2.9 or earlier.  You have version $DBD::mysql::VERSION";
}

1;

__END__

=head1 NAME

Rose::DB::MySQL - MySQL driver class for Rose::DB.

=head1 SYNOPSIS

  use Rose::DB;

  Rose::DB->register_db(
    domain   => 'development',
    type     => 'main',
    driver   => 'mysql',
    database => 'dev_db',
    host     => 'localhost',
    username => 'devuser',
    password => 'mysecret',
  );


  Rose::DB->default_domain('development');
  Rose::DB->default_type('main');
  ...

  # Set max length of varchar columns used to emulate the array data type
  Rose::DB::MySQL->max_array_characters(128);

  $db = Rose::DB->new; # $db is really a Rose::DB::MySQL-derived object
  ...

=head1 DESCRIPTION

L<Rose::DB> blesses objects into a class derived from L<Rose::DB::MySQL> when the L<driver|Rose::DB/driver> is "mysql".  This mapping of driver names to class names is configurable.  See the documentation for L<Rose::DB>'s L<new()|Rose::DB/new> and L<driver_class()|Rose::DB/driver_class> methods for more information.

This class cannot be used directly.  You must use L<Rose::DB> and let its L<new()|Rose::DB/new> method return an object blessed into the appropriate class for you, according to its L<driver_class()|Rose::DB/driver_class> mappings.

Only the methods that are new or have different behaviors than those in L<Rose::DB> are documented here.  See the L<Rose::DB> documentation for the full list of methods.

=head1 CLASS METHODS

=over 4

=item B<coerce_autoincrement_to_serial [BOOL]>

Get or set a boolean value that indicates whether or not "auto-increment" columns will be considered to have the column type  "serial."  If true, "integer" columns are coerced to the "serial" column type, and "bigint" columns use the "bigserial" column type.  The default value is true.

This setting comes into play when L<Rose::DB::Object::Loader> is used to auto-create column metadata based on an existing database schema.

=item B<max_array_characters [INT]>

Get or set the maximum length of varchar columns used to emulate the array data type.  The default value is 255.

MySQL does not have a native "ARRAY" data type, but this data type can be emulated using a "VARCHAR" column and a specially formatted string.  The formatting and parsing of this string is handled by the L<format_array|/format_array> and L<parse_array|/parse_array> object methods.  The maximum length limit is honored by the L<format_array|/format_array> object method.

=item B<max_interval_characters [INT]>

Get or set the maximum length of varchar columns used to emulate the interval data type.  The default value is 255.

MySQL does not have a native "interval" data type, but this data type can be emulated using a "VARCHAR" column and a specially formatted string.  The formatting and parsing of this string is handled by the L<format_interval|/format_interval> and L<parse_interval|/parse_interval> object methods.  The maximum length limit is honored by the L<format_interval|/format_interval> object method.

=back

=head1 OBJECT METHODS

=over 4

=item B<mysql_auto_reconnect [BOOL]>

Get or set the L<mysql_auto_reconnect|DBD::mysql/mysql_auto_reconnect> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_auto_reconnect> documentation to learn more about this attribute.

=item B<mysql_bind_type_guessing [BOOL]>

Get or set the L<mysql_bind_type_guessing|DBD::mysql/mysql_bind_type_guessing> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_bind_type_guessing> documentation to learn more about this attribute.

=item B<mysql_client_found_rows [BOOL]>

Get or set the L<mysql_client_found_rows|DBD::mysql/mysql_client_found_rows> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_client_found_rows> documentation to learn more about this attribute.

=item B<mysql_compression [BOOL]>

Get or set the L<mysql_compression|DBD::mysql/mysql_compression> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_compression> documentation to learn more about this attribute.

=item B<mysql_connect_timeout [BOOL]>

Get or set the L<mysql_connect_timeout|DBD::mysql/mysql_connect_timeout> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_connect_timeout> documentation to learn more about this attribute.

=item B<mysql_embedded_groups [STRING]>

Get or set the L<mysql_embedded_groups|DBD::mysql/mysql_embedded_groups> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_embedded_groups> documentation to learn more about this attribute.

=item B<mysql_embedded_options [STRING]>

Get or set the L<mysql_embedded_options|DBD::mysql/mysql_embedded_options> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_embedded_options> documentation to learn more about this attribute.

=item B<mysql_enable_utf8 [BOOL]>

Get or set the L<mysql_enable_utf8|DBD::mysql/mysql_enable_utf8> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists, by executing the SQL C<SET NAMES utf8>.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_enable_utf8> documentation to learn more about this attribute.

=item B<mysql_enable_utf8mb4 [BOOL]>

Get or set the L<mysql_enable_utf8mb4|DBD::mysql/mysql_enable_utf8mb4> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists, by executing the SQL C<SET NAMES utf8mb4>.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_enable_utf8mb4> documentation to learn more about this attribute.

=item B<mysql_local_infile [STRING]>

Get or set the L<mysql_local_infile|DBD::mysql/mysql_local_infile> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_local_infile> documentation to learn more about this attribute.

=item B<mysql_multi_statements [BOOL]>

Get or set the L<mysql_multi_statements|DBD::mysql/mysql_multi_statements> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_multi_statements> documentation to learn more about this attribute.

=item B<mysql_read_default_file [STRING]>

Get or set the L<mysql_read_default_file|DBD::mysql/mysql_read_default_file> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_read_default_file> documentation to learn more about this attribute.

=item B<mysql_read_default_group [STRING]>

Get or set the L<mysql_read_default_group|DBD::mysql/mysql_read_default_group> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_read_default_group> documentation to learn more about this attribute.

=item B<mysql_socket [STRING]>

Get or set the L<mysql_socket|DBD::mysql/mysql_socket> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_socket> documentation to learn more about this attribute.

=item B<mysql_ssl [BOOL]>

Get or set the L<mysql_ssl|DBD::mysql/mysql_ssl> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_ssl> documentation to learn more about this attribute.

=item B<mysql_ssl_ca_file [STRING]>

Get or set the L<mysql_ssl_ca_file|DBD::mysql/mysql_ssl_ca_file> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_ssl_ca_file> documentation to learn more about this attribute.

=item B<mysql_ssl_ca_path [STRING]>

Get or set the L<mysql_ssl_ca_path|DBD::mysql/mysql_ssl_ca_path> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_ssl_ca_path> documentation to learn more about this attribute.

=item B<mysql_ssl_cipher [STRING]>

Get or set the L<mysql_ssl_cipher|DBD::mysql/mysql_ssl_cipher> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_ssl_cipher> documentation to learn more about this attribute.

=item B<mysql_ssl_client_cert [STRING]>

Get or set the L<mysql_ssl_client_cert|DBD::mysql/mysql_ssl_client_cert> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_ssl_client_cert> documentation to learn more about this attribute.

=item B<mysql_ssl_client_key [STRING]>

Get or set the L<mysql_ssl_client_key|DBD::mysql/mysql_ssl_client_key> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_ssl_client_key> documentation to learn more about this attribute.

=item B<mysql_use_result [BOOL]>

Get or set the L<mysql_use_result|DBD::mysql/mysql_use_result> database handle attribute.  This is set directly on the L<dbh|Rose::DB/dbh>, if one exists.  Otherwise, it will be set when the L<dbh|Rose::DB/dbh> is created.  If no value for this attribute is defined (the default) then it will not be set when the L<dbh|Rose::DB/dbh> is created, deferring instead to whatever default value L<DBD::mysql> chooses.

Returns the value of this attribute in the L<dbh|Rose::DB/dbh>, if one exists, or the value that will be set when the L<dbh|Rose::DB/dbh> is next created.

See the L<DBD::mysql|DBD::mysql/mysql_use_result> documentation to learn more about this attribute.

=back

=head2 Value Parsing and Formatting

=over 4

=item B<format_array ARRAYREF | LIST>

Given a reference to an array or a list of values, return a specially formatted string.  Undef is returned if ARRAYREF points to an empty array or if LIST is not passed.  The array or list must not contain undefined values.

If the resulting string is longer than L<max_array_characters|/max_array_characters>, a fatal error will occur.

=item B<format_interval DURATION>

Given a L<DateTime::Duration> object, return a string formatted according to the rules of PostgreSQL's "INTERVAL" column type.  If DURATION is undefined, a L<DateTime::Duration> object, a valid interval keyword (according to L<validate_interval_keyword|Rose::DB/validate_interval_keyword>), or if it looks like a function call (matches C</^\w+\(.*\)$/>) and L<keyword_function_calls|Rose::DB/keyword_function_calls> is true, then it is returned unmodified.

If the resulting string is longer than L<max_interval_characters|/max_interval_characters>, a fatal error will occur.

=item B<format_set ARRAYREF | LIST>

Given a reference to an array or a list of values, return a string formatted according to the rules of MySQL's "SET" data type.  Undef is returned if ARRAYREF points to an empty array or if LIST is not passed.  If the array or list contains undefined values, a fatal error will occur.

=item B<parse_array STRING | LIST | ARRAYREF>

Parse STRING and return a reference to an array.  STRING should be formatted according to the MySQL array data type emulation format returned by L<format_array()|/format_array>.  Undef is returned if STRING is undefined.

If a LIST of more than one item is passed, a reference to an array containing the values in LIST is returned.

If a an ARRAYREF is passed, it is returned as-is.

=item B<parse_interval STRING>

Parse STRING and return a L<DateTime::Duration> object.  STRING should be formatted according to the PostgreSQL native "interval" (years, months, days, hours, minutes, seconds) data type.

If STRING is a L<DateTime::Duration> object, a valid interval keyword (according to L<validate_interval_keyword|Rose::DB/validate_interval_keyword>), or if it looks like a function call (matches C</^\w+\(.*\)$/>) and L<keyword_function_calls|Rose::DB/keyword_function_calls> is true, then it is returned unmodified.  Otherwise, undef is returned if STRING could not be parsed as a valid "interval" value.

=item B<parse_set STRING | LIST | ARRAYREF>

Parse STRING and return a reference to an array.  STRING should be formatted according to MySQL's "SET" data type.  Undef is returned if STRING is undefined.

If a LIST of more than one item is passed, a reference to an array containing the values in LIST is returned.

If a an ARRAYREF is passed, it is returned as-is.

=item B<validate_date_keyword STRING>

Returns true if STRING is a valid keyword for the MySQL "date" data type.  Valid (case-insensitive) date keywords are:

    curdate()
    current_date
    current_date()
    now()
    sysdate()
    00000-00-00

Any string that looks like a function call (matches /^\w+\(.*\)$/) is also considered a valid date keyword if L<keyword_function_calls|Rose::DB/keyword_function_calls> is true.

=item B<validate_datetime_keyword STRING>

Returns true if STRING is a valid keyword for the MySQL "datetime" data type, false otherwise.  Valid (case-insensitive) datetime keywords are:

    curdate()
    current_date
    current_date()
    current_time 
    current_time()
    current_timestamp
    current_timestamp()
    curtime()
    now()
    sysdate()
    0000-00-00 00:00:00

Any string that looks like a function call (matches /^\w+\(.*\)$/) is also considered a valid datetime keyword if L<keyword_function_calls|Rose::DB/keyword_function_calls> is true.

=item B<validate_timestamp_keyword STRING>

Returns true if STRING is a valid keyword for the MySQL "timestamp" data type, false otherwise.  Valid (case-insensitive) timestamp keywords are:

    curdate()
    current_date
    current_date()
    current_time 
    current_time()
    current_timestamp
    current_timestamp()
    curtime()
    now()
    sysdate()
    0000-00-00 00:00:00
    00000000000000

Any string that looks like a function call (matches /^\w+\(.*\)$/) is also considered a valid timestamp keyword if L<keyword_function_calls|Rose::DB/keyword_function_calls> is true.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
