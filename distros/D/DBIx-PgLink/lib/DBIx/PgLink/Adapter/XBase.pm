package DBIx::PgLink::Adapter::XBase;

use Moose;

extends 'DBIx::PgLink::Adapter';

with 'DBIx::PgLink::Adapter::Roles::EmulateColumnInfo';

has '+are_transactions_supported' => (default=>0);
has '+include_schema_to_qualified_name' => (default=>0);

# Fix XBase 'table_info' method
# Note: 'catalog' and 'schema' arguments are ignored
override 'table_info' => sub {
  my ($self, $catalog, $schema, $table, $type) = @_;

  # catalog and schema ignored, type can be only 'TABLE'
  $type =~ s/'//g;
  return unless grep { $_ eq 'TABLE' } split /,/, $type;

  # convert 'like' pattern to regex
  $table =~ s/_/./g;
  $table =~ s/%/.*/g;

  my $sth = DBI::_new_sth(
    $self->dbh, 
    { 
      'xbase_lines' =>
  		[ map { [ undef, undef, $_, 'TABLE', undef ] } 
          grep /^$table$/i, $self->dbh->tables # fixed: no name filtering
  		]
  	} 
  );
  $sth->STORE('NUM_OF_FIELDS', 5);
  $sth->{'xbase_nondata_name'} = [ 
    qw! TABLE_QUALIFIER TABLE_OWNER
  		TABLE_NAME TABLE_TYPE REMARKS !
  ];
  return $sth;
};


# DBD::XBase 0.241 don't understand any quoting
override 'quote_identifier' => sub {
  my $self = shift;
  my @argv = grep { defined } @_;
  return $argv[-1]; # only last portion of name
};


# conversion

# Date YYYY-MM-DD -> YYYYMMDD
sub to_xbase_date($) {
  return unless defined $_[1];
  $_[1] = "$1$2$3" if $_[1] =~ /^(\d\d\d\d)-(\d\d)-(\d\d)/; 
}

1;
