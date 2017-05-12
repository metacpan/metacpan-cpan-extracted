package CAM::PDF::Annot;

use 5.010000;
use strict;
use warnings;

our $VERSION = '0.09';

use base qw(CAM::PDF);
use Data::Dumper;

=head1 NAME

CAM::PDF::Annot - Perl extension for appending annotations on PDFs

=head1 SYNOPSIS

  use strict;
  use CAM::PDF::Annot;
  my $pdf = CAM::PDF::Annot->new( 'pdf1.pdf' );
  my $otherDoc = CAM::PDF::Annot->new( 'pdf2.pdf' );
  for my $page ( 1 .. $pdf->numPages() ) {
	my %refs;
    for my $annotRef ( @{$pdf->getAnnotations( $page )} ) {
	  $otherDoc->appendAnnotation( $page, $pdf, $annotRef, \%refs );
	}
  }
  $otherDoc->output('pdf_merged.pdf');


=head1 DESCRIPTION

CAM::PDF::Annot is an extension to C<CAM::PDF> to ease the appending of
Annotation objects to pdf documents.

=head2 EXPORT

This module does not export any functions.

=cut

=head2 METHODS

=over

=item CAM::PDF::Annot->new( 'file.pdf' );

Constructor method, same as C<CAM::PDF>.

=cut

#sub new {
#	my $class = shift;
#    my $self = $class->SUPER::new( @_ );
#
#    bless $self, $class;
#}

=item $doc->appendAnnotation($page, $doc, $annotRef, $refKeys) *NEW*

Duplicate an annotation object from another PDF document and add it to this
document. It also copies its appearance object and Popup object. In case
this is a Text Subtype Annot object (a Reply to another Annot object) it
recurses to append the Annot object it refers to (using the IRT reference
of the object).

It was only tested for annotations of /Type /Annot and /Subtype 
/Square, /Circle, /Polygon and /Text. It is hardcoded to not allow any other
subtypes (sometime in the future this may change).

It takes a hash reference C<$refKeys> and adds the altered keys so it can
be used across calls and update references across objects (and avoid
adding the same object more than once).

=cut

sub appendAnnotation($$$\%) {
	my ( $self, $page, $otherDoc, $otherAnnotRef, $refKeys ) = @_;

	# Sanity check: it only appends objects of /Type /Annot /Subtype /Square|Circle|Polygon|Text
	# returns an empty hash reference
	return {} if ( $otherDoc->getValue( $otherAnnotRef )->{Subtype}{value} !~ /(Square|Circle|Polygon|Text)/ );

	# If document does not have annots in this page, create an annots property
	unless ( exists $self->getPage( $page )->{Annots} ) {
		$self->getPage( $page )->{Annots} = CAM::PDF::Node->new('array',[], scalar $self->getPageObjnum( $page ),'0');
	}

	# get this page's annotation object it will be widely used
	my $annots = $self->getPage( $page )->{Annots};
	# dereferences the previous value in case the annots object was originaly a reference to the object itself...
	$annots = $self->dereference( $annots->{value} )->{value} while $annots->{type} eq 'reference';

	# append the annot object based on the object number
	my $newkey = $self->appendObject( $otherDoc, $otherAnnotRef->{value}, 0 );
	# store the refkey for later
	$$refKeys{$otherAnnotRef->{value}} = $newkey;

	# append a reference to this annot to the annotations object of this page
	my $annotRef = CAM::PDF::Node->new('reference', "$newkey", $self->getPageObjnum( $page ), '0');
	push @{$annots->{value}}, $annotRef;

	# Append the appearance object (if it exists)
	$self->_appendAppearanceObject( $otherDoc, $annotRef, $refKeys );

	# Append the popup object (if it exists)
	$self->_appendPopupObject( $page, $otherDoc, $annotRef, { $otherAnnotRef->{value} => $newkey }, $refKeys );

	# Verify if it has an IRT reference (meaning, if it refers to another annotation)
	my $annotVal = $self->getValue( $annotRef );
	if ( exists $annotVal->{IRT} ) {
		# Check if it is a reference to an already added object
		unless ( exists $refKeys->{$annotVal->{IRT}{value}} ) {
			# In this case the IRT must be added
			$self->appendAnnotation( $page, $otherDoc, $annotVal->{IRT}, $refKeys );
		}
	}

	# Since the annots object was altered, let's flag it
	# I dont know if it is necessary to store it in cache but it seems to work
	$self->{objcache}{$annots->{objnum}} = $self->dereference( $annots->{objnum} );
	$self->{changes}{$annots->{objnum}} = 1;
	$self->{versions}{$annots->{objnum}} = -1;

	# Now, update all the references for the object
	$self->changeRefKeys( $self->{objcache}{$newkey}, $refKeys );

	if (wantarray) {
		return ($newkey, %$refKeys);
	}
	else {
		return $newkey;
	}
}

