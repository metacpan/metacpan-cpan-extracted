package Chemistry::File::OPTIMADE;

our $VERSION = '0.11'; # VERSION
# $Id$

use strict;
use warnings;

use base 'Chemistry::File';

use Chemistry::Mol;
use JSON;
use List::Util qw( any );
use URL::Encode qw( url_params_multi );

my @mandatory_fields = qw( cartesian_site_positions species species_at_sites );

=head1 NAME

Chemistry::File::OPTIMADE - OPTIMADE reader

=head1 SYNOPSIS

    use Chemistry::File::OPTIMADE;

    # read a molecule
    my $file = Chemistry::File::OPTIMADE->new( file => 'myfile.json' );
    my $mol = $file->read();

=cut

# Format is not registered, as OPTIMADE does not have proper file extension.
# .json is an option, but not sure if it will not clash with anything else.

=head1 DESCRIPTION

OPTIMADE structure representation reader.

=cut

sub parse_string {
    my ($self, $s, %opts) = @_;

    my $mol_class  = $opts{mol_class}  || 'Chemistry::Mol';
    my $atom_class = $opts{atom_class} || $mol_class->atom_class;
    my $bond_class = $opts{bond_class} || $mol_class->bond_class;

    my $json = decode_json $s;

    if( $json->{meta} &&
        $json->{meta}{api_version} &&
        $json->{meta}{api_version} =~ /^[^01]\./ ) {
        warn 'OPTIMADE API version ' . $json->{meta}{api_version} .
             ' encountered, this module supports versions 0 and 1, ' .
             'later versions may not work as expected' . "\n";
    }

    my $required_fields_selected;
    if( $json->{meta} &&
        $json->{meta}{query} &&
        $json->{meta}{query}{representation} ) {
        if( $json->{meta}{query}{representation} =~ /\?/ ) {
            my( $query ) = reverse split /\?/, $json->{meta}{query}{representation};
            $query = url_params_multi $query;
            if( $query->{response_fields} ) {
                my @response_fields = split ',', $query->{response_fields}[0];
                $required_fields_selected =
                    (any { $_ eq 'cartesian_site_positions' } @response_fields) &&
                    (any { $_ eq 'species' } @response_fields) &&
                    (any { $_ eq 'species_at_sites' } @response_fields);
            } else {
                $required_fields_selected = ''; # false
            }
        } else {
            $required_fields_selected = ''; # false
        }
    }

    return () unless $json->{data};

    my @molecule_descriptions;
    if(      ref $json->{data} eq 'HASH' && $json->{data}{attributes} ) {
        @molecule_descriptions = ( $json->{data} );
    } elsif( ref $json->{data} eq 'ARRAY' ) {
        @molecule_descriptions = @{$json->{data}};
    } else {
        return ();
    }

    my @molecules;
    for my $description (@molecule_descriptions) {
        my $mol = $mol_class->new( name => $description->{id} );
        my $attributes = $description->{attributes};

        # TODO: Warn about disorder

        if( any { !exists $attributes->{$_} } @mandatory_fields ) {
            warn 'one or more of the mandatory fields (' .
                 join( ', ', map { "'$_'" } @mandatory_fields ) .
                 'not found in input for molecule \'' .
                 $description->{id} . '\', skipping' . "\n";
        }

        my %species = map { $_->{name} => $_ } @{$attributes->{species}};
        for my $site (0..$#{$attributes->{cartesian_site_positions}}) {
            my $species = $species{$attributes->{species_at_sites}[$site]};

            # FIXME: For now we are taking the first chemical symol.
            # PerlMol is not capable to represent mixture sites.
            my $atom = $mol->new_atom( coords => $attributes->{cartesian_site_positions}[$site],
                                       symbol => $species->{chemical_symbols}[0] );
            if( exists $species->{mass} ) {
                $atom->mass( $species->{mass}[0] );
            }
        }
        push @molecules, $mol;
    }
    return @molecules;
}

1;

=head1 SOURCE CODE REPOSITORY

L<https://github.com/perlmol/Chemistry-File-OPTIMADE>

=head1 SEE ALSO

L<Chemistry::Mol>, L<Chemistry::File>

The OPTIMADE Home Page at https://www.optimade.org

=head1 AUTHOR

Andrius Merkys <merkys@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2022 Andrius Merkys. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut
