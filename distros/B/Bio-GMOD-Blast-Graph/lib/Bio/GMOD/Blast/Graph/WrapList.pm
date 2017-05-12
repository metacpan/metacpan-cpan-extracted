package Bio::GMOD::Blast::Graph::WrapList;
BEGIN {
  $Bio::GMOD::Blast::Graph::WrapList::AUTHORITY = 'cpan:RBUELS';
}
BEGIN {
  $Bio::GMOD::Blast::Graph::WrapList::VERSION = '0.06';
}
#####################################################################
#
# Cared for by Shuai Weng <shuai@genome.stanford.edu>
#
# Originally created by John Slenk <jces@genome.stanford.edu>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

use Bio::GMOD::Blast::Graph::BaseObj;
use Bio::GMOD::Blast::Graph::List;
use Bio::GMOD::Blast::Graph::ListEnumerator;
use Bio::GMOD::Blast::Graph::ScientificNotation;
use Bio::GMOD::Blast::Graph::HitWrapper;
use Bio::GMOD::Blast::Graph::MyUtils;
use Bio::GMOD::Blast::Graph::MyDebug qw( dmsg dmsgs );

@ISA = qw( Bio::GMOD::Blast::Graph::List );

sub pValueSorterIncreasing
{
    my( $cmp );
    my( $aP, $bP );

    $aP = $a->getP();
    $bP = $b->getP();
    $cmp = Bio::GMOD::Blast::Graph::ScientificNotation::cmp( $aP, $bP );

    return( $cmp );
}

sub mapHelper
{
    $_->getP();
}

sub sortByPValue
{
    my( $self ) = shift;
    my( @ray );

    @ray = @{$self->getElementsRef()};
    #dmsgs( "sortByPValue(): before = ", map( mapHelper, @ray ) );

    @ray = sort pValueSorterIncreasing @ray;
    #dmsgs( "sortByPValue(): after = ", map( mapHelper, @ray ) );

    $self->putElementsRef( \@ray );
}

# really, we're looking at the p value.
sub getLeastNonZeroElement
{
    my( $self ) = shift;
    my( $elem );
    my( $ref, $te );

    $ref = $self->getElementsRef();
    foreach $te ( @{$ref} )
    {
    if( ! Bio::GMOD::Blast::Graph::ScientificNotation::isZero( $te->getP() ) )
    {
        $elem = $te;
        last;
    }
    }

    return( $elem );
}

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Bio::GMOD::Blast::Graph::WrapList

=head1 AUTHORS

=over 4

=item *

Shuai Weng <shuai@genome.stanford.edu>

=item *

John Slenk <jces@genome.stanford.edu>

=item *

Robert Buels <rmb32@cornell.edu>

=item *

Jonathan "Duke" Leto <jonathan@leto.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by The Board of Trustees of Leland Stanford Junior University.

This is free software, licensed under:

  The Artistic License 1.0

=cut

