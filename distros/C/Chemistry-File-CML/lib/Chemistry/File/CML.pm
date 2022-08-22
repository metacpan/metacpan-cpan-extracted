package Chemistry::File::CML;

our $VERSION = '0.11'; # VERSION
# $Id$

use base 'Chemistry::File';
use Chemistry::Mol;
use XML::LibXML;
use strict;
use warnings;

our $DEBUG = 0;

=head1 NAME

Chemistry::File::CML - CML reader

=head1 SYNOPSIS

    use Chemistry::File::CML;

    # read a molecule
    my $mol = Chemistry::Mol->read('myfile.cml');

=cut

Chemistry::Mol->register_format(cml => __PACKAGE__);

=head1 DESCRIPTION

Chemical Markup Language reader.

This module automatically registers the 'cml' format with Chemistry::Mol.

This version only reads some of the information available in CML files.
It does not read stereochemistry yet, but this is envisaged in future.
Writing CML files is not implemented yet too.

This module is part of the PerlMol project, L<https://github.com/perlmol>.
    

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

    my @cml_molecules = $xp->findnodes( '/cml:cml/cml:molecule' );
    if( !@cml_molecules ) {
        @cml_molecules = $xp->findnodes( '/cml:molecule' ); # Somewhy some CMLs need this
    }

    my @molecules;
    for my $molecule (@cml_molecules) {
        my $mol = $mol_class->new;
        push @molecules, $mol;

        $mol->name( $molecule->getAttribute( 'id' ) ) if $molecule->hasAttribute( 'id' );

        my ($atomArray) = $molecule->getChildrenByTagName( 'atomArray' );
        next unless $atomArray; # Skip empty molecules

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
            }
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
            $mol->new_bond(
                type => $type, 
                atoms => [map { $atom_by_name{$_} } split ' ', $bond->getAttribute( 'atomRefs2' )],
                order => $order,
                ($type eq 'A' ? (aromatic => 1) : ()),
            );
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
            next if $explicit_hydrogens == $hydrogens_by_id{$id};
            $atom->implicit_hydrogens( $hydrogens_by_id{$id} - $explicit_hydrogens );
        }
    }

    return @molecules;
}

sub name_is {
    my ($self, $fname) = @_;
    $fname =~ /\.cml$/i;
}

sub file_is {
    my ($self, $fname) = @_;
    $fname =~ /\.cml$/i;
}

1;

=head1 SOURCE CODE REPOSITORY

L<https://github.com/perlmol/Chemistry-File-CML>

=head1 SEE ALSO

L<Chemistry::Mol>

=head1 AUTHOR

Andrius Merkys <merkys@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2022 Andrius Merkys. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut
