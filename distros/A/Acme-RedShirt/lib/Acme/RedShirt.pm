
package Acme::RedShirt;

our @ISA = qw(Exporter);
our $VERSION = 0.1;

my %HOW = (
	phaser       => 'Got hit by a phaser. ', 
	mutant_plant => 'I knew those plants looked funny. ', 
	spear        => 'The natives got him. ', 
	lightning    => 'Must be a god-like alien around. ', 
	insect_bite  => "Insects? Sensors didn't pick up any insects. ", 
	transporter  => 'Scotty, you need to fix the transporter. ', 
);

sub import 
{
	my $pkg = shift;
	my $way = shift || '';

	if($way eq 'random') {
		my @keys = keys %HOW;
		$way = $keys[int rand($#keys)];
	}

	my $text = $HOW{$way} . "He's dead, Jim.";

	print STDERR $text, "\n";
	exit(0);
}

1;

__END__

=head1 NAME 

  Acme::RedShirt -- Write programs that die upon beaming down

=head1 SYNOPSIS 

  use Acme::RedShirt;
  . . . # Program dies like a Red Shirt. Won't be executed. 
  
  __OUTPUT__
  He's dead, Jim.

  # Specify a method of death
  use Acme::RedShirt 'phaser';
  . . . 
  
  __OUTPUT__
  He got hit by a phaser.  He's dead, Jim.

=head2 DESCRIPTION

Every good captain is surrounded by a bunch of extras wearing red shirts, whose 
job it is to put themselves in the line of fire so the regulars can get on with 
the show. Now, this level of security is brought to Perl.

It is possible to use this module to specify a method of death for your expendable 
program.  Currently defined methods are: 

  phaser 
  mutant_plant
  spear
  lightning
  insect_bite
  transporter

=head1 BUGS 

Actually doesn't die(), but instead just exit(0). die() causes an extra error message 
to be printed to the screen, which would interfear with the point of the module.

=head1 COPYRIGHT 

  Copyright (C) 2003 Timm Murray

  This module is free software; you can redistribute it and/or modify it
  under the terms of either:

  a) the GNU General Public License as published by the Free Software
  Foundation; either version 1, or (at your option) any later version,
  
  or

  b) the "Artistic License" which comes with this module.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
  the GNU General Public License or the Artistic License for more details.

  You should have received a copy of the Artistic License with this
  module, in the file ARTISTIC.  If not, I'll be glad to provide one.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
  USA


=cut

