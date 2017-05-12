package DBIx::PgLink::Adapter::Roles::EmulateColumnInfo;

use Moose::Role;
use Data::Dumper;

# Emulate dbh->column_info() for drivers, that not support it.
# Run dummy SELECT * FROM and use type_info()
# NOTE: allow single table only, catalog ignored

requires 'column_info_from_statement_arrayref';

override 'column_info' => sub {
  my ($self, $catalog, $schema, $table, $column) = @_;

  my @name = ($table);
  unshift @name, $schema if defined $schema && $schema ne '%';
  my $fullname = $self->quote_identifier(@name);

  $self->type_info(0); # required by column_info_from_statement_arrayref()

  my $sth = $self->prepare("SELECT * FROM $fullname WHERE 1=0");
  $sth->execute;

  my $aoh = $self->column_info_from_statement_arrayref($catalog, $schema, $table, $sth);

  $sth->finish;

  # borrowed from from DBD::ADO
  my @names = qw/TABLE_CAT TABLE_SCHEM TABLE_NAME COLUMN_NAME DATA_TYPE TYPE_NAME COLUMN_SIZE BUFFER_LENGTH DECIMAL_DIGITS NUM_PREC_RADIX NULLABLE REMARKS COLUMN_DEF SQL_DATA_TYPE SQL_DATETIME_SUB CHAR_OCTET_LENGTH ORDINAL_POSITION IS_NULLABLE/;
  my @types = (         12,         12,        12,         12,        5,       12,          4,            4,             5,             5,       5,     12,        12,            5,               5,                4,               4,         12);
  my @aoa;
  for my $hashref (@{$aoh}) {
    my @values = @{$hashref}{@names};
    push @aoa, \@values;
  }

  return DBI->connect('dbi:Sponge:','','', { RaiseError => 1 } )->prepare(
    "column_info($fullname)", 
    { 
      rows => \@aoa,
      NAME => \@names,
      TYPE => \@types,
	} 
  );
  
};

1;
