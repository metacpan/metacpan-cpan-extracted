#!perl

# ########################################################################## #
# Title:         Batch-of-rows processor
# Creation date: 2007-03-05
# Author:        Michael Zedeler
#                Henrik Andreasen
# Description:   Process batches of rows in a data stream
#                Data Stream class
#                Data transformer
#                Buffers rows
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Transformer/Buffer.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Transformer::Buffer;

use base qw{ DS::Transformer::TypePassthrough };

use strict;
use Carp;
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;


# new
#
# Class constructor
#
sub new {
    my( $class, $source, $target ) = @_;

    my $self = $class->SUPER::new( $source, $target );

    $self->{buffer} = [];   # Holds copies (?) of the currently buffered rows (stream is N elements long, indexed 0 .. N-1)
    $self->{first} = 0;     # Range: [0..N]    Inv: Always at first buffered element (one past "last" when buffer is empty)
    $self->{last} = -1;     # Range: [-1..N-1] Inv: Always at last element (one before "first" when buffer is empty)
    $self->{current} = -1;  # Range: [-1..N]   Inv: Always at current element, initially -1, finally N (past end)

    return $self;
}

# receive_row
#
# Processes a row in stream.
# Returns undef when no more rows are available.
# It is allowed to call fetch after the stream has ended, each call returning undef.
#
sub process {
    my ($self, $row) = @_;
    $self->push( $row );
    return $self->shift;
}

sub shift {
    my( $self ) = @_;

    my $last = $self->{last};
    my $current = $self->{current};
    my $result = undef;

    # Find and return the "next" element, if any
    ++$current if ($current <= $last);
    $result = ${$self->{buffer}}[$current] if ($current <= $last);
    
    $self->{current} = $current;

    return $result;
}

sub push {
    my( $self, $row ) = @_;
 
    my $last = $self->{last};

    # Put row in buffer if not EOF or EOF not already registered in buffer
    if ( $row or ${$self->{buffer}}[$last] ) {
        ++$last;
        $row = {%$row} if $row; # Make a copy if not EOF
        ${$self->{buffer}}[$last] = $row;
    }

    $self->{last} = $last;

    return;
}

# fetch
#
# Re-fetches rows that has been unfetched.
# It is a fatal error to try fetching beyond last row in the buffer
#TODO Implement some kind of end of stream indicator that will allow fetch to return undef indicating end of stream
sub fetch {
    my ($self) = @_;

    my $last = $self->{last};
    my $current = $self->{current};
    my $result = undef;

    # Make sure we're not beyond end of buffer
    if( $current < $last ) {
        # Find and return the "next" element
        ++$current;
        $result = ${$self->{buffer}}[$current];
    } else {
        croak("Can't fetch past buffer end.");
    }
    
    $self->{last} = $last;
    $self->{current} = $current;

    return $result;
}


# unreceive_row
#
# Moves the "current" position one step backwards within the buffered rows.
# It is a fatal error to try to move before the start of the currently buffered rows.
#
sub unfetch {
    my ($self) = @_;
    
    my $first = $self->{first};
    my $last = $self->{last};
    my $current = $self->{current};

    # Validate the request
    if ($current < $first) {
        die "Cannot unfetch beyond buffer start (frame starts at row number $first and current record is $current)\n";
    } elsif( $current > $last ) {
        # If EOF reached, return to the element that contains EOF
        assert( $current == $last + 1, '$current must never be more than one past $last' );
        --$current;
    }

    # Move back one step
    --$current;

    $self->{current} = $current;
    return 1;
}


# flush
#
# Clears the buffered rows up to and including the given point.
# If the "current" position is flush, it is moved forward such that it will
# return the first available element at next fetch, if any.
# It is a fatal error to flush non-existent rows.
#
sub flush {
    my ($self, $point) = @_;

    my $first = $self->{first};
    my $last = $self->{last};
    my $current = $self->{current};
    
    # Use current position to flush in no point provided
    $point ||= $current;

    # Validate the request
    if ($point < $first || $point > $last) {
        croak("Cannot flush non-existent elements. ($point is not within valid range: $first .. $last)");
    }

    # Delete buffer elements and adjust pointers
    for (my $i = $first; $i <= $point; ++$i) {
        delete ${$self->{buffer}}[$i];
    }
    $self->{first} = $point + 1;
    $self->{current} = $point if ($self->{current} < $point);

    return 1;
}

1;
