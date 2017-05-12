package Chemistry::MolecularMass;

=pod

=head1 NAME

Chemistry::MolecularMass - Perl extension for calculating
molecular mass of a chemical compound given its chemical formula.

=head1 VERSION

0.1

=head1 AUTHOR AND COPYRIGHT

Copyright (C) 2000, Maksim A. Khrapov
maksim@recursivemind.com
http://www.recursivemind.com

This program is distributed under Perl Artistic Lisence.
No warranty. Use at your own risk.

=head1 SYNOPSIS

   use Chemistry::MolecularMass;
   my $mm = new Chemistry::MolecularMass;
   my $mass = $mm->calc_mass("C2H5OH");
   print $mass if defined($mass);

   my %default_macros = $mm->all_macros;
   $mm->add_macros("Ts" => "CH3C6H4SO2", "Bs" => "BrC6H4SO2");
   $mass = $mm->calc_mass("TsOEt");
   $mass = $mm->calc_mass("{[(CH3)3Si]2N}2CHCH<CH2Br>2");

   ### if you are an organic chemist, you might want to do this:
   $mm->add_macros("Pr" => "C3H7", "Ac" => "CH3COO");

   my %elements = $mm->all_elements;
   $mm->replace_elements("Na" => 24.00, "Cl" => 37.00);
   $mass = $mm->calc_mass("NaCl");

=head1 DESCRIPTION

   Chemistry::MolecularMass is an Object Oriented Perl module for calculating
   molcular mass of chemical compounds implemented with Perl and C.
   Molecular masses of elements stored in the module follow recommendations
   of IUPAC (1995). The module includes elements from H(1) through
   Uuu(113) and isotopes of hydrogen: deuterium and tritium. The module
   also allows a programmer to change the default masses of elements
   for work with isotopes. It also includes some of the more common
   chemical abbreviations as macros and allows to add new macros and
   change the values of old macros. A hash of all macros and a hash
   of all elements can be returned.

   Arbitrary element names can be added, they are expected, however, to
   start with an upper case letter followed by zero or more lower case
   letters. Macros can be any string of characters. Macros are substituted
   only once, so a macro should not evaluate to another macro. Legal
   characters in a formula are: A-Za-z0-9<>{}[]()
   Spaces are not allowed. Parentheses can be nested arbitrarily deep.

   Each MolecularMass object has its own hashes of macros and element 
   masses, so modifications made to one MolecularMass object do NOT
   affect another. The whole thing was programmed with reentrancy
   in mind, so it should be thread safe as well.

=cut

use strict;
use vars qw($VERSION @ISA);

require DynaLoader;

@ISA = qw(DynaLoader);

$VERSION = '0.1';

bootstrap Chemistry::MolecularMass $VERSION;

######################### Globals ###############################

my %macros = (
   'Me' => 'CH3',
   'Et' => 'CH3CH2',
   # Pr is an element, if user wants it, let them install it themselves
   'Bu' => 'C4H9',
   'Bn' => 'C6H5CH2',
   'Cp' => 'C5H5',
   'Ph' => 'C6H5',
   # Ac is an element
   'Bz' => 'C6H5CO',
);

