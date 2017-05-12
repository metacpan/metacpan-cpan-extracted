use DBI;
use DBI::Dump;

my $dbh = DBI->connect(...);

my $sth = $dbh->prepare("select * from users");

$sth->execute();

my $exceldb = DBIx::Dump->new();

$exceldb->dump('format' => 'excel', 'output' => 'db2.xls', 'sth' => $sth,
'eventHandler' => \&handler);

my $count = 0;
sub handler
{
	my ($self, $data, $colName, $row) = @_;

	my $format;
	if ($count == 0)
	{
		$format = $self->{Generator}->addformat(); # Add a format
		$format->set_bold();
		$format->set_color('red');
		$format->set_align('center');
		$self->{excelFormat} = $format;
	}
	$count++;

	if ($row == 2)
	{
		$self->{excelFormat} = undef;
		$format = $self->{Generator}->addformat(); # Add a format
		$format->set_num_format(0x0f);
	}

	if ($row > 1 && $colName == 'ACQUISITION DATE')
	{
		$self->{excelFormat} = $format;
	}
	elsif ($row > 1)
	{
		$self->{excelFormat} = undef;
	}
}

