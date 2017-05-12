package Bio::GMOD::Blast::Graph::BucketSet;
BEGIN {
  $Bio::GMOD::Blast::Graph::BucketSet::AUTHORITY = 'cpan:RBUELS';
}
BEGIN {
  $Bio::GMOD::Blast::Graph::BucketSet::VERSION = '0.06';
}
#####################################################################
#
# Cared for by Shuai Weng <shuai@genome.stanford.edu>
#
# Originally created by John Slenk <jces@genome.stanford.edu>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

use Carp;

use Bio::GMOD::Blast::Graph::BaseObj;
use Bio::GMOD::Blast::Graph::IntSpan;
use Bio::GMOD::Blast::Graph::Bucket;
use Bio::GMOD::Blast::Graph::MyUtils;
use Bio::GMOD::Blast::Graph::MyDebug qw( dmsg );

@ISA = qw( Bio::GMOD::Blast::Graph::BaseObj );

#
# used to keep track of exploded HSPs from
# one Bio::GMOD::Blast::Graph::HitWrapper. the HSPs are
# split into as many lines as required
# to make sure they aren't overlapping.
#

my( $kBucketList ) =
  Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "bucket", "list" );

##################################################################
sub init {
##################################################################
    my( $self ) = shift;

    # note that they aren't stored in
    # any kind of sorted order; we
    # always do a linear search.
    $self->{ $kBucketList } = new Bio::GMOD::Blast::Graph::List();
}

##################################################################
sub getBucketList {
##################################################################
    my( $self ) = shift;
    return( $self->{ $kBucketList } );
}

##################################################################
sub getCount {
##################################################################
    my( $self ) = shift;

    return( $self->getBucketList()->getCount() );
}

##################################################################
sub addBucket {
##################################################################
    my( $self, $bucket ) = @_;
    my( $bucketList ) = $self->getBucketList();

    #dmsg( "addBucket(): bucket = " . $bucket->toString() );
    #dmsg( "addBucket(): this = $self, bucketList = $bucketList" );
    #dmsg( "addBucket(): before = " . join( ", ", @{$bucketList->getElementsRef()} ) );
    $bucketList->addElement( $bucket );
    #dmsg( "addBucket(): after = " . join( ", ", @{$bucketList->getElementsRef()} ) );
}

##################################################################
sub addRegion {
##################################################################X
    my( $self, $region ) = @_;
    my( $bucket );

    $bucket = $self->findNonIntersectingBucket( $region );
    if( defined($bucket) )
    {
    #dmsg( "addRegion(): adding " . $region->run_list() . " to bucket = " . $bucket->toString() );
    $bucket->addRegion( $region );
    }
    else
    {
    #dmsg( "addRegion(): no good bucket, creating " . $region->run_list() );
    $bucket = new Bio::GMOD::Blast::Graph::Bucket( $region );
    $self->addBucket( $bucket );
    }
}

##################################################################
sub findNonIntersectingBucket {
##################################################################
    my( $self ) = shift;
    my( $region ) = shift;

    my( $bucketList ) = $self->getBucketList();
    my( $foundP ) = 0;
    my( $testBucket );
    my( $match );
    my( $dex );

    #dmsg( "findNonIntersectingBucket(): region = " . $region->run_list() );

    for( $dex = 0;
     $dex < $bucketList->getCount() && !$foundP;
     $dex++ )
    {
    $testBucket = $bucketList->getElementAt( $dex );
    #dmsg( "findNonIntersectingBucket(): test = " . $testBucket->toString() );

    if( $testBucket->disjointP( $region ) )
    {
        $match = $testBucket;
        $foundP = 1;
    }
    }

    return( $match );
}

##################################################################
1;
##################################################################

__END__
=pod

=encoding utf-8

=head1 NAME

Bio::GMOD::Blast::Graph::BucketSet

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

