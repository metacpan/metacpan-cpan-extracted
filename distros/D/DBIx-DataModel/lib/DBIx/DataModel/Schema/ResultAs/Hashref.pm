#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs::Hashref;
#----------------------------------------------------------------------
use warnings;
use strict;
use DBIx::DataModel::Carp;

use parent 'DBIx::DataModel::Schema::ResultAs';

use namespace::clean;

sub new {
  my $class = shift;

  my $self;

  if ((ref $_[0] || '') eq 'CODE') {
    $self = {make_key => shift};
    !@_ or croak "-result_as => [hashref => sub {...}] : improper other args after sub{}";
  }
  else {
    $self = {cols => \@_};
  }

  return bless $self, $class;
}


sub get_result {
  my ($self, $statement) = @_;

  my $make_key = $self->{make_key} || do {
    my @cols = @{$self->{cols}};
    @cols = $statement->meta_source->primary_key              if !@cols;
    croak "-result_as=>'hashref' impossible: no primary key"  if !@cols;
    sub {my $row = shift; map {defined $row->{$_} ? $row->{$_} : ''} @cols};
  };

  $statement->execute;

  my %hash;
  while (my $row = $statement->next) {
    my @key = $make_key->($row);
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

  my $tree = $source->select(..., -result_as => 'hashref');
  # or
  my $tree = $source->select(..., -result_as => [hashref => ($column1, ...)]);
  # or
  my $tree = $source->select(..., -result_as => [hashref => sub {...}]);

=head1 DESCRIPTION

Returns a nested tree of hashrefs; leaves of the tree are data rows,
and keys of the hashes are column values. The depth of the tree corresponds
to the number of columns given as argument. In most cases there is just one
single column, so the result is just an ordinary hashref.

This C<-result_as> is normally used only in situations where the key
fields values for each row are unique. If multiple rows are returned
with the same values for the key fields then later rows overwrite
earlier ones.

Instead of a list of column names, the argument can be a reference
to a subroutine. That subroutine will we called
for each row and should return a list of scalar values to be used as hash keys.


In absence of column or S<sub> arguments, the primary
key of the $source will be used.






