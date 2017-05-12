package DBIx::Dump;

use 5.006;
use strict;
use warnings;

require Exporter;
#use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use DBIx::Dump ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);
our $VERSION = '0.04';

sub new
{
	my $self = shift;
	my $attr = {@_};

	bless $attr, $self;
}

### Must put all anonymous subs before the %formats hash and dump sub.

my $excel = sub {

	my $self = shift;

	$self->{excelFormat} = undef;

	require Spreadsheet::WriteExcel;

	my $workbook = $self->{Generator} || Spreadsheet::WriteExcel->new($self->{output});
	$self->{Generator} = $workbook;

	my $worksheet = $workbook->addworksheet();

	my $col = 0; my $row = 0;

	my $cols = $self->{sth}->{NAME_uc};

	foreach my $data (@$cols)
	{
		$self->{eventHandler}->($self, \$data, $cols->[$col], 1) if $self->{eventHandler};
		$worksheet->write(0, $col, $data, $self->{excelFormat});
		$col++;
	}
	$row++;
	$col = 0;

	while (my @data = $self->{sth}->fetchrow_array())
	{
		foreach my $data (@data)
		{
			$self->{eventHandler}->($self, \$data, $cols->[$col], $row+1) if $self->{eventHandler};
			$worksheet->write($row, $col, $data, $self->{excelFormat});
			$col++;
		}
		$col = 0;
		$row++;
	}
	$row = 0;
	_clean_up($self);
};

my $csv = sub {

	my $self = shift;

	require Text::CSV_XS;
	require IO::File;

	my $fh = IO::File->new("$self->{output}", "w");

	my $csvobj = $self->{Generator} || Text::CSV_XS->new({
    'quote_char'  => '"',
    'escape_char' => '"',
    'sep_char'    => ',',
    'binary'      => 0
	});

	$self->{Generator} = $csvobj;

	my $cols = $self->{sth}->{NAME_uc};
	$csvobj->combine(@$cols);
	print $fh $csvobj->string(), "\n";

	my $row = 0;
	while (my @data = $self->{sth}->fetchrow_array())
	{
		my $col = 0;
		foreach my $data (@data)
		{
			$self->{eventHandler}->($self, \$data, $cols->[$col], $row+1) if $self->{eventHandler};
			$col++;
		}
		$csvobj->combine(@data);
		print $fh $csvobj->string(), "\n";
		$row++;
	}
	$row = 0;
	$fh->close();
	_clean_up($self);
};


#### This is experimental, don't use!!!!! ####
my $iQuery = sub {

	my $self = shift;

	require IO::File;

	my $fh = IO::File->new("$self->{output}", "w");

	my $stmt = $self->{sth}->{Statement};
	$stmt =~ /from\s+(.*)\s+(where|order by|group by)*/i;
	my @tables;
};
###############################################

my %formats = (
								'excel'  => $excel,
								'csv'		 => $csv,
								'iQuery' => $iQuery
							);

sub dump
{
	my $self = shift;
	my $attr = {@_};
	$self = {%$self, %$attr};

	$formats{$self->{'format'}}->($self);
}

sub _clean_up
{
	my $self = shift;

	$self->{Generator} = undef;
	$self->{excelFormat} = undef;
}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

DBIx::Dump - Perl extension for dumping database (DBI) data into a variety of formats.

=head1 SYNOPSIS

  use DBI;
	use DBIx::Dump;

	my $dbh = DBI->connect("dbi:Oracle:DSN_NAME", "user", "pass", {PrintError => 0, RaiseError => 1});
	my $sth = $dbh->prepare("select * from foo");
	$sth->execute();

	my $exceldb = DBIx::Dump->new('format' => 'excel', 'ouput' => 'db.xls', 'sth' => $sth, EventHandler => \@handler);
	$exceldb->dump();

=head1 DESCRIPTION

DBIx::Dump allows you to easily dump database data, retrieved using DBI, into a variety of formats
including Excel, CSV, etc...

=head2 EXPORT

None by default.


=head1 AUTHOR

Ilya Sterin<lt>isterin@cpan.org<gt>

=head1 SEE ALSO

L<perl>.
L<DBI>.

=cut
