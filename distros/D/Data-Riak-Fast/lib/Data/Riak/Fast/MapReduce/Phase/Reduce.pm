package Data::Riak::Fast::MapReduce::Phase::Reduce;
use Mouse;

# ABSTRACT: Reduce phase of a MapReduce

extends 'Data::Riak::Fast::MapReduce::Phase::Map';

has phase => (
  is => 'ro',
  isa => 'Str',
  default => 'reduce'
);

=head1 DESCRIPTION

A map/reduce map phase for Data::Riak::Fast.  See L<Data::Riak::Fast::MapReduce::Phase::Reduce>
for attribute information.

=head1 SYNOPSIS

  my $mp = Data::Riak::Fast::MapReduce::Phase::Map->new(
    language => "javascript", # The default
    source => "function(v) { return [ v ] }",
    keep => 1 # The default
  );

=cut

1;
