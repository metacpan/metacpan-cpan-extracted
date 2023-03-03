package Chemistry::File::CML;

our $VERSION = '0.14'; # VERSION
# $Id$

use base 'Chemistry::File';
use Chemistry::Mol;
use XML::LibXML;
use strict;
use warnings;

our $DEBUG = 0;

=head1 NAME

Chemistry::File::CML - Chemical Markup Language reader/writer

=head1 SYNOPSIS

    use Chemistry::File::CML;

    # read a molecule
    my $mol = Chemistry::Mol->read('myfile.cml');

    # write a molecule
    $mol->write('myfile.cml');

=cut

Chemistry::Mol->register_format(cml => __PACKAGE__);

=head1 DESCRIPTION

Chemical Markup Language reader/writer.

This module automatically registers the 'cml' format with L<Chemistry::Mol>.

This version reads and writer only some of the information available in CML files.
It does not read stereochemistry yet, but this is envisaged in future.

This module is part of the PerlMol project, L<https://github.com/perlmol>.

=head2 Format specifics

As not all atoms in a CML file may have coordinates, those who do are marked with an attribute with value 1:

    $atom->attr('cml/has_coords');

This is because L<Chemistry::Mol> has no other way to denote missing coordinates.

=cut

sub parse_string {
    my ($self, $s, %opts) = @_;

    my $mol_class  = $opts{mol_class}  || 'Chemistry::Mol';
    my $atom_class = $opts{atom_class} || $mol_class->atom_class;
    my $bond_class = $opts{bond_class} || $mol_class->bond_class;
    local $_;

    my $cml = XML::LibXML->load_xml( string => $s );
    my $xp = XML::LibXML::XPathContext->new( $cml );
    $xp->registerNs( 'cml', 'http://www.xml-cml.org/schema' );

    my @molecules;
    for my $molecule ($xp->findnodes( '//cml:molecule' )) {
        my $mol = $mol_class->new;
        $mol->name( $molecule->getAttribute( 'id' ) ) if $molecule->hasAttribute( 'id' );

        my ($atomArray) = $molecule->getChildrenByTagName( 'atomArray' );
        next unless $atomArray; # Skip empty molecules

        push @molecules, $mol;

        my %atom_by_name;
        my %hydrogens_by_id;

        # atomArray
        for my $element ($atomArray->getChildrenByTagName( 'atom' )) { # for each atom...
            my ($symbol, $charge, $hydrogen_count, $mass_number);
            my @coord3;

            next unless $element->hasAttribute( 'id' );
            my $id = $element->getAttribute( 'id' );
            my $atom = $atom_by_name{$id} = $mol->new_atom( name => $id );

            if( $element->hasAttribute( 'elementType' ) ) {
                $atom->symbol( $element->getAttribute( 'elementType' ) );
            }
            if( $element->hasAttribute( 'formalCharge' ) ) {
                $atom->formal_charge( int $element->getAttribute( 'formalCharge' ) );
            }
            if( $element->hasAttribute( 'hydrogenCount' ) ) {
                $hydrogens_by_id{$atom->id} = int $element->getAttribute( 'hydrogenCount' );
            }
            if( $element->hasAttribute( 'isotopeNumber' ) ) {
                $atom->mass_number( int $element->getAttribute( 'isotopeNumber' ) );
            }
            if( $element->hasAttribute( 'x3' ) &&
                $element->hasAttribute( 'y3' ) &&
                $element->hasAttribute( 'z3' ) ) {
                $atom->coords( map { $_ * 1 } $element->getAttribute( 'x3' ),
                                              $element->getAttribute( 'y3' ),
                                              $element->getAttribute( 'z3' ) );
                $atom->attr( 'cml/has_coords' => 1 );
            }
        }

        # Second pass through atoms to set chirality (if supported)
        for my $element ($atomArray->getChildrenByTagName( 'atom' )) { # for each atom...
            my( $atomParity ) = $element->getChildrenByTagName( 'atomParity' );
            next unless $atomParity &&
                        $atomParity->hasAttribute( 'atomRefs4' ) &&
                        $atomParity->textContent =~ /^-?1$/;

            next unless $element->hasAttribute( 'id' );
            my $id = $element->getAttribute( 'id' );
            my $atom = $atom_by_name{$id};
            next unless $atom->can( 'chirality' );

            my @atoms = map { $atom_by_name{$_} }
                            split ' ', $atomParity->getAttribute( 'atomRefs4' );
            $atom->chirality( @atoms, int $atomParity->textContent );
        }

        my @bonds;
        my( $bondArray ) = $molecule->getChildrenByTagName( 'bondArray' );
        if( $bondArray ) {
            @bonds = $bondArray->getChildrenByTagName( 'bond' );
        }

        # bondArray
        for my $bond (@bonds) { # for each bond...
            my $order = my $type = $bond->getAttribute( 'order' );
            $order = 1 unless $order =~ /^[123]$/;

            my @atoms = map { $atom_by_name{$_} }
                            split ' ', $bond->getAttribute( 'atomRefs2' );
            my $mol_bond = $mol->new_bond(
                type => $type, 
                atoms => \@atoms,
                order => $order,
                ($type eq 'A' ? (aromatic => 1) : ()),
            );

            my( $bondStereo ) = $bond->getChildrenByTagName( 'bondStereo' );
            if( $mol_bond->can( 'cistrans' ) &&
                $bondStereo &&
                $bondStereo->hasAttribute( 'atomRefs4' ) &&
                $bondStereo->textContent =~ /^[CT]$/ ) {
                my @cistrans_atoms = map { $atom_by_name{$_} }
                                         split ' ', $bondStereo->getAttribute( 'atomRefs4' );
                if( $cistrans_atoms[1] ne $atoms[0] ) {
                    ( $cistrans_atoms[0], $cistrans_atoms[3] ) =
                        ( $cistrans_atoms[3], $cistrans_atoms[0] );
                    $mol_bond->cistrans( $cistrans_atoms[0],
                                         $cistrans_atoms[3],
                                         $bondStereo->textContent eq 'C' ? 'cis' : 'trans' );
                }
            }
        }

        # calculate implicit hydrogens
        for my $id (sort keys %hydrogens_by_id) {
            my $atom = $mol->by_id( $id );
            my $explicit_hydrogens = scalar grep { $_->symbol eq 'H' }
                                                 $atom->neighbors;
            if( $explicit_hydrogens > $hydrogens_by_id{$id} ) {
                warn 'total number of attached hydrogen atoms is ' .
                     "less than the number of explicit hydrogen atoms\n";
                next;
            }
            $atom->implicit_hydrogens( $hydrogens_by_id{$id} - $explicit_hydrogens );
        }
    }

    return @molecules;
}

sub write_string {
    my ($self, $mol, %opts) = @_;
    my $cml = sprintf '  <molecule id="%s">' . "\n", $mol->name;

    # Write the atomArray
    $cml .= "    <atomArray>\n";
    for my $atom ($mol->atoms) {
        my %attributes = ( id => $atom->name,
                           elementType => $atom->symbol );

        if( $atom->attr( 'cml/has_coords' ) ) {
            ( $attributes{x3}, $attributes{y3}, $attributes{z3} ) = $atom->coords->array;
        }

        $attributes{formalCharge} = $atom->formal_charge if $atom->formal_charge;
        $attributes{isotopeNumber} = $atom->mass_number if $atom->mass_number;

        if( defined $atom->implicit_hydrogens ) {
            $attributes{hydrogenCount} =
                $atom->implicit_hydrogens +
                scalar grep { $_->symbol eq 'H' } $atom->neighbors;
        }

        $cml .= '      <atom ' .
                join( ' ', map { $_ . '="' . $attributes{$_} . '"' }
                           sort { ($b eq 'id') <=> ($a eq 'id') || $a cmp $b }
                                keys %attributes ) .
                "/>\n";
    }
    $cml .= "    </atomArray>\n";

    # Write the bondArray (if any)
    if ($mol->bonds) {
        $cml .= "    <bondArray>\n";
        for my $bond ($mol->bonds) {
            $cml .= '      <bond atomRefs2="' .
                    join( ' ', map { $_->name } $bond->atoms ) .
                    sprintf '" order="%s"/>' . "\n",
                            $bond->type;
        }
        $cml .= "    </bondArray>\n";
    }

    $cml .= "  </molecule>\n";
    return $cml;
}

sub name_is {
    my ($self, $fname) = @_;
    $fname =~ /\.cml$/i;
}

sub file_is {
    my ($self, $fname) = @_;
    $fname =~ /\.cml$/i;
}

sub write_header {
    my ($self) = @_;
    my $fh = $self->fh;
    print $fh "<?xml version=\"1.0\"?>\n<cml xmlns=\"http://www.xml-cml.org/schema\">\n";
}

sub write_footer {
    my ($self) = @_;
    my $fh = $self->fh;
    print $fh "</cml>\n";
}

1;

=head1 SOURCE CODE REPOSITORY

L<https://github.com/perlmol/Chemistry-File-CML>

=head1 SEE ALSO

L<Chemistry::Mol>

=head1 AUTHOR

Andrius Merkys <merkys@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2022-2023 Andrius Merkys. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut
