# *%) $Id: Filter.pm,v 1.7 2004/10/15 22:30:46 scottz Exp $
#
# Copyright (c) 2004 Scott Zuyderduyn <scottz@bccrc.ca>.
# All rights reserved. This program is free software; you
# can redistribute it and/or modify it under the same
# terms as Perl itself.

package Bio::SAGE::DataProcessing::Filter;

=pod

=head1 NAME

Bio::SAGE::DataProcessing::Filter - An abstract filter for determining whether a [di]tag is worth keeping.

=head1 SYNOPSIS

  use Bio::SAGE::DataProcessing::Filter;
  $filter = Bio::SAGE::DataProcessing::Filter->new();

=head1 DESCRIPTION

This module encapsulates an abstract filtering procedure
that is used during library processing with
Bio::SAGE::DataProcessing.  For example, a concrete
implementation might indicate a tag is not worth keeping
because the Phred scores are too low.

=head1 INSTALLATION

Included with Bio::SAGE::DataProcessing.

=head1 PREREQUISITES

This module requires the C<Bio::SAGE::DataProcessing> package.

=head1 CHANGES

  1.10 2004.06.19 - Initial release.
  0.01 2004.05.02 - prototype

=cut

use strict;
use diagnostics;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK $PROTOCOL_SAGE $PROTOCOL_LONGSAGE $DEBUG $ENZYME_NLAIII $ENZYME_SAU3A );

require Exporter;
require AutoLoader;

@ISA = qw( Exporter AutoLoader );
@EXPORT = qw();
$VERSION = $Bio::SAGE::DataProcessing::VERSION;

my $PACKAGE = "Bio::SAGE::DataProcessing::Filter";

=pod

=head1 VARIABLES

B<Globals>

=over 2

I<$PROTOCOL_SAGE>

  Hashref containing protocol parameters for the
  regular/original SAGE protocol (see set_protocol
  documentation for more information).

I<$PROTOCOL_LONGSAGE>

  Hashref containing protocol parameters for the
  LongSAGE protocol (see set_protocol documentation
  for more information).

=back

B<Settings>

=over 2

I<$DEBUG = 0>

  Prints debugging output if value if >= 1.

=back

=cut

$DEBUG = 0; # set this flag to non-zero to enable debugging messages

=pod

=head1 CLASS METHODS

=cut

#######################################################
sub new {
#######################################################
=pod

=head2 new [$arg1,$arg2,...]

Constructor for a new Bio::SAGE::DataProcessing::Filter
object.

B<Arguments>

I<$arg1,$arg2,...> (optional)

  Any arguments can be specified.  These are stored in
  the 'args' hash element (ie. $self->{'args'}).  Concrete
  subclasses must call this constructor explictly from
  within their constructor.

    i.e. $class->SUPER::new( @_ );

  The required parameters are dependent on the
  concrete implementation of a Filter.

B<Usage>

  Not explicitly called.

=cut

    my $this = shift;
    my $class = ref( $this ) || $this;
    my $self = {};
    bless( $self, $class );

    $self->{'args'} = \@_;

    return $self;

}

=pod

=head1 INSTANCE METHODS

=cut

#######################################################
sub is_valid {
#######################################################
=pod

=head2 is_valid $sequence, <\@scores>

This method must be implementated by the developer
in a concrete subclass.  The contract of this method
is to return a boolean value indicating whether the
tag is valid or not.

The subclass implementation should always work for
cases where the \@scores argument is not provided
(i.e. !defined(\@scores)).

B<Arguments>

I<$sequence>

  The tag sequence.

I<\@scores> (optional)

  An arrayref to scores for this tag (it should be
  assumed that the quality scores for the leading
  anchoring enzyme site nucleotides are included).

B<Usage>

  my $filter = Bio::SAGE::DataProcessing::Filter->new();
  if( $filter->is_tag_valid( "AAAAAAAAAA" ) ) {
      print "VALID!\n";
  }

=cut

    my $this = shift;

    die( $PACKAGE . "::is_tag_valid needs to implemented by concrete subclass." );

}

#######################################################
sub compare {
#######################################################
=pod

=head2 compare $scores1, $scores2

This method determines which set of scores is "better"
(defined by the implementation).

This method can be overridden by the developer in a
subclass.  The default method chooses the scores that
have the highest cumulative sum.

B<Arguments>

I<$scores1,$scores2>

  Space-separated strings of Phred scores (for example,
  "20 20 25 12 35").

B<Returns>

  Returns <0 if the first scores are best, >0 if
  the second scores are best, and 0 if the two
  score sets are equivalent.

B<Usage>

  my $filter = Bio::SAGE::DataProcessing::Filter->new();
  my $res = $filter->compare( "20 20 20", "40 40 40" );
  if( $res == -1 ) { # this would be the result in this example
    print "First set is better.\n";
  }
  if( $res == +1 ) {
    print "Second set is better.\n";
  }
  if( $res == 0 ) {
    print "Both sets are equivalent.\n";
  }

=cut

    my $this = shift;
    my $score1 = shift;
    my $score2 = shift;

    my @scores1 = split( /\s/, $score1 );
    my @scores2 = split( /\s/, $score2 );

    if( scalar( @scores1 ) != scalar( @scores2 ) ) {
        die( $PACKAGE . "::compare can't compare score sets of different size." );
    }

    my $sum1 = 0;
    my $sum2 = 0;
    for( my $i = 0; $i < scalar( @scores1 ); $i++ ) {
        $sum1 += $scores1[$i];
        $sum2 += $scores2[$i];
    }

    return ( $sum1 == $sum2 ? 0 : ( $sum1 > $sum2 ? -1 : 1 ) );

}

1;

__END__

=pod

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

=head1 TODO

  Nothing yet.

=cut
