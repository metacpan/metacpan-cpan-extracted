package App::DB::Schema::Dumper;
use Dwarf::Pragma;
use DBIx::Inspector 0.03;
use Carp ();

sub dump {
	my $class = shift;
	my %args = @_==1 ? %{$_[0]} : @_;
	my $dbh       = $args{dbh} or Carp::croak("missing mandatory parameter 'dbh'");
	my $namespace = $args{namespace} or Carp::croak("missing mandatory parameter 'namespace'");
	my $row_class = $args{base_row_class};
	my $dt_rules  = $args{dt_rules} || qr/_at$/;

	my $inspector = DBIx::Inspector->new(dbh => $dbh);

	my $ret = "package ${namespace}::Schema;\n";
	$ret .= "use Teng::Schema::Declare;\n";
	$ret .= "use ${namespace}::Schema::Declare;\n\n";

	for my $table_info (sort { $a->name cmp $b->name } $inspector->tables) {
		$ret .= "table {\n";
		$ret .= sprintf("    name '%s';\n", $table_info->name);
		$ret .= sprintf("    pk %s;\n", join ',' , map { q{'}.$_->name.q{'} } $table_info->primary_key);
		$ret .= sprintf("    row_class '%s';\n", $row_class) if $row_class;

		$ret .= "    columns (\n";
		for my $col ($table_info->columns) {
			if ($col->data_type) {
				my $data_type = $col->data_type;
				my $pg_type = $col->{PG_TYPE} || $col->{pg_type};
				# Pg の char(n) 対策
				if ($pg_type && $pg_type =~ /^character\((\d+)\)$/) {
					if ($1 > 1) {
						$data_type = "{ pg_type => 1042 }";
					}
				}

				$ret .= sprintf("        { name => '%s', type => %s },\n", $col->name, $data_type);
			} else {
				$ret .= sprintf("        '%s',\n", $col->name);
			}
		}
		$ret .= "    );\n";

		my @datetime_columns = grep { $_->name =~ m/$dt_rules/ } $table_info->columns;
		if (@datetime_columns) {
			$ret .= "    datetime_columns (\n";
			for my $col (@datetime_columns) {
				$ret .= sprintf("        '%s',\n", $col->name);
			}
			$ret .= "    );\n";
		}

		$ret .= "};\n\n";
	}
	$ret .= "1;\n";
	return $ret;
}

1;
