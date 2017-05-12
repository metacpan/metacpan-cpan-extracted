package AI::Categorizer::Learner::Rocchio;
$VERSION = '0.01';

use strict;
use Params::Validate qw(:types);
use AI::Categorizer::FeatureVector;
use AI::Categorizer::Learner::Boolean;
use base qw(AI::Categorizer::Learner::Boolean);

__PACKAGE__->valid_params
  (
   positive_setting => {type => SCALAR, default => 16 },
   negative_setting => {type => SCALAR, default => 4  },
   threshold        => {type => SCALAR, default => 0.1},
  );

sub create_model {
  my $self = shift;
  foreach my $doc ($self->knowledge_set->documents) {
    $doc->features->normalize;
  }
  
  $self->{model}{all_features} = $self->knowledge_set->features(undef);
  $self->SUPER::create_model(@_);
  delete $self->{knowledge_set};
}

sub create_boolean_model {
  my ($self, $positives, $negatives, $cat) = @_;
  my $posdocnum = @$positives;
  my $negdocnum = @$negatives;
  
  my $beta = $self->{positive_setting};
  my $gamma = $self->{negative_setting};
  
  my $profile = $self->{model}{all_features}->clone->scale(-$gamma/$negdocnum);
  my $f = $cat->features(undef)->clone->scale( $beta/$posdocnum + $gamma/$negdocnum );
  $profile->add($f);

  return $profile->normalize;
}

sub get_boolean_score {
  my ($self, $newdoc, $profile) = @_;
  return $newdoc->features->normalize->dot($profile);
}

1;








