#################################################################
# DistancesBlock.pm
#################################################################
# Author: Thomas Hladish
# $Id: DistancesBlock.pm,v 1.18 2007/09/21 23:09:09 rvos Exp $

#################### START POD DOCUMENTATION ##################

=head1 NAME

Bio::NEXUS::DistancesBlock - Represents DISTANCES block in NEXUS file

=head1 SYNOPSIS


=head1 DESCRIPTION

The DistancesBlock class represents a NEXUS Distances Block and provides methods for reading, writing, and accessing data within these blocks.  Distances Blocks contain distance matrices, or a table of calculated distances between each possible pair of taxa.

=head1 COMMENTS

=head1 FEEDBACK

All feedback (bugs, feature enhancements, etc.) are greatly appreciated. 

=head1 AUTHORS

 Tom Hladish (tjhladish at yahoo)

=head1 VERSION

$Revision: 1.18 $

=head1 METHODS

=cut

package Bio::NEXUS::DistancesBlock;

use strict;
#use Data::Dumper; # XXX this is not used, might as well not import it!
#use Carp; # XXX this is not used, might as well not import it!
use Bio::NEXUS::Functions;
use Bio::NEXUS::Matrix;
use Bio::NEXUS::Util::Logger;
use Bio::NEXUS::Util::Exceptions;
use vars qw(@ISA $VERSION $AUTOLOAD);
use Bio::NEXUS; $VERSION = $Bio::NEXUS::VERSION;

@ISA = qw(Bio::NEXUS::Matrix);
my $logger = Bio::NEXUS::Util::Logger->new();

=head2 new

 Title   : new
 Usage   : block_object = new Bio::NEXUS::DistancesBlock($block_type, $commands, $verbose, $taxa);
 Function: Creates a new Bio::NEXUS::DistancesBlock object
 Returns : Bio::NEXUS::DistancesBlock object
 Args    : type (string), the commands/comments to parse (array ref), and a verbose flag (0 or 1)

=cut

sub new {
    my ( $class, $type, $commands, $verbose, $taxa ) = @_;
    if ( not $type) { 
    	( $type = lc $class ) =~ s/Bio::NEXUS::(.+)Block/$1/i; 
    }
    my $self = { 
    	'type' => $type 
    };
    bless $self, $class;
    $self->set_taxlabels($taxa);
    if ( ( defined $commands ) and @$commands ) {
    	$self->_parse_block( $commands, $verbose )
    }
    return $self;
}

=begin comment

 Title   : _parse_matrix
 Usage   : $self->_parse_matrix($block);
 Function: Parses a distance matrix, stores the data
 Returns : none
 Args    : the distance matrix to parse (string)

=end comment 

=cut

