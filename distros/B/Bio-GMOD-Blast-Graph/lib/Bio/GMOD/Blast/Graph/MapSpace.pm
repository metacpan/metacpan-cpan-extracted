package Bio::GMOD::Blast::Graph::MapSpace;
BEGIN {
  $Bio::GMOD::Blast::Graph::MapSpace::AUTHORITY = 'cpan:RBUELS';
}
BEGIN {
  $Bio::GMOD::Blast::Graph::MapSpace::VERSION = '0.06';
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
use Bio::GMOD::Blast::Graph::MyUtils;
use Bio::GMOD::Blast::Graph::MapDefs;
use Bio::GMOD::Blast::Graph::HitWrapper;
use Bio::GMOD::Blast::Graph::MyDebug qw( assert dmsg );

@ISA = qw( Bio::GMOD::Blast::Graph::BaseObj );

my $kInitialSpace =
  Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "initial", "space" );
my $kSpaceRemaining =
  Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "space", "remaining" );
my $kFullP =
  Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "full", "predicate" );

#######################################################################
sub init {
#######################################################################
    my( $self ) = shift;

    $self->{ $kInitialSpace } =
    $self->{ $kSpaceRemaining } =
        ($Bio::GMOD::Blast::Graph::MapDefs::imgHeight -
         $Bio::GMOD::Blast::Graph::MapDefs::hspPosInit -
         $Bio::GMOD::Blast::Graph::MapDefs::imgBottomBorder );

    #dmsg( "init(): space = ", $self->getSpaceRemaining() );
}

#######################################################################
sub getSpaceRemaining {
#######################################################################
    my( $self ) = shift;
    return( $self->{ $kSpaceRemaining } );
}

#######################################################################
sub getSpaceUsed {
#######################################################################
    my( $self ) = shift;
    return( $self->{ $kInitialSpace } - $self->{ $kSpaceRemaining } );
}

#######################################################################
sub putSpaceRemaining {
#######################################################################
    my( $self, $space ) = @_;
    assert( $space >= 0, "space must be non-negative" );
    $self->{ $kSpaceRemaining } = $space;
}

# return true iff the last call to wrapperFitsP returned false.
#######################################################################
sub getFullP {
#######################################################################
    my( $self ) = shift;
    return( $self->{ $kFullP } );
}

#######################################################################
sub putFullP {
#######################################################################
    my( $self, $fp ) = @_;
    $self->{ $kFullP } = $fp;
}

#######################################################################
sub wrapperFitsP {
#######################################################################
    my( $self, $wrap ) = @_;
    my( $space );
    my( $wheight );
    my( $fitsP );

    $space = $self->getSpaceRemaining();

    $wheight = $wrap->getHSPLineCount() * $Bio::GMOD::Blast::Graph::MapDefs::hspHeight;
    if( $wheight <= $space )
    {
    $fitsP = 1;
    #dmsg( "wrapperFitsP(): $wheight <= $space" );
    }
    else
    {
    $fitsP = 0;
    #dmsg( "wrapperFitsP(): $wheight > $space" );
    }

    $self->{ $kFullP } = (! $fitsP);

    return( $fitsP );
}

#######################################################################
sub updateFromWrapper {
#######################################################################
    my( $self, $wrap ) = @_;
    my( $space );
    my( $count );
    my( $wheight );

    $space = $self->getSpaceRemaining();
    $count = $wrap->getHSPLineCount();
    $wheight = $count * $Bio::GMOD::Blast::Graph::MapDefs::hspHeight;
    #dmsg( "updateFromWrapper(): ", $wrap->getName(), "$count $wheight" );

    assert( $wheight <= $space, "not enough space left" );

    $self->putSpaceRemaining( $space - $wheight );
}

#######################################################################
1;
#######################################################################

__END__
=pod

=encoding utf-8

=head1 NAME

Bio::GMOD::Blast::Graph::MapSpace

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

