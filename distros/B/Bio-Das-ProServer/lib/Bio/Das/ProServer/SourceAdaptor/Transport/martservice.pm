#########
# Author:        Ray Miller <rm7@sanger.ac.uk>
# Maintainer:    $Author: zerojinx $
# Created:       2009-07-10
# Last Modified: $Date: 2010-11-02 11:37:11 +0000 (Tue, 02 Nov 2010) $
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceAdaptor/Transport/martservice.pm $
#
package Bio::Das::ProServer::SourceAdaptor::Transport::martservice;

use strict;
use warnings FATAL => 'all';

our $VERSION  = do { my ($v) = (q$Revision: 687 $ =~ /\d+/mxsg); $v; };

use List::MoreUtils 'zip';
use LWP::UserAgent;
use XML::Writer;
use Carp;

use base qw(Bio::Das::ProServer::SourceAdaptor::Transport::generic);

sub init {
    my ( $self ) = @_;
    $self->martservice( $self->config->{'martservice'} );
    $self->dataset( $self->config->{'dataset'} );
    $self->attributes( $self->config->{'attributes'} || [] );
    $self->timeout( $self->config->{'timeout'} );
    return $self;
}

sub timeout {
    my ( $self, $timeout ) = @_;
    if ( defined $timeout ) {
        $self->{'timeout'} = $timeout;
    }
    return $self->{'timeout'};
}

sub attributes {
    my ( $self, $attributes ) = @_;
    if ( $attributes ) {
        if ( ref $attributes ) {
            $self->{'attributes'} = $attributes;
        }
        else {
            $self->{'attributes'} = [ split qr/\s*,\s*/mxs, $attributes ];
        }
    }
    return $self->{'attributes'};
}

sub dataset {
    my ( $self, $dataset ) = @_;
    if ( $dataset ) {
        $self->{'dataset'} = $dataset;
    }
    return $self->{'dataset'};
}

sub martservice {
    my ( $self, $martservice ) = @_;
    if ( $martservice ) {
        $self->{'martservice'} = $martservice;
    }
    return $self->{'martservice'};
}

sub ua {
    my ( $self ) = @_;
    if (! $self->{'ua'} ) {
        $self->{'ua'} = LWP::UserAgent->new();
        if ( defined $self->timeout ) {
            $self->{'ua'}->timeout( $self->timeout );
        }
    }
    return $self->{'ua'};
}

sub build_query_xml {
    my ( $self, $filter ) = @_;

    if (!$self->dataset) {
      croak 'No dataset defined';
    }

    if (!$self->attributes || !scalar @{ $self->{attributes} }) {
      croak 'No attributes defined';
    }

    if (!$filter) {
      croak 'No filter defined';
    }

    my $query_xml;

    my $xml = XML::Writer->new( OUTPUT => \$query_xml, ENCODING => 'utf-8' );
    $xml->xmlDecl;
    $xml->doctype( 'Query' );
    $xml->startTag( 'Query', virtualSchemaName => 'default', datasetConfigVersion => '0.6' );
    $xml->startTag( 'Dataset', name => $self->dataset, interface => 'default' );
    foreach my $attr ( @{ $self->attributes } ) {
        $xml->emptyTag( 'Attribute', name => $attr );
    }
    while ( my ( $name, $value) = each %{ $filter } ) {
        $xml->emptyTag( 'Filter', name => $name, value => $value );
    }
    $xml->endTag( 'Dataset' );
    $xml->endTag( 'Query' );
    $xml->end;

    return $query_xml;
}

sub query {
    my ( $self, %filter ) = @_;

    if (!$self->martservice) {
      croak 'No martservice defined';
    }

    my $query_xml = $self->build_query_xml( \%filter );

    my $response = $self->ua->post( $self->martservice, { query => $query_xml } );

    if (!$response->is_success) {
      croak $response->message;
    }

    my @results;

    foreach my $row ( split /\n/mxs, $response->content ) {
        my @cols = split /\t/mxs, $row;
        push @results, { zip @{ $self->attributes }, @cols };
    }

    return \@results;
}

1;

__END__

=pod

=head1 NAME

Bio::Das::ProServer::SourceAdaptor::Transport::martservice - BioMart MartService Transport

=head1 VERSION

$Revision: 687 $

=head1 SYNOPSIS

=head1 DESCRIPTION

This module provides a transport to retrieve data from a BioMart MartService.

=head1 SUBROUTINES/METHODS

=head2 init

Initializes this object using values taken from the configuration.

=head2 timeout

Get/set the timeout for requests POSTed via LWP::UserAgent.

=head2 martservice

Get/set the MartService URL.

=head2 dataset

Get/set the MartService dataset name.

=head2 attributes

Get/set the list of attributes to be retrieved from the MartService.  This may be specified as
an arrayref or a comma-delimited list.

=head2 ua

Return a cached LWP::UserAgent object or instantiate a new one.

=head2 build_query_xml

Takes a hashref of name/value pairs and returns an XML query string to be POSTed to the MartService.

=head2 query

Passed a list of name/value pairs, performs a query against the MartService and returns an arrayref
of returned results.  Each result is a hashref with keys named after this object's B<attributes>.    

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

The following values may be specified in the main configuration file:

=over 4

=item martservice

The URL for the BioMart MartService.

=item dataset

The name of the MartService dataset.

=item attributes

A comma-separated list of attributes to be retrieved from the BioMart MartService.

=item timeout

How long (in seconds) to wait for a response from the BioMart MartService.

=back

=head1 DEPENDENCIES

=over 4

=item List::MoreUtils

=item LWP::UserAgent

=item XML::Writer

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Ray Miller <rm7@sanger.ac.uk>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Wellcome Trust Sanger Institute

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut
