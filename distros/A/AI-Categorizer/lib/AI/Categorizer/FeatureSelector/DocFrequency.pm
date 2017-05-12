package AI::Categorizer::FeatureSelector::DocFrequency;

use strict;
use AI::Categorizer::FeatureSelector;
use base qw(AI::Categorizer::FeatureSelector);

use Params::Validate qw(:types);
use Carp qw(croak);

__PACKAGE__->contained_objects
  (
   features => { class => 'AI::Categorizer::FeatureVector',
		 delayed => 1 },
  );

# The KnowledgeSet keeps track of document frequency, so just use that.
sub rank_features {
  my ($self, %args) = @_;
  
  my $k = $args{knowledge_set} or die "No knowledge_set parameter provided to rank_features()";
  
  my %freq_counts;
  foreach my $name ($k->features->names) {
    $freq_counts{$name} = $k->document_frequency($name);
  }
  return $self->create_delayed_object('features', features => \%freq_counts);
}

sub scan_features {
  my ($self, %args) = @_;
  my $c = $args{collection} or die "No 'collection' parameter provided to scan_features()";

  my $doc_freq = $self->create_delayed_object('features');
  
  while (my $doc = $c->next) {
    $args{prog_bar}->() if $args{prog_bar};
    $doc_freq->add( $doc->features->as_boolean_hash );
  }
  print "\n" if $self->verbose;
  
  return $self->reduce_features($doc_freq);
}

1;

__END__

=head1 NAME

AI::Categorizer::FeatureSelector - Abstract Feature Selection class

=head1 SYNOPSIS

 ...

=head1 DESCRIPTION

The KnowledgeSet class that provides an interface to a set of
documents, a set of categories, and a mapping between the two.  Many
parameters for controlling the processing of documents are managed by
the KnowledgeSet class.

=head1 METHODS

=over 4

=item new()

Creates a new KnowledgeSet and returns it.  Accepts the following
parameters:
