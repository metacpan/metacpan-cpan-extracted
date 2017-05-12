#!perl

# ########################################################################## #
# Title:         Gather counts of selected fields
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Counts number of occurences of various field values
#                Data Stream class
#                Data transformer
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Transformer/StatCounter.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# ########################################################################## #

package DS::Transformer::StatCounter;

use base qw{ DS::Transformer };

use strict;
use Carp::Assert;
use IO::Handle;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;


sub new {
    my ( $class, $typespec, $source, $count_config ) = @_;

    my $self = $class->SUPER::new( $typespec, $source );

    $self->{count_config} = $count_config;
    $self->{stats} = {};

    return $self;
}

sub process {
    my( $self, $row ) = @_;

    $self->_update_counts( $row, $self->{count_config}, $self->{stats} );

    return $row;
}

sub _update_counts {
    my ( $self, $row, $field_list, $stats ) = @_;

    for( my $i = 0; $i <= $#$field_list; $i++ ) {

        # Find out which field to process
        my $field = ${$field_list}[$i];

        # Create any missing data structures
        # (yes - this could be done once and would speed up the processing a lot)
        unless( defined $stats->{$field} ) {
            $stats->{$field} = {};
        }

        unless( defined $stats->{$field}->{ $row->{$field} } ) {
            $stats->{$field}->{ $row->{$field} } = { stats => { count => 0 } };
        }

        # This is where the actual statistics are being stored
        $stats->{$field}->{ $row->{$field} }->{stats}->{count}++;

        # If there are any extra subfields, add the next one to the structure
        if( $i < $#$field_list) {
            unless( defined( $stats->{$field}->{ $row->{$field} }->{subfield} ) ) {
                $stats->{$field}->{ $row->{$field} }->{subfield} = {};
            }
            $stats = $stats->{$field}->{ $row->{$field} }->{subfield};
        }
    }
}

# Method to print statistics
sub print {
    my( $self, $fh ) = @_;

    unless( defined( $fh ) ) {
        $fh = new IO::Handle;
        #TODO Error check: did we get a file handle on STDOUT?
        $fh->fdopen(fileno(STDOUT),"w");
    }

    $fh->print(join("\t\t", @{$self->{count_config}}), "\n");

    return $self->_print( $fh, $self->{stats}, '' );
}

# Recursive print of statistics
sub _print {
    my( $self, $fh, $stats, $indent ) = @_;
    
    foreach my $field (sort keys %{$stats}) {
        foreach my $value (sort keys %{$stats->{$field}}) {
            $fh->print("$indent$value\t", $stats->{$field}->{$value}->{stats}->{count}, "\n");
            if(defined($stats->{$field}->{$value}->{subfield})) {
                $self->_print( $fh, $stats->{$field}->{$value}->{subfield}, "$indent\t\t" );
            }
        }
    }
}

sub print_terse_sum {
    my( $self, $fh ) = @_;

    unless( defined( $fh ) ) {
        $fh = new IO::Handle;
        #TODO Error check: did we get a file handle on STDOUT?
        $fh->fdopen(fileno(STDOUT),"w");
    }

    $fh->print($self->terse_sum_line(), "\n");
}

sub terse_sum_line {
    my( $self ) = @_;

    my $ts = $self->terse_sum();
    my $line = '';

    foreach my $field (@{$self->{count_config}}) {
        $line .= sprintf("%6s % 6d % 6d ", $field, $ts->{$field}->{count}, $ts->{$field}->{sum});
    }
    
    return $line;
}

sub terse_sum {
    my( $self ) = @_;

    my $result = {};
    foreach my $field (@{$self->{count_config}}) {
        $result->{$field} = {
            count => 0,
            sum => 0
        };
    }

    $self->_terse_sum( $self->{stats}, $result );

    return $result;
}

# Recursive print of statistics
sub _terse_sum {
    my( $self, $stats, $result ) = @_;
    
    foreach my $field (keys %{$stats}) {
       foreach my $value (keys %{$stats->{$field}}) {
            $result->{$field}->{count}++;
            $result->{$field}->{sum} += $stats->{$field}->{$value}->{stats}->{count};
            if(defined($stats->{$field}->{$value}->{subfield})) {
                $self->_terse_sum( $stats->{$field}->{$value}->{subfield}, $result );
            }
        }
    }
}

1;
