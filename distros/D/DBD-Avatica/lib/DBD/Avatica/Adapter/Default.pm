package DBD::Avatica::Adapter::Default;

use strict;
use warnings;

use Scalar::Util 'weaken';
use Carp 'croak';
use Time::Piece;
use Scalar::Util qw/looks_like_number/;
use DBI ':sql_types';

use Avatica::Client;

#
# JAVA Types https://github.com/JetBrains/jdk8u_jdk/blob/master/src/share/classes/java/sql/Types.java
#

use constant JAVA_TO_REP => {
  -6    => Avatica::Client::Protocol::Rep::BYTE(),                # TINYINT
  5     => Avatica::Client::Protocol::Rep::SHORT(),               # SMALLINT
  4     => Avatica::Client::Protocol::Rep::INTEGER(),             # INTEGER
  -5    => Avatica::Client::Protocol::Rep::LONG(),                # BIGINT
  6     => Avatica::Client::Protocol::Rep::DOUBLE(),              # FLOAT
  8     => Avatica::Client::Protocol::Rep::DOUBLE(),              # DOUBLE
  2     => Avatica::Client::Protocol::Rep::BIG_DECIMAL(),         # NUMERIC
  1     => Avatica::Client::Protocol::Rep::STRING(),              # CHAR
  91    => Avatica::Client::Protocol::Rep::JAVA_SQL_DATE(),       # DATE
  92    => Avatica::Client::Protocol::Rep::JAVA_SQL_TIME(),       # TIME
  93    => Avatica::Client::Protocol::Rep::JAVA_SQL_TIMESTAMP(),  # TIMESTAMP
  -2    => Avatica::Client::Protocol::Rep::BYTE_STRING(),         # BINARY
  -3    => Avatica::Client::Protocol::Rep::BYTE_STRING(),         # VARBINARY
  16    => Avatica::Client::Protocol::Rep::BOOLEAN(),             # BOOLEAN

  -7    => Avatica::Client::Protocol::Rep::BOOLEAN(),             # BIT
  7     => Avatica::Client::Protocol::Rep::DOUBLE(),              # REAL
  3     => Avatica::Client::Protocol::Rep::BIG_DECIMAL(),         # DECIMAL
  12    => Avatica::Client::Protocol::Rep::STRING(),              # VARCHAR
  -1    => Avatica::Client::Protocol::Rep::STRING(),              # LONGVARCHAR
  -4    => Avatica::Client::Protocol::Rep::BYTE_STRING(),         # LONGVARBINARY
  2004  => Avatica::Client::Protocol::Rep::BYTE_STRING(),         # BLOB
  2005  => Avatica::Client::Protocol::Rep::STRING(),              # CLOB
  -15   => Avatica::Client::Protocol::Rep::STRING(),              # NCHAR
  -9    => Avatica::Client::Protocol::Rep::STRING(),              # NVARCHAR
  -16   => Avatica::Client::Protocol::Rep::STRING(),              # LONGNVARCHAR
  2011  => Avatica::Client::Protocol::Rep::STRING(),              # NCLOB
  2009  => Avatica::Client::Protocol::Rep::STRING(),              # SQLXML
  2013  => Avatica::Client::Protocol::Rep::JAVA_SQL_TIME(),       # TIME_WITH_TIMEZONE
  2014  => Avatica::Client::Protocol::Rep::JAVA_SQL_TIMESTAMP(),  # TIMESTAMP_WITH_TIMEZONE

  # Returned by Avatica for Arrays in EMPTY resultsets
  2000  => Avatica::Client::Protocol::Rep::BYTE_STRING(),         # JAVA_OBJECT
};

use constant REP_TO_TYPE_VALUE => {
  Avatica::Client::Protocol::Rep::INTEGER()            => 'number_value',
  Avatica::Client::Protocol::Rep::PRIMITIVE_INT()      => 'number_value',
  Avatica::Client::Protocol::Rep::SHORT()              => 'number_value',
  Avatica::Client::Protocol::Rep::PRIMITIVE_SHORT()    => 'number_value',
  Avatica::Client::Protocol::Rep::LONG()               => 'number_value',
  Avatica::Client::Protocol::Rep::PRIMITIVE_LONG()     => 'number_value',
  Avatica::Client::Protocol::Rep::BYTE()               => 'number_value',
  Avatica::Client::Protocol::Rep::JAVA_SQL_TIME()      => 'number_value',
  Avatica::Client::Protocol::Rep::JAVA_SQL_DATE()      => 'number_value',
  Avatica::Client::Protocol::Rep::JAVA_SQL_TIMESTAMP() => 'number_value',

  Avatica::Client::Protocol::Rep::BYTE_STRING()        => 'bytes_value',

  Avatica::Client::Protocol::Rep::DOUBLE()             => 'double_value',
  Avatica::Client::Protocol::Rep::PRIMITIVE_DOUBLE()   => 'double_value',

  Avatica::Client::Protocol::Rep::PRIMITIVE_CHAR()     => 'string_value',
  Avatica::Client::Protocol::Rep::CHARACTER()          => 'string_value',
  Avatica::Client::Protocol::Rep::BIG_DECIMAL()        => 'string_value',
  Avatica::Client::Protocol::Rep::STRING()             => 'string_value',

  Avatica::Client::Protocol::Rep::BOOLEAN()            => 'bool_value',
  Avatica::Client::Protocol::Rep::PRIMITIVE_BOOLEAN()  => 'bool_value',
};

use constant JAVA_TO_DBI => {
  -6    => SQL_TINYINT,                       # TINYINT
  5     => SQL_SMALLINT,                      # SMALLINT
  4     => SQL_INTEGER,                       # INTEGER
  -5    => SQL_BIGINT,                        # BIGINT
  6     => SQL_FLOAT,                         # FLOAT
  8     => SQL_DOUBLE,                        # DOUBLE
  2     => SQL_NUMERIC,                       # NUMERIC
  1     => SQL_CHAR,                          # CHAR
  91    => SQL_TYPE_DATE,                     # DATE
  92    => SQL_TYPE_TIME,                     # TIME
  93    => SQL_TYPE_TIMESTAMP,                # TIMESTAMP
  -2    => SQL_BINARY,                        # BINARY
  -3    => SQL_VARBINARY,                     # VARBINARY
  16    => SQL_BOOLEAN,                       # BOOLEAN

  -7    => SQL_BIT,                           # BIT
  7     => SQL_REAL,                          # REAL
  3     => SQL_DECIMAL,                       # DECIMAL
  12    => SQL_VARCHAR,                       # VARCHAR
  -1    => SQL_LONGVARCHAR,                   # LONGVARCHAR
  -4    => SQL_LONGVARBINARY,                 # LONGVARBINARY
  2004  => SQL_BLOB,                          # BLOB
  2005  => SQL_CLOB,                          # CLOB
  -15   => SQL_CHAR,                          # NCHAR
  -9    => SQL_VARCHAR,                       # NVARCHAR
  -16   => SQL_LONGVARCHAR,                   # LONGNVARCHAR
  2011  => SQL_CLOB,                          # NCLOB
  2009  => SQL_LONGVARCHAR,                   # SQLXML
  2013  => SQL_TYPE_TIME_WITH_TIMEZONE,       # TIME_WITH_TIMEZONE
  2014  => SQL_TYPE_TIMESTAMP_WITH_TIMEZONE,  # TIMESTAMP_WITH_TIMEZONE

  # Returned by Avatica for Arrays in EMPTY resultsets
  2000  => SQL_ARRAY,                         # JAVA_OBJECT
  2003  => SQL_ARRAY,                         # ARRAY
};

sub new {
  my ($class, %params) = @_;

  my $self = {dbh => $params{dbh}};
  weaken $self->{dbh};

  return bless $self, $class;
}

