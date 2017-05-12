package AI::Categorizer::FeatureSelector::CategorySelector;

use strict;
use AI::Categorizer::FeatureSelector;
use base qw(AI::Categorizer::FeatureSelector);

use Params::Validate qw(:types);

__PACKAGE__->contained_objects
  (
   features => { class => 'AI::Categorizer::FeatureVector',
		 delayed => 1 },
  );

1;


sub reduction_function;

# figure out the feature set before reading collection (default)

sub scan_features {
  my ($self, %args) = @_;
  my $c = $args{collection} or 
    die "No 'collection' parameter provided to scan_features()";

  if(!($self->{features_kept})) {return;}

  my %cat_features;
  my $coll_features = $self->create_delayed_object('features');
  my $nbDocuments = 0;

  while (my $doc = $c->next) {
    $nbDocuments++;
    $args{prog_bar}->() if $args{prog_bar};
    my $docfeatures = $doc->features->as_hash;
    foreach my $cat ($doc->categories) {
      my $catname = $cat->name;
      if(!(exists $cat_features{$catname})) {
        $cat_features{$catname} = $self->create_delayed_object('features');
      }
      $cat_features{$catname}->add($docfeatures);
    }
    $coll_features->add( $docfeatures );
  }
  print STDERR "\n* Computing Chi-Square values\n" if $self->verbose;

  my $r_features = $self->create_delayed_object('features');
  my @terms = $coll_features->names;
  my $progressBar = $self->prog_bar(scalar @terms);
  my $allFeaturesSum = $coll_features->sum;
  my %cat_features_sum;
  while( my($catname,$features) = each %cat_features ) {
    $cat_features_sum{$catname} = $features->sum;
  }

  foreach my $term (@terms) {
    $progressBar->();
    $r_features->{features}{$term} = $self->reduction_function($term,
      $nbDocuments,$allFeaturesSum,$coll_features,
      \%cat_features,\%cat_features_sum);
  }
  print STDERR "\n" if $self->verbose;
  my $new_features = $self->reduce_features($r_features);
  return $coll_features->intersection( $new_features );
}


# calculate feature set after reading collection (scan_first=0)

sub rank_features {
  die "CategorySelector->rank_features is not implemented yet!";
#  my ($self, %args) = @_;
#  
#  my $k = $args{knowledge_set} 
#    or die "No knowledge_set parameter provided to rank_features()";
#
#  my %freq_counts;
#  foreach my $name ($k->features->names) {
#    $freq_counts{$name} = $k->document_frequency($name);
#  }
#  return $self->create_delayed_object('features', features => \%freq_counts);
}


# copied from KnowledgeSet->prog_bar by Ken Williams

sub prog_bar {
  my ($self, $count) = @_;

  return sub {} unless $self->verbose;
  return sub { print STDERR '.' } unless eval "use Time::Progress; 1";

  my $pb = 'Time::Progress'->new;
  $pb->attr(max => $count);
  my $i = 0;
  return sub {
    $i++;
    return if $i % 25;
    print STDERR $pb->report("%50b %p ($i/$count)\r", $i);
  };
}


__END__

=head1 NAME

AI::Categorizer::CategorySelector - Abstract Category Selection class

=head1 SYNOPSIS

This class is abstract. For example of instanciation, see
ChiSquare.

=head1 DESCRIPTION

A base class for FeatureSelectors that calculate their global features
from a set of features by categories.

=head1 METHODS

=head1 AUTHOR

Francois Paradis, paradifr@iro.umontreal.ca
with inspiration from Ken Williams AI::Categorizer code

=cut
