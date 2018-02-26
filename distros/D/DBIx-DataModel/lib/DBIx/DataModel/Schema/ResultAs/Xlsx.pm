#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs::Xlsx;
#----------------------------------------------------------------------
use warnings;
use strict;
use Carp::Clan           qw[^(DBIx::DataModel::|SQL::Abstract)];
use Excel::Writer::XLSX;
use Params::Validate qw/validate_with SCALAR/;

use parent 'DBIx::DataModel::Schema::ResultAs';

use namespace::clean;

sub param_spec { # class method
  return {
    -worksheet    => {type => SCALAR, default => 'Data'},
    -tech_details => {type => SCALAR, default => 'Technical_details'},
  };
}

sub new {
  my $class = shift;

  # the first positional arg is the output file .. string or a filehandle
  my $file  = shift
    or croak 'select(..., -result_as => [xlsx => $file]): file is missing';

  # other args as a hash of named options
  my %self = validate_with(
    params      => \@_,
    spec        => $class->param_spec,
    allow_extra => 0);

  # assemble and bless
  $self{file} = $file;
  return bless \%self, $class;
}


sub get_result {
  my ($self, $statement) = @_;

  # create the Excel workbook
  my $workbook  = $self->create_workbook;

  # gather data from the statement
  $statement->execute;
  $statement->make_fast;
  my @headers   = $statement->headers;
  my @rows;
  while (my $row = $statement->next) {
    push @rows, [@{$row}{@headers}];
  }

  # create the data worksheet
  my $worksheet = $self->create_data_worksheet($workbook);
  $self->populate_worksheet($worksheet, \@headers, \@rows);

  # optionally insert another sheet with technical details
  $self->add_technical_details($workbook, $statement) if $self->{-tech_details};

  # finalize
  $statement->finish;
  $workbook->close;

  # return filename or filehandle
  return $self->{file};
}


sub create_workbook {
  my ($self) = @_;

  my $workbook  = Excel::Writer::XLSX->new($self->{file})
    or die "open Excel file $self->{file}: $!";

  return $workbook;
}


sub create_data_worksheet {
  my ($self, $workbook) = @_;
  my $worksheet = $workbook->add_worksheet($self->{-worksheet});

  return $worksheet;
}


sub populate_worksheet {
  my ($self, $worksheet, $headers, $rows) = @_;

  # insert data as an Excel table
  $worksheet->add_table(0, 0, scalar(@$rows), scalar(@$headers)-1, {
    data       => $rows,
    columns    => [ map { {header => $_}} @$headers ],
    autofilter => 1,
   });
}


sub add_technical_details {
  my ($self, $workbook, $statement, $n_rows) = @_;

  my $tech_worksheet = $workbook->add_worksheet($self->{-tech_details});
  $tech_worksheet->write_col(0, 0, [
    scalar(localtime),               # time of the extraction
    $statement->schema->dbh->{Name}, # database name
    $statement->row_num . " rows",   # number of rows
    $statement->sql,                 # SQL and bind values
   ]);

  return $tech_worksheet;
}


1;


__END__

=head1 NAME

DBIx::DataModel::Schema::ResultAs::Xlsx - writes into an Excel file

=head1 SYNOPSIS

  $source->select(..., $result_as => [xlsx => ($file,
                                               -worksheet    => $wksh_name,
                                               -tech_details => 0)]);


=head1 DESCRIPTION

Writes all resulting rows into an Excel file, using L<Excel::Writer::XLSX>.

=head1 METHODS

=head1 new

Arguments :

=over

=item C<$file>

Mandatory. This can be either the name of a file to generate, or it can
be an open filehandle (see L<Excel::Writer::XLSX/new>).

=item C<< -worksheet => $wksh_name >>

Optional. Specifies the name of the data worksheet. Default is 'Data'.

=item C<< -tech_details => $details_name >>

Optional. Specifies the name of the worksheet that will report technical
details (time of extraction, name of database, SQL and bind values).
Default is 'Technical_details'. If set to 0 or to an empty string, the
technical sheet will not be generated.

=back





