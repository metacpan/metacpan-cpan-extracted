package Chemistry::File::QChemOut;

$VERSION = '0.10';
# $Id: QChemOut.pm,v 1.1.1.1 2006/10/04 16:13:50 itubert Exp $

use base qw(Chemistry::File);
use Chemistry::Mol;
use Carp;
use strict;
use warnings;

=head1 NAME

Chemistry::File::QChemOut - Q-Chem ouput molecule format reader

=head1 SYNOPSIS

    use Chemistry::File::QChemOut;

    # read an QChemOut file
    my $mol = Chemistry::Mol->read("myfile.out", format => 'qchemout');

    # read all the intermediate structures (e.g., optimization steps)
    my $mol = Chemistry::Mol->read("myfile.out", 
        format => 'chemout', all => 1);

=cut

=head1 DESCRIPTION

This module reads Q-Chem output files. It automatically registers the
'qchemout' format with Chemistry::Mol, so that Q-Chem outuput files may be
identified and read using Chemistry::Mol->read().

The current version of this reader simply extracts the cartesian coordinates
and symbols from the Q-Chem outuput file. All other information is ignored.

=head1 INPUT OPTIONS

=over

=item all

If true, read all the intermediate structures, as in a structure optimization.
This causes $mol->read to return an array instead of a single molecule.
Default: false.

=back

=cut

Chemistry::Mol->register_format(qchemout => __PACKAGE__);

sub parse_string {
    my ($class, $s, %opts) = @_;

    my $mol_class  = $opts{mol_class}  || 'Chemistry::Mol';
    my $atom_class = $opts{atom_class} || $mol_class->atom_class;

    my @coord_blocks = $s =~ m{
        Standard\ Nuclear\ Orientation
        .*? 
        ----
        (?:\n|\r\n?)
        (.*?)           # coordinate block
        \ ----
    }smxg;

    croak "no coordinates found" unless @coord_blocks;

    unless ($opts{all}) {
        # keep only the last block
        splice @coord_blocks, 0, @coord_blocks - 1;
    }

    my @mols;
    for my $block (@coord_blocks) {
        my $mol = $mol_class->new();
        my @lines = split /(?:\n|\r\n?)/, $block;

        my $i = 0;
        for my $line (@lines) {
            $i++;
            $line =~ s/^\s+//;
            my ($n, $symbol, $x, $y, $z) = split ' ', $line;

            my $atom = $mol->new_atom(
                symbol => $symbol, 
                coords => [$x, $y, $z],
            );
        }
        push @mols, $mol;
    }

    return $opts{all} ? @mols : $mols[0];
}

sub name_is {
    my ($class, $fname) = @_;
    return;
    $fname =~ /\.xyz$/i;
}

sub file_is {
    my ($class, $fname) = @_;
    return;
    $fname =~ /\.xyz$/i;
}

sub write_string {
    my ($class, $mol, %opts) = @_;

    croak "QChemOut writing not implemented";
}

1;

=head1 VERSION

0.10

=head1 SEE ALSO

L<Chemistry::Mol>, L<http://www.perlmol.org/>.

=head1 AUTHOR

Ivan Tubert-Brohman <itub@cpan.org>

=cut

