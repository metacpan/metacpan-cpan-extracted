package CAM::PDF::Annot::Parsed;

use 5.010000;
use strict;
use warnings;

our $VERSION = '0.10';

=head1 NAME

CAM::PDF::Annot::Parsed - Perl extension for pluggable parsing for PDF Annotations

=head1 SYNOPSIS

	# Define a parsing interface for the annotations
	package MyYAMLTinyParser;
	use base qw(YAML::Tiny);
	# MUST DEFINE parse METHOD!! it takes as input the string contents
	#  of the pdf annotations and must spit out the inflated version of it
	sub parse { return shift->read_string( shift )->[0] }
	1;

	package main;
	my $pdf = CAM::PDF::Annot::Parsed->( 'file.pdf', 'MyYAMLTinyParser' );

	for my $parsed_annot ( @{$pdf->getParsedAnnots} ) {
		# Since I am using YAML::Tiny to parse it, each $parsed_annot
		#  is a YAML::Tiny object
		# if document has annotations with the mask:
		
		#author:
		#    name: Donato Azevedo
		#

		print $parsed_annot->[0]{author}{name}, "\n";
	}

=head1 DESCRIPTION

	This module provides a way to use a pluggable parser to process
	comments on annotations of PDF documents. Annotations are free
	text strings generally contained in pop ups for drawing markups
	of PDF documents.

=cut

use base qw( CAM::PDF::Annot );

=item

Constructor

	my $p = CAM::PDF::Annot::Parsed->new($file, $parser);

Creates an instance of the object

=cut

sub new {
    my ($class, $file, $parser) = @_;
    my $self = $class->SUPER::new($file);
    $self->{_parser} = $parser;
    bless $self, $class;
}

=item

	my $arrRef = $p->getParsedAnnots( $page );

Returns a reference to an array containing the objects parsed by $parser (as
passed to the constructor).

=cut

sub getParsedAnnots {
    my ($self, $page) = @_;
    my $annots = [];
    for my $annot ( @{$self->getAnnotations($page)} ) {
		my $annotVal = $self->getValue( $annot );
		if ( exists $annotVal->{Contents} ) {
			( my $parse_str = $self->getValue( $annotVal->{Contents} ) ) =~ s/\r\n/\n/g;
			if ( my $parsed = $self->{_parser}->parse( $parse_str ) ) {
			    push @$annots, $parsed;
			}
		}
	}
    return $annots;
}

1;
__END__

=head1 SEE ALSO

	CAM::PDF
	CAM::PDF::Annot

=head1 AUTHOR

Donato Azevedo, E<lt>donatoaz@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Donato Azevedo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