sub _parse_matrix {
    my ( $self, $buffer ) = @_;

    # Set format values as already parsed, or to NEXUS-specified defaults
    my %format = %{ $self->get_format() };

    my $triangle = defined $format{'triangle'} ? $format{'triangle'} : 'lower';
    my $diagonal = defined $format{'diagonal'} ? $format{'diagonal'} : 1;
    my $labels   = defined $format{'labels'}   ? $format{'labels'}   : 1;
    my $missing  = defined $format{'missing'}  ? $format{'missing'}  : undef;
    my $interleave = defined $format{'interleave'} ? $format{'interleave'} : 0;

    if ( $triangle =~ /^both$/i && !$diagonal ) {
        Bio::NEXUS::Util::Exceptions::BadFormat->throw(
        	'error' => "The Distances Block contains a matrix that has\n" 
        			. "both upper and lower halves, but does not have\n"
        			. "diagonal values.\nThis is prohibited by the NEXUS standard"
        );
    }
    if ( $interleave && !$labels ) {
        Bio::NEXUS::Util::Exceptions::BadFormat->throw(
        	'error' => "This matrix is interleaved and without row labels\n" 
        			. "('unlabeled').  Please label rows or use a non-\n"
        			. "interleaved format, to allow for safer parsing"
        );
    }

    my @rows = split /\n+/, $buffer;
    my @taxa_order;
    my %row_for;

    # First, we'll deal with whether the matrix is interleaved and labeled
    if ( $interleave || $labels ) {
        for my $row (@rows) {
            my ( $taxon, @distances ) = @{ _parse_nexus_words($row) };
            push( @taxa_order, $taxon );
            push @{ $row_for{$taxon} }, @distances;
        }
    }
    else {
        @taxa_order = @{ $self->get_taxlabels() };
        @rows       =
            grep { !/^\s+$/ } @rows;  # throw out rows that are just blank space

        for ( my $i = 0; $i < @rows; $i++ ) {
            my $row = $rows[$i];
            $row_for{ $taxa_order[$i] } = [ split /\s+/, $row ];
        }
    }

    # It's important to keep track of this so that we know what the columns
    # are, since they're unlabeled
    $self->set_taxlabels( \@taxa_order );

    # Now everything is stored in %row_for, and the original order
    # is in @taxa_order
    my $matrix;
    for ( my $r = 0; $r < @taxa_order; $r++ ) {
        my $row_label = $taxa_order[$r];
        my @cells     = @{ $row_for{$row_label} };

        # If this is a full matrix (simplest to parse),
        if ( $triangle =~ /^both$/i ) {

            # iterate through the values
            for ( my $c = 0; $c < @cells; $c++ ) {
                my $cell_val  = $cells[$c];
                my $col_label = $taxa_order[$c];

                # and store them in $matrix.
                $matrix->{$row_label}{$col_label} = $cell_val;
            }
        }

        # If it's a lower triangle,
        elsif ( $triangle =~ /^lower$/i ) {

            # iterate through the values
            for ( my $c = 0; $c < @cells; $c++ ) {
                my $cell_val = $cells[$c];

                # and store them symmetrically in $matrix
                my $col_label = $taxa_order[$c];
                $matrix->{$row_label}{$col_label} =
                    ( $matrix->{$col_label}{$row_label} = $cell_val );
            }

            # In case there are no diagonal values,
            if ( !$diagonal ) {

                # make sure they still get stored (as zeroes)
                $matrix->{$row_label}{$row_label} = 0;
            }
        }

        # If this is an upper triangle
        elsif ( $triangle =~ /^upper$/i ) {

            # iterate through the values
            for ( my $c = 0; $c < @cells; $c++ ) {
                my $cell_val = $cells[$c];

                # and make sure the column label is correct,
                # since everything needs to be shifted over.
                my $col_label = $diagonal
                    ? $taxa_order[ $r + $c ]
                    : $taxa_order[ $r + $c + 1 ];

                # Store the values symmetrically in $matrix
                $matrix->{$row_label}{$col_label} =
                    ( $matrix->{$col_label}{$row_label} = $cell_val );
            }

            # In case there are no diagonal values,
            if ( !$diagonal ) {

                # make sure they still get stored (as zeroes)
                $matrix->{$row_label}{$row_label} = 0;
            }
        }
        else {
            Bio::NEXUS::Util::Exceptions::BadFormat->throw(
            	'error' => "Unknown value '$triangle' for Format:Triangle\n"
            			. "in the DistancesBlock.  Expecting 'upper', 'lower', or 'both'."
            );
        }
    }

    $self->set_ntax( scalar keys %$matrix ) unless $self->get_ntax();
    $self->{'matrix'} = $matrix;
    return $self->{'matrix'};
}

=head2 get_matrix

 Title   : get_matrix
 Usage   : $matrix = $self->get_matrix();
 Function: Retrieves the entire distance matrix
 Returns : a hashref of hashrefs
 Args    : none
 Note    : Distance values may be retrieved by specifying the row and column keys, e.g. $dist = $matrix->{$row_taxon}{$col_taxon}

=cut

sub get_matrix {
    my ( $self, $taxon ) = @_;
    return $self->{'matrix'};
}

=head2 get_distances_for

 Title   : get_distances_for
 Usage   : %taxon1_distances = %{ $self->get_distances_for($first_taxon) };
 Function: Retrieves a row of the distance matrix
 Returns : 
 Args    : the row label (a taxlabel) for the row desired (string)

=cut

sub get_distances_for {
    my ( $self, $taxon ) = @_;
    my $matrix = $self->get_matrix();
    my $row    = $matrix->{$taxon};
    return $row;
}

=head2 get_distance_between

 Title   : get_distance_between
 Usage   : $distance = $self->get_distance_between($row_taxon, $column_taxon);
 Function: Retrieves a cell from the matrix
 Returns : A scalar (number)
 Args    : the row and column labels (both taxa) for the cell desired
 Note    : Generally get_distance_between($A, $B) == get_distance_between($B, $A); however, this need not be true if the distance matrix is not symmetric.  Make sure you are asking for the distance you want.

=cut

sub get_distance_between {
    my ( $self, $tax1, $tax2 ) = @_;
    my $matrix = $self->get_matrix();
    my $dist   = $matrix->{$tax1}{$tax2};
    return $dist;
}

=begin comment

 Name    : _write
 Usage   : $block->_write();
 Function: Writes out NEXUS Distances Block
 Returns : none
 Args    : file handle

=end comment 

=cut

sub _write {
    my ( $self, $fh, $verbose ) = @_;
    $fh ||= \*STDOUT;

    Bio::NEXUS::Block::_write( $self, $fh );
    $self->_write_dimensions( $fh, $verbose );
    $self->_write_format( $fh, $verbose );
    $self->_write_matrix( $fh, $verbose );
    print $fh "END;\n";
}

=begin comment

 Name    : _write_matrix
 Usage   : $block->_write_matrix();
 Function: writes out the matrix for a NEXUS Distances Block
 Returns : none
 Args    : file handle

=end comment 

=cut

sub _write_matrix {
    my ( $self, $fh, $verbose ) = @_;
    $fh ||= \*STDOUT;

    my %format = %{ $self->get_format() };

    my $triangle = defined $format{'triangle'} ? $format{'triangle'} : 'lower';
    my $diagonal = defined $format{'diagonal'} ? $format{'diagonal'} : 1;
    my $labels   = defined $format{'labels'}   ? $format{'labels'}   : 1;
    my $missing  = defined $format{'missing'}  ? $format{'missing'}  : undef;
    my $interleave = defined $format{'interleave'} ? $format{'interleave'} : 0;

    if ( $triangle =~ /^both$/i && !$diagonal ) {
        Bio::NEXUS::Util::Exceptions::BadFormat->throw(
        	'error' => "The Distances Block contains a matrix that has\n"
        			. "both upper and lower halves, but does not have\n"
        			. "diagonal values.  This is prohibited by the NEXUS standard"
        );
    }

    print $fh "\tMATRIX\n";
    my $matrix = $self->get_matrix();

    my @taxlabels = @{ $self->get_taxlabels };

    for ( my $r = 0; $r < @taxlabels; $r++ ) {
        my $row_taxon   = $taxlabels[$r];
        my $print_taxon = _nexus_formatted($row_taxon);
        print $fh "\t$print_taxon";

        my ( $first_col, $last_col );

        # Determine which part of the matrix to iterate through,
        # based on whether its 'upper', 'lower', or 'both'
        if ( $triangle =~ /^both$/i ) {
            ( $first_col, $last_col ) = ( 0, scalar @taxlabels );
        }
        elsif ( $triangle =~ /^lower$/i ) {
            ( $first_col, $last_col ) = ( 0, $r );
            $last_col++ if $diagonal;
        }
        elsif ( $triangle =~ /^upper$/i ) {
            ( $first_col, $last_col ) = ( $r, scalar @taxlabels );
            $first_col++ unless $diagonal;
        }

        for ( my $c = $first_col; $c < $last_col; $c++ ) {
            my $col_taxon = $taxlabels[$c];
            print $fh "\t" . $matrix->{$row_taxon}{$col_taxon};
        }
        print $fh "\n";
    }
    print $fh "\t;\n";
}

sub AUTOLOAD {
    return if $AUTOLOAD =~ /DESTROY$/;
    my $package_name = __PACKAGE__ . '::';

    # The following methods are deprecated and are temporarily supported
    # via a warning and a redirection
    my %synonym_for = (

#        "${package_name}parse"      => "${package_name}_parse_tree",  # example
    );

    if ( defined $synonym_for{$AUTOLOAD} ) {
        $logger->warn("$AUTOLOAD() is deprecated; use $synonym_for{$AUTOLOAD}() instead");
        goto &{ $synonym_for{$AUTOLOAD} };
    }
    else {
        Bio::NEXUS::Util::Exceptions::UnknownMethod->throw(
        	'error' => "ERROR: Unknown method $AUTOLOAD called"
        );
    }
}

1;
