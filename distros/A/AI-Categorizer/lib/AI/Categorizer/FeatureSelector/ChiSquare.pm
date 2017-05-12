package AI::Categorizer::FeatureSelector::ChiSquare;

use strict;
use AI::Categorizer::FeatureSelector;
use base qw(AI::Categorizer::FeatureSelector::CategorySelector);

use Params::Validate qw(:types);

# Chi-Square function
# NB: this could probably be optimised a bit...

sub reduction_function {
  my ($self,$term,$N,$allFeaturesSum,
      $coll_features,$cat_features,$cat_features_sum) = @_;
  my $CHI2SUM = 0;
  my $nbcats = 0;
  foreach my $catname (keys %{$cat_features}) {
#  while ( my ($catname,$catfeatures) = each %{$cat_features}) {
    my ($A,$B,$C,$D); # A = number of times where t and c co-occur
                      # B =   "     "   "   t occurs without c
                      # C =   "     "   "   c occurs without t
                      # D =   "     "   "   neither c nor t occur
    $A = $cat_features->{$catname}->value($term);
    $B = $coll_features->value($term) - $A;
    $C = $cat_features_sum->{$catname} - $A;
    $D = $allFeaturesSum - ($A+$B+$C);
    my $ADminCB = ($A*$D)-($C*$B);
    my $CHI2 = $N*$ADminCB*$ADminCB / (($A+$C)*($B+$D)*($A+$B)*($C+$D));
    $CHI2SUM += $CHI2;
    $nbcats++;
  }
  return $CHI2SUM/$nbcats;
}

1;

__END__

=head1 NAME

AI::Categorizer::FeatureSelector::ChiSquare - ChiSquare Feature Selection class

=head1 SYNOPSIS

 # the recommended way to use this class is to let the KnowledgeSet
 # instanciate it

 use AI::Categorizer::KnowledgeSetSMART;
 my $ksetCHI = new AI::Categorizer::KnowledgeSetSMART(
   tfidf_notation =>'Categorizer',
   feature_selection=>'chi_square', ...other parameters...); 

 # however it is also possible to pass an instance to the KnowledgeSet

 use AI::Categorizer::KnowledgeSet;
 use AI::Categorizer::FeatureSelector::ChiSquare;
 my $ksetCHI = new AI::Categorizer::KnowledgeSet(
   feature_selector => new ChiSquare(features_kept=>2000,verbose=>1),
   ...other parameters...
   );

=head1 DESCRIPTION

Feature selection with the ChiSquare function.

  Chi-Square(t,ci) = (N.(AD-CB)^2)
                    -----------------------
                    (A+C).(B+D).(A+B).(C+D)

where t = term
      ci = category i
      N = number of documents in the collection
      A = number of times where t and c co-occur
      B =   "     "   "   t occurs without c
      C =   "     "   "   c occurs without t
      D =   "     "   "   neither c nor t occur

for more details, see :
Yiming Yang, Jan O. Pedersen, A Comparative Study on Feature Selection 
in Text Categorization, in Proceedings of ICML-97, 14th International 
Conference on Machine Learning, 1997.
(available on citeseer.nj.nec.com)

=head1 METHODS

=head1 AUTHOR

Francois Paradis, paradifr@iro.umontreal.ca
with inspiration from Ken Williams AI::Categorizer code

=cut

