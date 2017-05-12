package Bio::GMOD::Blast::Graph::HitWrapper;
BEGIN {
  $Bio::GMOD::Blast::Graph::HitWrapper::AUTHORITY = 'cpan:RBUELS';
}
BEGIN {
  $Bio::GMOD::Blast::Graph::HitWrapper::VERSION = '0.06';
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
use Bio::GMOD::Blast::Graph::MyDebug qw( assert dmsg );
use Bio::GMOD::Blast::Graph::BucketSet;
use Bio::GMOD::Blast::Graph::IntSpan;
use Bio::GMOD::Blast::Graph::ScientificNotation;

@ISA = qw( Bio::GMOD::Blast::Graph::BaseObj );

##################################################################
my $kHit
    = Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "hit" );
my $kForwardHSPs
    = Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "forward", "hsps" );
my $kReverseHSPs
    = Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "reverse", "hsps" );
my $kSortedP
    = Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "sorted", "predicate" );
my $kLineCount
    = Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "line", "count" );
my $kForwardBucketSet
    = Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "forward", "bucket", "set" );
my $kReverseBucketSet
    = Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "reverse", "bucket", "set" );

#################################################################
#
# instance stuff.
#

#################################################################
sub init {
#################################################################
    my( $self, $hit ) = @_;

    $self->{ $kHit } = $hit;
    $self->{ $kForwardHSPs } = new Bio::GMOD::Blast::Graph::List();
    $self->{ $kReverseHSPs } = new Bio::GMOD::Blast::Graph::List();

    $self->{ $kSortedP } = 0;
    $self->sortHSPs();

    $self->{ $kForwardBucketSet } = new Bio::GMOD::Blast::Graph::BucketSet();
    $self->{ $kReverseBucketSet } = new Bio::GMOD::Blast::Graph::BucketSet();
    $self->calculateHSPLineCount();
}

#################################################################
sub toString {
#################################################################
    my( $self ) = shift;
    my( $str );

    $str = Bio::GMOD::Blast::Graph::MyUtils::makeDumpString($self,
                          $self->getName(),
                          $self->getP(),
                          $self->getScore());

    return( $str );
}

#################################################################
sub getForwardBucketSet {
#################################################################
    my( $self ) = shift;
    return( $self->{ $kForwardBucketSet } );
}

#################################################################
sub getReverseBucketSet {
#################################################################
    my( $self ) = shift;

    return( $self->{ $kReverseBucketSet } );

}

#################################################################
sub getHit {
#################################################################
    my( $self ) = shift;

    return( $self->{ $kHit } );

}

#################################################################
sub getForwardHSPs {
#################################################################
    my( $self ) = shift;

    return( $self->{ $kForwardHSPs } );

}

#################################################################
sub getReverseHSPs {
#################################################################
    my( $self ) = shift;

    return( $self->{ $kReverseHSPs } );
}

#################################################################
sub getStrandTypeCount {
#################################################################
    my( $self ) = shift;

    my( $list );
    my( $count ) = 0;

    $list = $self->getForwardHSPs();

    if( $list->getCount() > 0 )
    {
    $count++;
    }

    $list = $self->getReverseRef();
    if( $list->getCount() > 0 )
    {
    $count++;
    }

    return( $count )
}

#################################################################
sub sortHSPs {
#################################################################
    my( $self ) = shift;

    my $hit = $self->getHit();

    my $fwd = $self->getForwardHSPs();
    my $rev = $self->getReverseHSPs();

    foreach my $hsp ($hit->hsps() ) {

    if( $hsp->strand > 0 ) {
        $fwd->addElement( $hsp );
    }
    else {
        $rev->addElement( $hsp );
    }
    }

}

#################################################################
sub getP {
#################################################################
    my( $self ) = shift;

    return $self->getHit()->significance;

}

##################################################################
sub getPExponent {
##################################################################

    my( $self ) = shift;

    my $p = $self->getP();

    my $exp = Bio::GMOD::Blast::Graph::ScientificNotation::getExponent( $p );

    #dmsg( "getPExponent: $p $exp" );

    return( $exp );
}


########################################################################
sub getScore {
########################################################################
    my( $self ) = shift;

    return $self->getHit()->raw_score();

}

########################################################################
sub getName {
########################################################################
    my( $self ) = shift;

    my $name = $self->getHit()->name();

    $name =~ s/^.+[:\|](.+)$/$1/;
    $name =~ s/^(.+)\|$/$1/;

    return $name;

}

########################################################################
sub getDescription {
########################################################################
    my( $self ) = shift;

    return( $self->getHit()->description() );

}

########################################################################
sub getGraphAnnotation {
########################################################################
    my( $self ) = shift;

   return( $self->getName() . ' ' . $self->getP() );

}

########################################################################
sub calculateHSPLineCount {
########################################################################
    my( $self ) = shift;

    #dmsg( "calculateHSPLineCount(): hit = " . $self->getHit()->name() );

    $self->addHSPsRef( $self->getForwardHSPs(), $self->getForwardBucketSet() );
    $self->addHSPsRef( $self->getReverseHSPs(), $self->getReverseBucketSet() );

    $self->{ $kLineCount } =
    $self->getForwardBucketSet()->getCount() +
        $self->getReverseBucketSet()->getCount();
}

########################################################################
sub getHSPLineCount {
########################################################################
    my( $self ) = shift;

    return( $self->{ $kLineCount } );

}

########################################################################
sub addHSPsRef {
########################################################################
    my( $self, $list, $bset ) = @_;


    # the list could be empty (we don't
    # always have both forward and reverse hsps).

    #dmsg( "addHSPsRef(): bset = $bset, count = " . $list->getCount() );

    foreach my $hsp ( @{ $list->getElementsRef() } ) {
    my $start = $hsp->start;
    my $end = $hsp->end;
    my $region = new Bio::GMOD::Blast::Graph::IntSpan "$start-$end";
    #dmsg( "addHSPsRef(): hsp = ", $hsp->name(), $hsp, $region->run_list() );
    $bset->addRegion( $region );
    }
}

#######################################################################
1;
#######################################################################


__END__
=pod

=encoding utf-8

=head1 NAME

Bio::GMOD::Blast::Graph::HitWrapper

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

