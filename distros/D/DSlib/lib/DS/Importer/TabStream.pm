#!perl

# ########################################################################## #
# Title:         Tabular stream to datastream importer
# Creation date: 2007-03-05
# Author:        Michael Zedeler
# Description:   Produces a datastream from a tab separated stream (IO::Handle)
#                Data Stream class
#                Data importer
# File:          $Source: /data/cvs/lib/DSlib/lib/DS/Importer/TabStream.pm,v $
# Repository:    kronhjorten
# State:         $State: Exp $
# Documentation: inline
# Recepient:     -
# TODO Must store field order internally.
# ########################################################################## #

package DS::Importer::TabStream;

use base qw{ DS::Importer };

use strict;
use Carp::Assert;

our ($VERSION) = $DS::VERSION;
our ($REVISION) = '$Revision: 1.1 $' =~ /(\d+\.\d+)/;

require DS::TypeSpec;

# Important: calling this method with no typespec will make
# the class read a header from the stream and use it
# to create a typespec.
sub new {
    my( $class, $fh, $target, $typespec, $field_order, $row ) = @_;

    assert($fh->isa('IO::Handle'));

    my @fields;
    if( not defined( $typespec ) ) {
        # Get header from stream to create type spec from

        assert( (not defined $field_order), 
            "Can't handle specifying field order if fields derived from stream header." );

        # Get first non-comment line in stream
        my $line = getline($fh);
        $line =~ s/[\n\r]+$//;
        $line =~ s/(\s+|$)/\n/g;

        my @fields = split /\s+/, $line;

        $typespec = new DS::TypeSpec( [ @fields ] );
        
        $field_order = [@fields];
    }

    my $self = $class->SUPER::new( $typespec, $target, $row );

    $self->{field_order} = $field_order;

    $self->{fh} = $fh;

    return $self;
}

sub _fetch {
    my($self) = @_;

    my $result = undef;

    unless($self->{fh}->eof()) {
        
        my ($line) = getline($self->{fh}) =~ /^([^\n\r]+)/;
        my (@line) = split /\t/, $line;

        # Replace values that are not defined (because the field was empty or not there)
        # with empty strings.
        # This is a design decision: we could check whether each line has exactly the right
        # number of fields. The problem is that Microsoft Excel truncates trailing empty fields
        # on each line, which would trigger spurious errors.
        for(my $i = 0; $i <= $#{$self->{field_order}}; $i++) {
            $line[$i] = '' unless defined( $line[$i] );
        }

        @{$self->{row}}{@{$self->{field_order}}} = @line;
        
        $result = 1;
    }

    return $result ? $self->{row} : undef;
}

# Functions (not methods!)

sub getline {
    my( $fh ) = @_;

    my $line;
    do {
         $line = $fh->getline();
    } while( $line =~ /^#/ and not $fh->eof());

    return $line;
}

1;