# params:
# self
# [Avatica::Client::Protocol::ColumnValue, ...]
# [Avatica::Client::Protocol::ColumnMetaData, ...]
sub row_from_jdbc {
  my ($self, $columns_values, $columns_meta) = @_;
  croak 'The number of arguments is not the same as the expected number' if $#{$columns_values} != $#{$columns_meta};
  return [
    map {
        $self->from_jdbc($columns_values->[$_], $columns_meta->[$_])
    }
    0 .. $#{$columns_meta}
  ];
}

# params:
# self
# Avatica::Client::Protocol::ColumnValue
# Avatica::Client::Protocol::ColumnMetaData
sub from_jdbc {
  my ($self, $column_value, $column_meta) = @_;

  my $scalar_value = $column_value->get_scalar_value;

  return (undef,) if $scalar_value && $scalar_value->get_null;

  if ($column_value->get_has_array_value) {
    my $jdbc_type_id = $column_meta->get_type->get_component->get_id;
    my $rep = $self->convert_jdbc_to_rep_type($jdbc_type_id);

    my $type = $self->REP_TO_TYPE_VALUE()->{$rep};
    my $method = "get_$type";

    my $values = [];
    for my $v (@{$column_value->get_array_value_list}) {
      my $res = $v->$method();
      push @$values, $self->convert_from_jdbc($res, $rep);
    }

    return $values;
  }

  my $jdbc_type_id = $column_meta->get_type->get_id;
  my $rep = $self->convert_jdbc_to_rep_type($jdbc_type_id);

  my $type = $self->REP_TO_TYPE_VALUE()->{$rep};
  my $method = "get_$type";

  my $res = $scalar_value->$method();

  return $self->convert_from_jdbc($res, $rep);
}

# params:
# self
# values
# [Avatica::Client::Protocol::AvaticaParameter, ...]
sub row_to_jdbc {
  my ($self, $values, $avatica_params) = @_;
  croak 'The number of arguments is not the same as the expected number' if $#{$values} != $#{$avatica_params};
  return [
    map {
      $self->to_jdbc($values->[$_], $avatica_params->[$_])
    }
    0 .. $#{$avatica_params}
  ];
}

# params:
# self
# value
# Avatica::Client::Protocol::AvaticaParameter
sub to_jdbc {
  my ($self, $value, $avatica_param) = @_;

  my $jdbc_type_id = $avatica_param->get_parameter_type;

  my $typed_value = Avatica::Client::Protocol::TypedValue->new;

  unless (defined $value) {
    $typed_value->set_null(1);
    $typed_value->set_type(Avatica::Client::Protocol::Rep::NULL());
    return $typed_value;
  }

  $typed_value->set_null(0);

  my $rep = $self->convert_jdbc_to_rep_type($jdbc_type_id);
  croak "Unknown jdbc type: $jdbc_type_id" unless $rep;
  my $type = $self->REP_TO_TYPE_VALUE->{$rep};
  croak "Unknown rep type: $rep" unless $type;

  my $method = "set_$type";

  $typed_value->set_type($rep);
  $typed_value->$method($self->convert_to_jdbc($value, $rep));

  return $typed_value;
}

sub convert_from_jdbc {
  my ($self, $value, $rep) = @_;

  if ($rep == Avatica::Client::Protocol::Rep::JAVA_SQL_TIME()) {
    my $sec = int($value / 1000);
    my $milli = $value % 1000;
    my $time = Time::Piece->strptime($sec, '%s')->time;
    $time .= '.' . $milli if $milli;
    return $time;
  }

  if ($rep == Avatica::Client::Protocol::Rep::JAVA_SQL_DATE()) {
    return Time::Piece->strptime($value * 86400, '%s')->ymd;
  }

  if ($rep == Avatica::Client::Protocol::Rep::JAVA_SQL_TIMESTAMP()) {
    my $sec = int($value / 1000);
    my $milli = $value % 1000;
    my $datetime = Time::Piece->strptime($sec, '%s')->strftime('%Y-%m-%d %H:%M:%S');
    $datetime .= '.' . $milli if $milli;
    return $datetime;
  }

  return $value;
}