sub _appendAppearanceObject() {
	my ( $self, $otherDoc, $annotRef, $refKeys ) = @_;
	my $annotVal = $self->getValue( $annotRef );
	my %refs =();

	# Check if this annot has a reference to an APeareance object 
	# (it is expected it will have it...)
	if ( exists $annotVal->{AP} ) {
		my $ap = $self->getValue( $annotVal->{AP} );
		# Check if it wasn't already added before
		unless ( exists $refKeys->{$ap->{N}{value}} ) {
			my $apNkey = $self->appendObject( $otherDoc, $ap->{N}{value}, 0 );

			# keep track of this addition
			$$refKeys{$ap->{N}{value}} = $apNkey;
			$refs{$ap->{N}{value}} = $apNkey;
		}
		# Apparently only for reply cases (in which the APearance object seems to have more than one element
		if ( exists $ap->{D} ) {
			unless ( exists $refKeys->{$ap->{D}{value}} ) {
				my $apDkey = $self->appendObject( $otherDoc, $ap->{D}{value}, 0 );
				
				# keep track of this addition
				$$refKeys{$ap->{D}{value}} = $apDkey;
				$refs{$ap->{D}{value}} = $apDkey;
			}
		}
	}
	return %refs;
}

sub _appendPopupObject() {
	my ( $self, $page, $otherDoc, $annotRef, $parentKeys, $refKeys ) = @_;
	my $annotVal = $self->getValue( $annotRef );
	my $annots = $self->getPage( $page )->{Annots};
	my %refs =();

	# Now check if it has a reference to a popup object
	# (it is bound to have it...)
	# And also check if it wasnt already added
	if ( exists $annotVal->{Popup} ) {
		unless ( exists $refKeys->{$annotVal->{Popup}{value}} ) {
			my $pupkey = $self->appendObject( $otherDoc, $annotVal->{Popup}{value}, 0 );
			$$refKeys{$annotVal->{Popup}{value}} = $pupkey;
			$refs{$annotVal->{Popup}{value}} = $pupkey;
			
			# change its parent reference
			$self->changeRefKeys( $self->{objcache}{$pupkey}, $parentKeys );

			# it also gets a place on the Annots property of the page object
			my $pupRef = $self->copyObject( $annotVal->{Popup} );
			# change the keys in the newly created one to reflect the appended annotation object
			$self->changeRefKeys( $pupRef, { $pupRef->{value} => $pupkey } );
			$self->setObjNum( $pupRef, $annots->{objnum} );
			push @{$annots->{value}}, $pupRef;
		}
	}
	return %refs;
}

=item $doc->getAnnotations( $page )

Returns an array reference to the Annots array of the page. The array
contains CAM::PDF::Nodes (see C<CAM::PDF>) of type 'reference' refering
to the annotations.

=cut

sub getAnnotations($) {
		my ( $self, $p ) = @_;
		return $self->getValue( $self->getPage( $p )->{Annots} ) || [];
}

1;
__END__

=back

=head1 CAVEATS

This module was only tested for some subtypes of annotation objects and
may not work consistently for untested subtypes.

=head1 SEE ALSO

CAM::PDF

=head1 AUTHOR

Donato Azevedo, E<lt>donatoaz _AT_ gmail.comE<gt>

Many thanks to Mr. Chris Dolan for developing C<CAM::PDF>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Donato Azevedo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
