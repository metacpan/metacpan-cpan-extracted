package Angle::Omega;
use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(omega);
=head1 NAME

Angle::Omega -A perl module to calculate omega angles for the input Protein Data Bank (PDB) file. 

=head1 VERSION

Version 1.00 

=cut

our $VERSION = '1.00';


=head1 SYNOPSIS

    use Angle::Omega;
    my @foo = omega("input_filename");
    foreach(@foo) { print;}

=head1 SUBROUTINES/METHODS

=head2 omega

=cut

sub omega {
my $input=$_[0];
open(ID,"$input")or die "Could not open $input: $!";
my @N;my @CA;my @C;
while(<ID>)
{
if($_=~/^ATOM/)
{
my $c=substr($_,13,4);$c=~s/\s//g;
	if ($c eq 'N')	{ push(@N,$_);}
	if ($c eq 'CA')	{ push(@CA,$_);}
	if ($c eq 'C')	{ push(@C,$_);}
}
if ($_=~/^ENDMDL/) {last;}
}
my $k=0;
print "###RESIDUE_NAME	CHAIN	OMEGA (in degrees)###\n";
foreach(@N)
{
my $d4=substr($N[$k-1],17,3);$d4=~s/\s//g;
my $ud =find_omega(substr($CA[$k-1],30,8),substr($CA[$k-1],38,8),substr($CA[$k-1],46,8),substr($C[$k-1],30,8),substr($C[$k-1],38,8),substr($C[$k-1],46,8),substr($N[$k],30,8),substr($N[$k],38,8),substr($N[$k],46,8),substr($CA[$k],30,8),substr($CA[$k],38,8),substr($CA[$k],46,8));
$ud=sprintf("%0.1f", $ud);
if(substr($N[$k-1],21,1) ne substr($N[$k],21,1)) {$ud=360.0;}
if ($k>0) {print "$d4\t".substr($N[$k-1],21,1)."\t$ud\n";}
if ($k == $#N) { print substr($N[$#N],17,3)."\t".substr($N[$#N],21,1)."\t360.0\n";}
$k++;
}

 sub find_omega
 {
 use Math::Trig;
 my $answer=10000;
 my  $x1 = $_[3]-$_[0];
 my  $y1 = $_[4]-$_[1];
 my  $z1 = $_[5]-$_[2];
 my  $x2 = $_[3]-$_[6];
 my  $y2 = $_[4]-$_[7];
 my  $z2 = $_[5]-$_[8];
 my  $x3 = $_[6]-$_[9];
 my  $y3 = $_[7]-$_[10];
 my  $z3 = $_[8]-$_[11];

 my  $axbbxc = ((($y1*$z2-$z1*$y2)*($y2*$z3-$z2*$y3))+
          (($x2*$z1-$x1*$z2)*($x3*$z2-$x2*$z3))+
          (($x1*$y2-$x2*$y1)*($x2*$y3-$x3*$y2)));
 my  $vaxb = ((($y1*$z2-$z1*$y2)*($y1*$z2-$z1*$y2))+
        (($x2*$z1-$x1*$z2)*($x2*$z1-$x1*$z2))+
        (($x1*$y2-$x2*$y1)*($x1*$y2-$x2*$y1)));
 my  $vbxc = ((($y2*$z3-$z2*$y3)*($y2*$z3-$z2*$y3))+
        (($x3*$z2-$x2*$z3)*($x3*$z2-$x2*$z3))+
        (($x2*$y3-$x3*$y2)*($x2*$y3-$x3*$y2)));
 $answer = ($axbbxc/sqrt($vaxb*$vbxc));
 $answer = (180*(acos($answer)/3.14));
 my $sign = (($x1*($y2*$z3-$y3*$z2))-($y1*($x2*$z3-$x3*$z2))+($z1*($x2*$y3-$x3*$y2)));
 if($sign>=0)
 {
  if ($answer>0){ $answer=$answer};
  if ($answer<0) {$answer=-$answer};
 }
 if($sign<0)
 {
  if ($answer>=0) {$answer=-$answer};
  if ($answer<0) {$answer=$answer};
 }
if($answer>0){
$answer=180-$answer;
$answer*=(-1);}
else{$answer=180+$answer;}
if($answer<0){$answer*=(-1);}
else{$answer*=(-1);}
 return($answer);
}

}

=head1 DESCRIPTION

	Omega angle is one among the dihedral angles of proteins, which controls the Calpha - Calpha distance. The Omega angle tends to be planar due to delocalization of the carbonyl pi electrons and the nitrogen lone pair. Omega is notable for the cis/trans conformations.

=head1 AUTHOR

Shankar M, C<< <msinfopl at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<msinfopl at gmail.com>

=head1 ACKNOWLEDGEMENTS

Saravanan S E and Sabarinathan Radhakrishnan, for all their valuable thoughts and care. 

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Shankar M.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

# End of Angle::Omega
