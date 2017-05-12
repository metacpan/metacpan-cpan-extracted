package Bio::GMOD::Blast::Graph::List;
BEGIN {
  $Bio::GMOD::Blast::Graph::List::AUTHORITY = 'cpan:RBUELS';
}
BEGIN {
  $Bio::GMOD::Blast::Graph::List::VERSION = '0.06';
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
use Bio::GMOD::Blast::Graph::MyDebug qw( dmsg dmsgs );
use Bio::GMOD::Blast::Graph::ListEnumerator;

@ISA = qw( Bio::GMOD::Blast::Graph::BaseObj );

#
# basically, just a wrapper so we can
# use it in ListSet a little more clearly.
# tho you cannot have undefs as elements of the list.
#

my $kElements = Bio::GMOD::Blast::Graph::MyUtils::makeVariableName( "elements" );

#########################################################################
sub init {
#########################################################################
    my( $self, @ref ) = @_;

    # this sure is gross, but it seems to work.
#    if( defined( @ref ) )
    if( @ref )
    {
    if( ref( $ref[0] ) eq "ARRAY" )
    {
        #dmsg( "got reference to array" );
        $self->{ $kElements } = $ref[0];
    }
    elsif( !ref( $ref[0] ) )
    {
        #dmsg( "got array itself" );
        $self->{ $kElements } = \@ref;
    }
    }
    else
    {
    #dmsg( "no ref given at all" );
    $self->{ $kElements } = [];
    }
}

#########################################################################
sub getElementsRef{
#########################################################################
    my( $self ) = shift;
    return( $self->{ $kElements } );
}

#########################################################################
sub putElementsRef {
#########################################################################
    my( $self, $lref ) = @_;
    $self->{ $kElements } = $lref;
}

#########################################################################
sub addElement {
#########################################################################
    my( $self, $elem ) = @_;
    push( @{$self->getElementsRef}, $elem );
}

# dex is zero based.
#########################################################################
sub getElementAt {
#########################################################################
    my( $self, $dex ) = @_;
    my( $ref );
    my( $maxDex );
    my( $elem );

    $elem = undef;
    $maxDex = $self->getCount()-1;

    if( $dex <= $maxDex )
    {
    $ref = $self->getElementsRef();
    $elem = $ { $ref } [ $dex ];
    }

    return( $elem );
}

#########################################################################
sub removeElement {
#########################################################################
    my( $self, $elem ) = @_;
    my( $ref );
    my( $dex );
    my( $test );

    $ref = $self->getElementsRef();
    for( $dex = 0; $dex < $self->getCount(); $dex++ )
    {
    $test = $self->getElementAt( $dex );
    last if( $test == $elem );
    }

    splice( @{$ref}, $dex, 1 );
}

#########################################################################
sub my_shift {
#########################################################################
    my( $self ) = shift;
    my( $val );

    $val = shift( @{$self->getElementsRef()} );
    #dmsg( "shift(): $val" );
    return( $val );
}

#########################################################################
sub shiftSafe {
#########################################################################
    my( $self ) = shift;
    my( $val );

    if( $self->emptyP() )
    {
    $val = undef;
    }
    else
    {
    $val = $self->shift();
    }

    return( $val );
}

# return 1 based count.
#########################################################################
sub getCount {
#########################################################################
    my( $self ) = shift;
    my( $ref ) = $self->getElementsRef();
    #dmsgs( "getCount(): ref = ", @{$ref} );
    my( $count ) = scalar( @{$self->getElementsRef()} );
    #dmsg( "getCount(): count = ", $count );
    return( $count );
}

#########################################################################
sub emptyP {
#########################################################################
    my( $self ) = shift;
    my( $emptyP );

    if( $self->getCount() == 0 )
    {
    $emptyP = 1;
    }
    else
    {
    $emptyP = 0;
    }

    return( $emptyP );
}

# [[ $sub is the fully qualified name of a sorter subroutine.
# that routine must refer to $List::a and $List::b to work;
# perl suck. ]]
# subclasses might override this to provide a fixed
# sorting method, which ignores any given subroutine.
#########################################################################
sub sort {
#########################################################################
    my( $self, $sub ) = @_;
    my( $lref );
    my( @ray );

    $lref = $self->getElementsRef();

    @ray = sort $sub @{$lref};

    $self->putElementsRef( \@ray );
}

# n is zero based.
# element at location n is also removed.
#########################################################################
sub truncateAt {
#########################################################################
    my( $self, $n ) = @_;
    my( $lref );

    if( $n < 0 )
    {
    $self->putElementsRef( [] );
    }
    else
    {
    $lref = $self->getElementsRef();
    splice( @{$lref}, $n );
    }
}

#########################################################################
sub getEnumerator {
#########################################################################
    my( $self ) = shift;
    return( new Bio::GMOD::Blast::Graph::ListEnumerator( $self ) );
}

#########################################################################
sub toString {
#########################################################################
    my( $self ) = shift;
    my( $str );

    $str = Bio::GMOD::Blast::Graph::MyUtils::makeDumpString($self,
                          $self->getCount,
                          @{$self->getElementsRef()});

    return( $str );
}
#########################################################################
1;
#########################################################################

__END__
=pod

=encoding utf-8

=head1 NAME

Bio::GMOD::Blast::Graph::List

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

