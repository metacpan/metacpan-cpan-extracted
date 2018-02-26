#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs::File_tabular;
#----------------------------------------------------------------------
use warnings;
use strict;
use Carp::Clan       qw[^(DBIx::DataModel::|SQL::Abstract)];
use File::Tabular;

use parent 'DBIx::DataModel::Schema::ResultAs';

use namespace::clean;

sub new {
  my $class = shift;

  my $self = {ft_args => \@_};
  return bless $self, $class;
}



sub get_result {
  my ($self, $statement) = @_;

  $statement->execute;
  $statement->make_fast;

  my @headers = $statement->headers;
  my @ft_args = @{$self->{ft_args}};
  push @ft_args, {} unless @ft_args && ref $ft_args[1];

  $ft_args[-1]{headers}      = [$statement->headers];
  $ft_args[-1]{printHeaders} = 1;

  my $ft = File::Tabular->new(@ft_args);
  my $n_rows = 0;
  while (my $row = $statement->next) {
    $ft->append($row);
    $n_rows += 1;
  }
  $statement->finish;

  return $n_rows;
}


1;


__END__

=head1 NAME

DBIx::DataModel::Schema::ResultAs::File_tabular - write rows in a tabular file

=head1 SYNOPSIS

  $source->select(..., -result_as => [file_tabular => $file_name, \%options]);

=head1 DESCRIPTION

Writes all rows into a flat file through the L<File::Tabular> module.


