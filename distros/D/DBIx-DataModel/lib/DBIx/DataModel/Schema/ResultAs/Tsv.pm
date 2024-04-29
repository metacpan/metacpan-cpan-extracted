#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs::Tsv;
#----------------------------------------------------------------------
use warnings;
use strict;
use DBIx::DataModel::Carp;
use Scalar::Util 1.07 qw/openhandle/;

use parent 'DBIx::DataModel::Schema::ResultAs';

use namespace::clean;

sub new {
  my ($class, $file) = @_;

  croak "-result_as => [Tsv => ...] ... target file is missing" if !$file;
  return bless {file => $file}, $class;
}


sub get_result {
  my ($self, $statement) = @_;

  # open file
  my $fh;
  if (openhandle $self->{file}) {
    $fh = $self->{file};
  }
  else {
    open $fh, ">", $self->{file}
      or croak "open $self->{file} for writing : $!";
  }

  # get data
  $statement->execute;
  $statement->make_fast;

  # activate tsv mode by setting output field and record separators
  local $\ = "\n";
  local $, = "\t";

  # print header row
  no warnings 'uninitialized';
  my @headers   = $statement->headers;
  print $fh @headers;

  # print data rows
  while (my $row = $statement->next) {
    my @data = @{$row}{@headers}; 
    s/[\t\n]+/ /g foreach @data;
    print $fh @data;
  }

  # cleanup and return
  $statement->finish;
  return $self->{file};
}


1;

__END__

=head1 NAME

DBIx::DataModel::Schema::ResultAs::Tsv - writes into a tab-separated file

=head1 SYNOPSIS

  $source->select(..., $result_as => [tsv => $filename]);

=head1 DESCRIPTION

Writes all resulting rows into a tab-separated flat file.
Tab or newline characters within the data will be converted to spaces.
If you need more control over such conversions, use
L<DBIx::DataModel::Schema::ResultAs::File_tabular> where you
can specify options for L<File::Tabular>.

