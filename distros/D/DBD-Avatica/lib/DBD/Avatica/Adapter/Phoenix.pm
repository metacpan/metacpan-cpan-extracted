package DBD::Avatica::Adapter::Phoenix;

use strict;
use warnings;

use DBI ':sql_types';

use Avatica::Client;

use parent 'DBD::Avatica::Adapter::Default';

use constant JAVA_TO_REP => {
    %{DBD::Avatica::Adapter::Default->JAVA_TO_REP()},

    # These are the non-standard types defined by Phoenix
    18  => Avatica::Client::Protocol::Rep::JAVA_SQL_TIME(),     # UNSIGNED_TIME
    19  => Avatica::Client::Protocol::Rep::JAVA_SQL_DATE(),     # UNSIGNED_DATE
    15  => Avatica::Client::Protocol::Rep::DOUBLE(),            # UNSIGNED_DOUBLE
    14  => Avatica::Client::Protocol::Rep::DOUBLE(),            # UNSIGNED_FLOAT
    9   => Avatica::Client::Protocol::Rep::INTEGER(),           # UNSIGNED_INT
    10  => Avatica::Client::Protocol::Rep::LONG(),              # UNSIGNED_LONG
    13  => Avatica::Client::Protocol::Rep::SHORT(),             # UNSIGNED_SMALLINT
    20  => Avatica::Client::Protocol::Rep::JAVA_SQL_TIMESTAMP(),    # UNSIGNED_TIMESTAMP
    11  => Avatica::Client::Protocol::Rep::BYTE(),              # UNSIGNED_TINYINT
};

# params:
# self
# value
# Avatica::Client::Protocol::AvaticaParameter
sub to_jdbc {
    my ($self, $value, $avatica_param) = @_;

    my $jdbc_type_id = $avatica_param->get_parameter_type;

    # Phoenix add base 3000 for array types
    # https://github.com/apache/phoenix/blob/2a2d9964d29c2e47667114dbc3ca43c0e264a221/phoenix-core/src/main/java/org/apache/phoenix/schema/types/PDataType.java#L518
    my $is_array = $jdbc_type_id > 2900 && $jdbc_type_id < 3100;
    return $self->SUPER::to_jdbc($value, $avatica_param) unless $is_array && defined $value;

    # Phoenix added arrays with base 3000

    my $element_rep = $self->convert_jdbc_to_rep_type($jdbc_type_id - 3000);

    my $elem_avatica_param = Avatica::Client::Protocol::AvaticaParameter->new;
    $elem_avatica_param->set_parameter_type($jdbc_type_id - 3000);

    my $typed_value = Avatica::Client::Protocol::TypedValue->new;
    $typed_value->set_null(0);
    $typed_value->set_type(Avatica::Client::Protocol::Rep::ARRAY());
    $typed_value->set_component_type($element_rep);

    for my $v (@$value) {
        my $tv = $self->SUPER::to_jdbc($v, $elem_avatica_param);
        $typed_value->add_array_value($tv);
    }

    return $typed_value;
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

    # ARRAY (may be for bind params only)
    return SQL_ARRAY if $java_type_id > 2900 && $java_type_id < 3100;

    return $self->SUPER::to_dbi($avatica_type);
}

# params:
# self
# Avatica::Client::Protocol::Signature
sub extend_primary_key_info_signature {
    my ($self, $signature) = @_;
    # This returns '\x00\x00\x00A' or '\x00\x00\x00D' , but that's consistent with Java
    $signature->add_columns(Avatica::Client->_build_column_metadata(7, 'ASC_OR_DESC', 12));
    $signature->add_columns(Avatica::Client->_build_column_metadata(8, 'DATA_TYPE', 5));
    $signature->add_columns(Avatica::Client->_build_column_metadata(9, 'TYPE_NAME', 12));
    $signature->add_columns(Avatica::Client->_build_column_metadata(10, 'COLUMN_SIZE', 5));
    $signature->add_columns(Avatica::Client->_build_column_metadata(11, 'TYPE_ID', 5));
    $signature->add_columns(Avatica::Client->_build_column_metadata(12, 'VIEW_CONSTANT', 12));
    return $signature;
}

sub last_insert_id {
  my ($self, $dbh, undef, $schema, $table, $column, $attr) = @_;

  return $dbh->set_err(1, qq{Param "table" must be specified}) unless $table;

  my $seq = $attr->{sequence};
  my $quote = $dbh->get_info('SQL_IDENTIFIER_QUOTE_CHAR');

  # try to determine sequence
  unless ($seq) {
    my $system_table = "${quote}SYSTEM${quote}.${quote}SEQUENCE${quote}";
    my $where = $schema ? "SEQUENCE_SCHEMA = '$schema' AND " : '';
    $where .= "SEQUENCE_NAME LIKE '$table" . ($column ? "_${column}%" : '%')  . "'";

    my $res = $dbh->selectrow_hashref(qq{SELECT * FROM $system_table WHERE $where LIMIT 1});
    unless ($res) {
      return if $dbh->errstr;
      return $dbh->set_err(1, qq{Could not determine the sequence of table $table});
    }

    $seq = $res->{SEQUENCE_NAME};
  }

  my $full_table_name = $schema ? "${quote}${schema}${quote}." : '';
  $full_table_name .= "${quote}$table${quote}";

  # add schema to sequence
  if ($schema && index($seq, $schema) == -1) {
    $seq = "${quote}${schema}${quote}." . "${quote}${seq}${quote}"
  }

  my $res = $dbh->selectrow_hashref(qq{SELECT CURRENT VALUE FOR $seq AS SEQ FROM $full_table_name LIMIT 1});
  unless ($res) {
    return if $dbh->errstr;
    return $dbh->set_err(1, qq{last_insert_id must be called after NEXT VALUE FOR is called});
  }

  return $res->{SEQ};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBD::Avatica::Adapter::Phoenix

=head1 VERSION

version 0.2.0

=head1 AUTHOR

Alexey Stavrov <logioniz@ya.ru>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Alexey Stavrov.

This is free software, licensed under:

  The MIT (X11) License

=cut