my %elements = (
   "H" => 1.00794,
   "D" => 2.014101,
   "T" => 3.016049,
   "He" => 4.002602,
   "Li" => 6.941,
   "Be" => 9.012182,
   "B" => 10.811,
   "C" => 12.0107,
   "N" => 14.00674,
   "O" => 15.9994,
   "F" => 18.9984032,
   "Ne" => 20.1797,
   "Na" => 22.989770,
   "Mg" => 24.3050,
   "Al" => 26.981538,
   "Si" => 28.0855,
   "P" => 30.973761,
   "S" => 32.066,
   "Cl" => 35.4527,
   "Ar" => 39.948,
   "K" => 39.0983,
   "Ca" => 40.078,
   "Sc" => 44.955910,
   "Ti" => 47.867,
   "V" => 50.9415,
   "Cr" => 51.9961,
   "Mn" => 54.938049,
   "Fe" => 55.845,
   "Co" => 58.933200,
   "Ni" => 58.6934,
   "Cu" => 63.546,
   "Zn" => 65.39,
   "Ga" => 69.723,
   "Ge" => 72.61,
   "As" => 74.92160,
   "Se" => 78.96,
   "Br" => 79.904,
   "Kr" => 83.80,
   "Rb" => 85.4678,
   "Sr" => 87.62,
   "Y" => 88.90585,
   "Zr" => 91.224,
   "Nb" => 92.90638,
   "Mo" => 95.94,
   "Tc" => 98,
   "Ru" => 101.07,
   "Rh" => 102.90550,
   "Pd" => 106.42,
   "Ag" => 107.8682,
   "Cd" => 112.411,
   "In" => 114.818,
   "Sn" => 118.710,
   "Sb" => 121.760,
   "Te" => 127.60,
   "I" => 126.90447,
   "Xe" => 131.29,
   "Cs" => 132.90545,
   "Ba" => 137.327,
   "La" => 138.9055,
   "Ce" => 140.116,
   "Pr" => 140.90765,
   "Nd" => 144.24,
   "Pm" => 145,
   "Sm" => 150.36,
   "Eu" => 151.964,
   "Gd" => 157.25,
   "Tb" => 158.92534,
   "Dy" => 162.50,
   "Ho" => 164.93032,
   "Er" => 167.26,
   "Tm" => 168.93421,
   "Yb" => 173.04,
   "Lu" => 174.967,
   "Hf" => 178.49,
   "Ta" => 180.9479,
   "W" => 183.84,
   "Re" => 186.207,
   "Os" => 190.23,
   "Ir" => 192.217,
   "Pt" => 195.078,
   "Au" => 196.96655,
   "Hg" => 200.59,
   "Tl" => 204.3833,
   "Pb" => 207.2,
   "Bi" => 208.98038,
   "Po" => 209,
   "At" => 210,
   "Rn" => 222,
   "Fr" => 223,
   "Ra" => 226,
   "Ac" => 227,
   "Th" => 232.038,
   "Pa" => 231.03588,
   "U" => 238.0289,
   "Np" => 237,
   "Pu" => 244,
   "Am" => 243,
   "Cm" => 247,
   "Bk" => 247,
   "Cf" => 251,
   "Es" => 252,
   "Fm" => 257,
   "Md" => 258,
   "No" => 259,
   "Lr" => 262,
   "Rf" => 261,
   "Db" => 262,
   "Sg" => 266,
   "Bh" => 264,
   "Hs" => 269,
   "Mt" => 268,
   "Uun" => 271,
   "Uuu" => 272,
);

#####################################################################
#
#      Methods
#
#####################################################################

sub new
{
   my $class = shift;

   my $hr = {};
   my %ma = %macros;
   my %el = %elements;

   $hr->{macros} = \%ma;
   $hr->{elements} = \%el;

   bless $hr, $class;
   return $hr;
}

#####################################################################

sub calc_mass
{
   my $self = shift;
   my $formula = shift;
   
   if($formula =~ /[^a-zA-Z\d()<>{}\[\]]/)
   {
      warn "Forbidden chars\n";
      return undef; ### Forbidden characters
   }

   unless(verify_parens($formula))
   {
      warn "Parentheses don't match\n";
      return undef; ### Parentheses do not match
   }

   $formula =~ tr/<>{}[]/()()()/;
   my $exp_formula = $self->expand_macros($formula);
   my %symbol_table = parse_formula($exp_formula);
   my $weight = $self->sum_el_masses(\%symbol_table);

   return $weight;
}

#####################################################################

sub expand_macros
{
   my $self = shift;
   my $formula = shift;

   my $macro;
   foreach $macro (keys %{$self->{macros}})
   {
      my $value = $self->{macros}->{$macro};
      eval '$formula =~ s/$macro/($value)/g';
   }
   return $formula;
}

#####################################################################

sub sum_el_masses
{
   my $self = shift;
   my $symtab = shift;

   my $weight = 0;

   my $el;
   foreach $el (keys %$symtab)
   {
      unless(exists $self->{elements}->{$el})
      {
	 warn "No such element: $el\n";
         return undef; ### No such element
      }

      $weight += $symtab->{$el} * $self->{elements}->{$el}; ### Number of atoms
      ### of this element multiplied by its atomic weight
   }
   return $weight;
}

#####################################################################

sub add_macros
{
   my $self = shift;
   my %ma = @_;

   my $key;
   foreach $key (keys %ma)
   {
      unless(exists $self->{macros}->{$key})
      {
         $self->{macros}->{$key} = $ma{$key};
      }
   }
   return 1;
}

#####################################################################

sub replace_macros
{
   my $self = shift;
   my %ma = @_;

   my $key;
   foreach $key (keys %ma)
   {
      $self->{macros}->{$key} = $ma{$key};
   }
   return 1;
}

#####################################################################

sub add_elements
{
   my $self = shift;
   my %el = @_;

   my $key;
   foreach $key (%el)
   {
      unless(exists $self->{elements}->{$key})
      {
         $self->{elements}->{$key} = $el{$key};
      }
   }
   return 1;
}

####################################################################

sub replace_elements
{
   my $self = shift;
   my %el = @_;

   my $key;
   foreach $key (%el)
   {
      $self->{elements}->{$key} = $el{$key};
   }
   return 1;
}

#####################################################################

sub all_macros
{
   my $self = shift;
   return %{$self->{macros}};
}

#####################################################################

sub all_elements
{
   my $self = shift;
   return %{$self->{elements}};
}

#####################################################################

### End of game
1;
