# *%) $Id: MinimumPhredFilter.pm,v 1.5 2004/10/15 22:30:46 scottz Exp $
#
# Copyright (c) 2004 Scott Zuyderduyn <scottz@bccrc.ca>.
# All rights reserved. This program is free software; you
# can redistribute it and/or modify it under the same
# terms as Perl itself.

package Bio::SAGE::DataProcessing::MinimumPhredFilter;

=pod

=head1 NAME

Bio::SAGE::DataProcessing::MinimumPhredFilter - A filter that validates sequences based on minimum Phred score.

=head1 SYNOPSIS

  use Bio::SAGE::DataProcessing::MinimumPhredFilter;
  $filter = new Bio::SAGE::DataProcessing::MinimumPhredFilter->new( 20 );

=head1 DESCRIPTION

This module is a concrete subclass of Bio::SAGE::DataProcessing::Filter.
The implementation considers a sequence valid if all nucleotides have
a Phred score that exceeds that specified for the filter.

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

my $PACKAGE = "Bio::SAGE::DataProcessing::MinimumPhredFilter";

=pod

=head1 CLASS METHODS

=cut

#######################################################
sub new {
#######################################################
=pod

=head2 new $minPhred

Constructor.

B<Arguments>

I<$minPhred>

  The minimum phred value that all nucleotides in a
  sequence must have in order to be considered valid.

B<Usage>

  my $filter = Bio::SAGE::DataProcessing::MinimumPhredFilter->new( 20 );
  if( $filter->is_tag_valid( "AAAAAAAAAA" ) ) {
      print "VALID!\n";
  }

=cut

    my $class = shift;
    $class->SUPER::new( @_ );

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
  if( $filter->is_tag_valid( "AAAAAAAAAA" ) ) {
      print "VALID!\n";
  }

=cut

    my $this = shift;
    my $sequence = shift || die( $PACKAGE . "::is_valid no sequence defined." );
    my $scores = shift;

    if( $Bio::SAGE::DataProcessing::DEBUG >= 1 ) {
        print STDERR $PACKAGE . "::is_valid looking at " . $scores . "\n";
    }

    if( !defined( $scores ) ) { return 1; }

    my $min_phred = $this->{'args'}[0];

    if( $min_phred == 0 ) {
        if( $Bio::SAGE::DataProcessing::DEBUG >= 1 ) {
            print STDERR $PACKAGE . "::is_valid no need to check, minimum phred is 0\n";
        }
        return 1;
    }

    my @scores = split( /\s/, $scores );
    foreach my $score ( @scores ) {
        if( $score < $min_phred ) {
            if( $Bio::SAGE::DataProcessing::DEBUG >= 1 ) {
                print STDERR $PACKAGE . "::is_valid $score does not meet minimum $min_phred\n";
            }
            return 0;
        }
    }

    if( $Bio::SAGE::DataProcessing::DEBUG >= 1 ) {
        print STDERR $PACKAGE . "::is_valid scores passed\n";
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
