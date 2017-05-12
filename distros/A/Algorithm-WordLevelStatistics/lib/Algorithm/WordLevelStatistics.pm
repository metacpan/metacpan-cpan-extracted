# Copyright 2009 Francesco Nidito. All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Algorithm::WordLevelStatistics;

use strict;

use vars qw($VERSION);
$VERSION = '0.03';

sub new {
  my $class = shift;
  return bless {
                version => $VERSION,
               }, $class;
}

# computes the statistical level of a single word (given its spectrum and the total number of words in the text)
sub compute_spectrum {
  my ($self, $N, $s) = @_;

  my $n = @{$s};

  my $ls = { count => $n, C => 0, sigma_nor => 0 };
  if( $n > 3 ) {
    # position -> distance from preceding element in text
    my @tmp = ();
    for( my $i = 0; $i < ($n-1); ++$i ){ push @tmp, ($s->[$i+1] - $s->[$i]); }

    my ($avg, $sigma) = $self->_mean_and_variance( \@tmp );
    $sigma = sqrt($sigma)/$avg;

    # normalize sigma using an hypothetical uniform distribution
    my $p = $n/$N;
    $ls->{sigma_nor} = $sigma/sqrt(1.0-$p);

    # this is not simple:
    $ls->{C} = ($ls->{sigma_nor} - (2.0*$n-1.0)/(2.0*$n+2.0)) * ( sqrt($n)*(1.0+2.8*$n**-0.865) );
  }

  return $ls;
}

# computes the statistical level of a group of words (given their spectra)
sub compute_spectra {
  my ($self, $s) = @_;

  # count the total number of "words" in text
  my $N = 0;
  foreach my $i (keys(%{$s})){ $N += @{ $s->{$i} }; }

  # computes the level statistic for all terms
  my %r = ();
  foreach my $i (keys(%{$s})){
    $r{$i} = $self->compute_spectrum( $N, $s->{$i} );
  }

  return \%r;
}

# fast, on-line algorithm to compute mean and variance:
# http://en.wikipedia.org/wiki/Algorithms_for_calculating_variance#On-line_algorithm
sub _mean_and_variance {
  my ($self, $v) = @_;
  my ($n, $mean, $M2) = (0, 0, 0);

  foreach my $x (@{$v}) {
    $n++;
    my $delta = $x - $mean;
    $mean += $delta/$n;
    $M2 += $delta*($x - $mean);
  }

  my $variance = $M2/$n;

  return ($mean, $variance);
}
1;

__END__

=head1 NAME

Algorithm::WordLevelStatistics - Pure Perl implementation of the "words level statistics" algorithm

=head1 SYNOPSIS

 use Algorithm::WordLevelStatistics;
 my $wls = Algorithm::WordLevelStatistics->new;
 
 my %spectra = (); # hash from word to positions
 
 open IN, "<file.txt" or die "cannot open file.txt: $!";
 my $idx = 0;
 while(<IN>) {
   chomp;
   next if(m/^\s*$/); #skip blank lines
 
   foreach my $w ( split /\W/, lc( $_ ) ) {
     next if($w =~ m/^\s*$/);
     push @{ $spectra{$w} }, $idx++;
   }
 }
 close IN;
 
 my $ws = $wls->compute_spectra( \%spectra );
 
 # sort the words by their C attribute (the deviation of sigma_nor with respect to the expected value in a random text)
 my @sw = sort { $ws->{$b}->{C} <=> $ws->{$a}->{C} } keys( %{ $ws } );
 
 # print all the words with their scores
 foreach my $i (@sw) {
   print $i, " => { C = ",$ws->{$i}->{C}, ", count = ", $ws->{$i}->{count}, ", sigma_nor = ", $ws->{$i}->{sigma_nor}," }\n";
 }

=head1 DESCRIPTION

This module implements the word leval statistics algorithm as described in: P. Carpena, P. Bernaola-Galav, M. Hackenberg, A.V. Coronado and J.L. Oliver, "Level statistics of words: finding keywords in literary texts and DNA", Physical Review E 79, 035102-4 ( DOI: 10.1103/PhysRevE.79.035102 )

=head1 METHODS

=over 4

=item new()

Creates a new C<Algorithm::WordLevelStatistics> object and returns it.

=item compute_spectra()

The return value is a reference to an hash of hashes like the following one:

 {
   universe => {
                  C => 50.2020428972437,
                  count => 47,
                  sigma_nor => 6.16069263723295
               },
   x => {
          C => 47.1009427722911,
          count => 150,
          sigma_nor => 3.71679156784182
        }
  ...
 }

=item compute_spectrum()

The return value is a reference to an hash like the following one:

 {
   C => 50.2020428972437,
   count => 47,
   sigma_nor => 6.16069263723295
 }

=back

=head1 THEORY

The word level statistics algorithm uses a generalization of the level statistics analysis of quantum disordered systems to extract automatically keywords in literary texts.

The systems takes into account not only the relative frequencies of the words present in the text but also their spatial distribution in the text, and it is based on the consideration that relevant words are naturally clustered by the authors of the documents and irrelevant words are distributed randomly in the text (e.g. in an english text, the word 'the' is used with almost uniform distribution).

The word level statistics does not need a reference corpus but it uses just one document to extract the document's keywords. Moreover it is to be considered "language agnostic", because the algorithm does not need a "a priori" words classification (e.g. stop-words)


=head1 HISTORY

=over 4

=item 0.03

Corrected the test case (added test file to tarball.

=item 0.02

Removed the dependency from L<Statistics::Lite>.
The removal of the dependency make this a self contained Perl module.
The module is indeed faster too! (~15% speed improvement on large files).

=item 0.01

Initial version of the module

=back

=head1 AUTHOR

Francesco Nidito

=head1 COPYRIGHT

Copyright 2009 Francesco Nidito. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://bioinfo2.ugr.es/TextKeywords/>.

=cut
