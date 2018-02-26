#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs::Hashref;
#----------------------------------------------------------------------
use warnings;
use strict;
use Carp::Clan       qw[^(DBIx::DataModel::|SQL::Abstract)];

use parent 'DBIx::DataModel::Schema::ResultAs';

use namespace::clean;

sub new {
  my $class = shift;

  my $self = {cols => \@_};
  return bless $self, $class;
}


sub get_result {
  my ($self, $statement) = @_;

  my @cols = @{$self->{cols}};
  @cols = $statement->meta_source->primary_key              if !@cols;
  croak "-result_as=>'hashref' impossible: no primary key"  if !@cols;

  $statement->execute;

  my %hash;
  while (my $row = $statement->next) {
    my @key = map {defined $row->{$_} ? $row->{$_} : ''} @cols;
    my $last_key_item = pop @key;
    my $node          = \%hash;
    $node = $node->{$_} ||= {} foreach @key;
    $node->{$last_key_item} = $row;
  }
  $statement->finish;
  return \%hash;
}


1;

__END__

=head1 NAME

DBIx::DataModel::Schema::ResultAs::Hashref - arrange data rows in a hash

=head1 SYNOPSIS

  $source->select(..., -result_as => 'hashref');
  # or
  $source->select(..., -result_as => [hashref => ($key1, ...)]);

=head1 DESCRIPTION

The result will be a hashref. Keys in the hash correspond to distinct
values of the specified columns, and values are data row objects.
If the argument is given as C<< [hashref => @cols] >>, the column(s)
are specified by the caller; otherwise if the argument is given
as a simple string, C<@cols> will default to C<< $source->primary_key >>.
If there is more than one column, the result will be a tree of nested hashes.
This C<-result_as> is normally used only where the key fields values 
for each row are unique. If multiple rows are returned with the same
values for the key fields then later rows overwrite earlier ones.




