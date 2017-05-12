package Bio::GMOD::Blast::Graph::ListEnumerator;
BEGIN {
  $Bio::GMOD::Blast::Graph::ListEnumerator::AUTHORITY = 'cpan:RBUELS';
}
BEGIN {
  $Bio::GMOD::Blast::Graph::ListEnumerator::VERSION = '0.06';
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
use Bio::GMOD::Blast::Graph::MyDebug qw( dmsg );
use Bio::GMOD::Blast::Graph::List;

@ISA = qw( Bio::GMOD::Blast::Graph::BaseObj );

my $kList = Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "list" );
my $kIndex = Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "index" );
my $kMaxDex = Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "max", "dex" );

####################################################################
sub init {
####################################################################
    my( $self, $list ) = @_;

    #dmsg( "init(): ", $list->toString() );

    $self->{ $kList } = $list;
    $self->{ $kMaxDex } = $list->getCount() - 1;
    $self->reset();
}

####################################################################
sub reset {
####################################################################
    my( $self ) = shift;
    $self->{ $kIndex } = -1;
}

####################################################################
sub getList {
####################################################################
    my( $self ) = shift;
    return( $self->{ $kList } );
}

####################################################################
sub previousIndex {
####################################################################
    my( $self ) = shift;
    my( $dex );

    $dex = $self->getIndex();

    # we can go back to -1, even though that
    # is sort of a cheesy hack, to show that
    # we don't want anything in the list.
    if( $dex > -1 )
    {
    $dex--;
    }

    $self->putIndex( $dex );
}

# have to call this first to start things off.
####################################################################
sub nextIndex {
####################################################################
    my( $self ) = shift;
    my( $dex );
    my( $maxDex );

    $dex = $self->getIndex();
    $maxDex = $self->getMaxIndex();

    #dmsg( "nextIndex(): before =", $dex );

    # should be able to move to maxDex+1
    # which signifies there are no more elements.
    if( $dex <= $maxDex )
    {
    $self->putIndex( ++$dex );
    }

    #dmsg( "nextIndex(): after =", $self->getIndex() );
}

####################################################################
sub getCurrentElement {
####################################################################
    my( $self ) = shift;
    my( $elem );
    my( $dex );
    my( $maxDex );

    $elem = undef;
    $dex = $self->getIndex();
    $maxDex = $self->getMaxIndex();

    #dmsg( "nextIndex(): dex=$dex maxDex=$maxDex" );

    if( $dex <= $maxDex )
    {
    $elem = $self->getList()->getElementAt( $dex );
    }

    return( $elem );
}

####################################################################
sub getNextElement {
####################################################################
    my( $self ) = shift;
    $self->nextIndex();
    return( $self->getCurrentElement() );
}

####################################################################
sub getMaxIndex {
####################################################################
    my( $self ) = shift;
    return( $self->{ $kMaxDex } );
}

####################################################################
sub getIndex {
####################################################################
    my( $self ) = shift;
    return( $self->{ $kIndex } );
}

####################################################################
sub putIndex {
####################################################################
    my( $self, $dex ) = @_;
    $self->{ $kIndex } = $dex;
}

####################################################################
sub getCount {
####################################################################
    my( $self ) = shift;
    return( $self->getMaxIndex() );
}

####################################################################
1;
####################################################################

__END__
=pod

=encoding utf-8

=head1 NAME

Bio::GMOD::Blast::Graph::ListEnumerator

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

