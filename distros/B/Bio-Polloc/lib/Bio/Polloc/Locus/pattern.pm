=head1 NAME

Bio::Polloc::Locus::pattern - A loci matching a pattern.

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::Locus::pattern;
use base qw(Bio::Polloc::LocusI);
use strict;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 APPENDIX

Methods provided by the package

=head2 new

Initialization method.

=head3 Arguments

The generic arguments from L<Bio::Polloc::LocusI>, plus:

=over

=item -pattern I<str>

The query pattern (see L<Bio::Polloc::Rule::pattern>).

=item -score I<int>

The number of matched nucleotides.

=back

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head2 pattern

Gets/sets the query pattern.

=cut

sub pattern {
   my($self, $value) = @_;
   my $k = 'pattern';
   $self->{"_$k"} = $value if defined $value;
   return $self->{"_$k"};
}

=head2 score

Gets/sets the score (number of matched nucleotides).

=cut

sub score {
   my($self, $value) = @_;
   my $k = 'score';
   $self->{"_$k"} = $value+0 if defined $value;
   return $self->{"_$k"};
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _initialize

=cut

sub _initialize {
   my($self,@args) = @_;
   my($pattern, $score) = $self->_rearrange([qw(PATTERN SCORE)], @args);
   $self->type('pattern');
   $self->pattern($pattern);
   $self->score($score);
}

1;