sub convert_to_jdbc {
  my ($self, $value, $rep) = @_;

  if ($rep == Avatica::Client::Protocol::Rep::JAVA_SQL_TIME()) {
    return $value if looks_like_number($value);

    my ($datetime, $milli) = split /\./, $value;
    my ($date, $time) = split /[tT ]/, $datetime;
    $time = $date unless $time;

    my ($h, $m, $s) = split /:/, $time;
    return ((($h // 0) * 60 + ($m // 0)) * 60 + ($s // 0)) * 1000 + ($milli ? substr($milli . '00', 0, 3)  : 0);
  }

  if ($rep == Avatica::Client::Protocol::Rep::JAVA_SQL_DATE()) {
    return $value if looks_like_number($value);
    my ($datetime, $milli) = split /\./, $value;
    my ($date, $time) = split /[tT ]/, $datetime;
    return Time::Piece->strptime($date, '%Y-%m-%d')->epoch / 86400;
  }

  if ($rep == Avatica::Client::Protocol::Rep::JAVA_SQL_TIMESTAMP()) {
    return $value if looks_like_number($value);
    my ($datetime, $milli) = split /\./, $value;
    $datetime =~ s/[Tt]/ /;
    my $sec = Time::Piece->strptime($datetime, '%Y-%m-%d %H:%M:%S')->epoch;
    return $sec * 1000 + ($milli ? substr($milli . '00', 0, 3) : 0);
  }

  return $value;
}

sub convert_jdbc_to_rep_type {
  my ($self, $jdbc_type) = @_;
  if ($jdbc_type > 0x7FFFFFFF) {
      $jdbc_type = -(($jdbc_type ^ 0xFFFFFFFF) + 1);
  }
  return $self->JAVA_TO_REP()->{$jdbc_type};
}

# params:
# self
# Avatica::Client::Protocol::AvaticaType
sub to_dbi {
  my ($self, $avatica_type) = @_;
  my $java_type_id = $avatica_type->get_id;

  if ($java_type_id > 0x7FFFFFFF) {
    $java_type_id = -(($java_type_id ^ 0xFFFFFFFF) + 1);
  }

  my $dbi_type_id = $self->JAVA_TO_DBI()->{$java_type_id};
  return $java_type_id unless $dbi_type_id;
  return $dbi_type_id;
}

# may be phoenix specific code
sub map_database_properties {
  my ($self, $properties) = @_;

  my $res = {
    AVATICA_DRIVER_NAME => '',
    AVATICA_DRIVER_VERSION => '',
    DBMS_NAME => '',
    DBMS_VERSION => '',
    SQL_KEYWORDS => ''
  };

  for my $p (@$properties) {
    my $name = $p->get_key->get_name // '';
    if ($name eq 'GET_DRIVER_NAME') {
        $res->{AVATICA_DRIVER_NAME} = $p->get_value->get_string_value;
    } elsif ($name eq 'GET_DRIVER_VERSION') {
        $res->{AVATICA_DRIVER_VERSION} = $p->get_value->get_string_value;
    } elsif ($name eq 'GET_DATABASE_PRODUCT_VERSION') {
        $res->{DBMS_VERSION} = $p->get_value->get_string_value;
    } elsif ($name eq 'GET_DATABASE_PRODUCT_NAME') {
        $res->{DBMS_NAME} = $p->get_value->get_string_value;
    } elsif ($name eq 'GET_S_Q_L_KEYWORDS') {
        $res->{SQL_KEYWORDS} = $p->get_value->get_string_value;
    }
  }

  return $res;
}

# params:
# self
# Avatica::Client::Protocol::Signature
sub extend_primary_key_info_signature {
  my ($self, $signature) = @_;
  return $signature;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBD::Avatica::Adapter::Default

=head1 VERSION

version 0.2.2

=head1 AUTHOR

Alexey Stavrov <logioniz@ya.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Alexey Stavrov.

This is free software, licensed under:

  The MIT (X11) License

=cut
