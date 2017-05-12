package Chemistry::PointGroup;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Chemistry::PointGroup - Group theory for normal modes of vibration

=head1 SYNOPSIS
	
	# the benzene molecule 
  	use Chemistry::PointGroup::D6h;
	my @R = Chemistry::PointGroup::D6h->symmetry_elements;
	my @Ur = qw(12 0 0 0 4 0 0 0 0 12 0 4);
	my %Ur;
	@Ur{@R}=@Ur;
	my $mol = new Chemistry::PointGroup::D6h( %Ur );
	my %ri_mol = $mol->irr;
	print "Irreducible Representations:\n";
	print map {$ri_mol{$_}," ",$_,"\t"} sort keys %ri_mol;

	print "\n\n";
	my $benzene = 
		Chemistry::PointGroup::D6h->new(
	       E => 12, C6 => 0, C3 => 0, C2 => 0, C2f => 4, C2s => 0,
			 i => 0,  S3 => 0, S6 => 0, sh => 12, sd => 0, sv => 4);
								  
	my %ri_benzene = $benzene->irr;
	print "Irreducible Representations:\n";
	print map{$ri_benzene{$_}," ", $_,"\t"} sort keys %ri_benzene;
	print "\n";
	print "Normal Modes: ", $benzene->normal_modes,"\n";
	print "Table of Characters\n", 
			Chemistry::PointGroup::D6h->character_tables, "\n\n";

	
	# methane
	use Chemistry::PointGroup::Td;
	my @sy = Chemistry::PointGroup::Td->symmetry_elements;
	print "Symmetry elements: @sy\n";
	print "CH4\n";
	my $met = Chemistry::PointGroup::Td->new( 
	                E => 5, C3 => 2, C2 => 1, S4 => 1, sd => 3);
	my %ri_met = $met->irr;
	print "Irreducible Representations:\n";
	print map{$ri_met{$_}," ", $_, "\t"} sort keys %ri_met;
	print "\n";
	print "Normal Modes: ", $met->normal_modes,"\n";
	print "Table of Characters\n", $met->character_tables, "\n\n";
	
	# ammonia
	use Chemistry::PointGroup::C3v;
	print "NH3\n";
	my $am = Chemistry::PointGroup::C3v->new(E => 4, C3 => 1, sv => 2);
	my %ri_am = $am->irr;
	print "Irreducible Representations:\n";
	print map{$ri_am{$_}," ",$_,"\t"} sort keys %ri_am;
	print "\n";
	print "Normal Modes: ", $am->normal_modes,"\n";
	print "Table of Characters\n", $am->character_tables, "\n\n";
	
	# CHCl3
	use Chemistry::PointGroup::C3v;
	print "CHCl3\n";
	my $cl = Chemistry::PointGroup::C3v->new(E => 5, C3 => 2, sv => 3);
	my %ri_cl = $cl->irr;
	print "Irreducible Representations:\n";
	print map{$ri_cl{$_}," ", $_,"\t"} sort keys %ri_cl;
	print "\n";
	print "Normal Modes: ", $cl->normal_modes,"\n";
	print "Table of Characters\n", $cl->character_tables, "\n\n";
	

	# Trans N2F2
	use Chemistry::PointGroup::C2h;
	my @sy = Chemistry::PointGroup::C2h->symmetry_elements;
	print "Symmetry elements: @sy\n";
	print "Trans N2F2\n";
	my $nf = Chemistry::PointGroup::C2h->new( E => 4, C2 => 0, i => 0, sh=> 4);
	my %ri_nf = $nf->irr;
	print "Irreducible Representations:\n";
	print map{$ri_nf{$_}," ", $_, "\t"} sort keys %ri_nf;
	print "\n";
	print "Normal Modes: ", $nf->normal_modes,"\n";
	print "Table of Characters\n", $nf->character_tables, "\n\n";


	
=head1 DESCRIPTION

Many common molecules, for example, water, ammonia, methane,etc.,
possess some symmetry. In calculating the normal modes and frequencies
of vibration, symmetry considerations can reduce enormously the labor
of the calculations. The symmetry and geometry of a molecular model can
be used to determine the number and symmetry of fundamental frequencies,
their degeneracies, the selection rules for the infrared and Raman spectra.


=head1 METHODS

=over

=item $mol = Chemistry::PointGroup::XX->new( %U )
	
Create a new Chemistry::PointGroup::XX object, where XX is a point group.
The value of %U is the number of atoms which are not shifted when the
symmetry operation R acts on the atoms of the molecule. The key of %U
is the symmetry operation.

=item $table = $mol->character_tables

Return the table of characters

=item @R = $mol->symmetry_elements

Return the symmetry operations

=item $modes = $mol->normal_modes

Return the number of normal modes of vibration

=item %ri = $mol->irr

Return the Irreducible Representations for the vibrations.
The key of %ri is the irreducible representations and
the value is the number of this representation

See B<Molecular vibrations> I<The Theory of Infrared and Raman
Vibrational Spectra>, E.B. Wilson, J.C. Decius and P.C. Cross,
Dover - C<ISBN 0-486-63941-X>

=back


=head1 VERSION

0.01

=head1 SEE ALSO

=over 

=item L<Chemistry::PointGroup::C1>, L<Chemistry::PointGroup::Ci>, 

=item L<Chemistry::PointGroup::Cs>, L<Chemistry::PointGroup::C2>,

=item L<Chemistry::PointGroup::C2h>, L<Chemistry::PointGroup::C2v>,

=item L<Chemistry::PointGroup::D2>, L<Chemistry::PointGroup::D2h>,

=item L<Chemistry::PointGroup::C4>, L<Chemistry::PointGroup::S4>,

=item L<Chemistry::PointGroup::C4h>, L<Chemistry::PointGroup::C4v>,

=item L<Chemistry::PointGroup::D2d>, L<Chemistry::PointGroup::D4>,

=item L<Chemistry::PointGroup::D4h>, L<Chemistry::PointGroup::C3>,

=item L<Chemistry::PointGroup::S6>, L<Chemistry::PointGroup::C3v>,

=item L<Chemistry::PointGroup::D3>, L<Chemistry::PointGroup::D3d>,

=item L<Chemistry::PointGroup::C3h>, L<Chemistry::PointGroup::C6>,

=item L<Chemistry::PointGroup::C6h>, L<Chemistry::PointGroup::D3h>,

=item L<Chemistry::PointGroup::C6v>, L<Chemistry::PointGroup::D6>,

=item L<Chemistry::PointGroup::D6h>, L<Chemistry::PointGroup::T>,

=item L<Chemistry::PointGroup::Th>, L<Chemistry::PointGroup::Td>,

=item L<Chemistry::PointGroup::O>, L<Chemistry::PointGroup::Oh>,

=back

=head1 AUTHOR

Leo Manfredi, E<lt>manfredi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Leo Manfredi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
