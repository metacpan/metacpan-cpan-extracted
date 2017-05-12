#------------------------------------------------------------------------------
# DBO test skeleton: open database and create a table.
#------------------------------------------------------------------------------

test {
  my $handle_class = "DBO::Handle::DBI::$CONFIG->{driver}";
  $handle_class = "DBO::Handle::DBI" unless eval "defined ${handle_class}::";
  $dbh = $handle_class->connect(@$CONFIG{qw(datasource user password)})
    or die "Can't connect to $CONFIG->{datasource}: " . $handle_class->errstr;
};

test {
  $table1 = Table
    (
     name => "${TABLE}1",
     columns =>
     [
      Key(base => AutoIncrement(name => 'id', not_null => 1)),
      Char(name => 'col_char', max_length => 15, not_null => 1),
      Text(name => 'col_text'),
      Time(name => 'col_time1'),
      Time(name => 'col_time2', accuracy => 2),
      Integer(name => 'col_integer'),
      Unsigned(name => 'col_unsigned'),
      Option(base => Unsigned(name => 'col_option_unsigned', not_null => 1),
	     values => [ 0, 1 ]),
      Option(base => Char(name => 'col_option_char', not_null => 1),
	     values => [ 'red', 'white', 'blue' ]),
     ]
    );
  $schema = Database(tables => [ $table1 ])
};

test { $dbo = DBO->new(schema => $schema, handle => $dbh) };
test { $dbo->apply_to_database('DBO::Visitor::Create') };

1;
