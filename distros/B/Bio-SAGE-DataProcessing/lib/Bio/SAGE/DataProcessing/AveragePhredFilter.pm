# *%) $Id: AveragePhredFilter.pm,v 1.6 2004/10/15 22:30:46 scottz Exp $
#
# Copyright (c) 2004 Scott Zuyderduyn <scottz@bccrc.ca>.
# All rights reserved. This program is free software; you
# can redistribute it and/or modify it under the same
# terms as Perl itself.

package Bio::SAGE::DataProcessing::AveragePhredFilter;

=pod

=head1 NAME

Bio::SAGE::DataProcessing::AveragePhredFilter - A filter that validates sequences based on average Phred score.

=head1 SYNOPSIS

  use Bio::SAGE::DataProcessing::AveragePhredFilter;
  $filter = new Bio::SAGE::DataProcessing::AveragePhredFilter->new( 30, 15 );

=head1 DESCRIPTION

This module is a concrete subclass of Bio::SAGE::DataProcessing::Filter.
The implementation considers a sequence valid if the average quality of
all nucleotides meet a given value.

=head1 INSTALLATION

Included with Bio::SAGE::DataProcessing.

=head1 PREREQUISITES

This module requires the C<Bio::SAGE::DataProcessing::Filter> package.

=head1 CHANGES

  1.10 2004.06.19 - Initial release.
  0.01 2004.05.02 - prototype

=cut

use Bio::SAGE::DataProcessing::Filter;
use base qw( Bio::SAGE::DataProcessing::Filter );
use strict;
use diagnostics;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK );

#require Exporter;
#require AutoLoader;

#@ISA = qw( Exporter AutoLoader );
@ISA = qw( Bio::SAGE::DataProcessing::Filter );
@EXPORT = qw();
$VERSION = $Bio::SAGE::DataProcessing::VERSION;

my $PACKAGE = "Bio::SAGE::DataProcessing::AveragePhredFilter";

=pod

=head1 CLASS METHODS

=cut

#######################################################
sub new {
#######################################################
=pod

=head2 new $avgPhred, <$minPhred>

Constructor.

B<Arguments>

I<$avgPhred>

  The average phred value of all nucleotides required
  for a sequence to be considered valid.

I<$minPhred> (optional)

  The minimum phred value that all nucleotides in a
  sequence must have in order to be considered valid.
  The default value if this argument is not specified
  is 0.

B<Usage>

  my $filter = Bio::SAGE::DataProcessing::MinimumPhredFilter->new( 30, 20 );
  if( $filter->is_tag_valid( "AAAAAA", "20 40 40 40 30 35" ) ) {
      print "VALID!\n";
  }

=cut

    my $class = shift;
    return $class->SUPER::new( @_ );

}

=pod

=head1 INSTANCE METHODS

=cut

#######################################################
sub is_valid {
#######################################################
=pod

=head2 is_valid $sequence, $scores

This implements the is_valid subroutine required
in concrete subclasses of Bio::SAGE::DataProcessing::Filter.

B<Arguments>

I<$sequence>

  The tag sequence.

I<$scores>

  A space-separated string of Phred scores for the
  specified sequence.

B<Returns>

  Returns non-zero if the valid, zero if invalid.

B<Usage>

  my $filter = Bio::SAGE::DataProcessing::MinimumPhredFilter->new();
  if( $filter->is_tag_valid( "AAAAAA", "20 40 40 40 30 35" ) ) {
      print "VALID!\n";
  }

=cut

    my $this = shift;
    my $sequence = shift || die( $PACKAGE . "::is_valid no sequence defined." );
    my $scores = shift; # || die( $PACKAGE . "::is_valid no scores defined." );

    if( !defined( $scores ) ) { return 1; } # force valid

    if( $Bio::SAGE::DataProcessing::DEBUG >= 1 ) {
        print STDERR $PACKAGE . "::is_valid looking at " . $scores . "\n";
    }

    my $min_avg_phred = $this->{'args'}[0];
    my $min_phred = $this->{'args'}[1];

    my $avg = 0;

    my @scores = split( /\s/, $scores );
    foreach my $score ( @scores ) {
        if( $score < $min_phred ) {
            if( $Bio::SAGE::DataProcessing::DEBUG >= 1 ) {
                print STDERR "    $score does not meet minimum $min_phred\n";
            }
            return 0;
        }
        $avg += $score;
    }
    $avg /= scalar( @scores );

    if( $avg < $min_avg_phred ) {
        if( $Bio::SAGE::DataProcessing::DEBUG >= 1 ) {
            print STDERR "    $avg does not meet minimum avg. phred $min_avg_phred\n";
        }
        return 0;
    }

    return 1;

}

#######################################################
#######################################################
=pod

=head2 compare $scores1, $scores2

The default implementation provided by the base class
Bio::SAGE::DataProcessing::Filter is used.  See the
documentation for the base class for more information.

=cut

1;

__END__

=head1 COPYRIGHT

Copyright(c)2004 Scott Zuyderduyn <scottz@bccrc.ca>. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Scott Zuyderduyn <scottz@bccrc.ca>
BC Cancer Research Centre

=head1 VERSION

  1.20

=head1 SEE ALSO

  Bio::SAGE::DataProcessing(1).
  Bio::SAGE::DataProcessing::Filter(1).

=head1 TODO

  Nothing yet.

=cut
