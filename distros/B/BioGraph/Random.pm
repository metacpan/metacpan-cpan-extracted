package BioGraph::Random;

# Auteur : Tristan Colombo
# Librairie de traitement des graphes
# Création : le 18/06/2004
# Modifications : le 16/07/2004 

use BioGraph::Compute;

$VERSION="1.0.1";

=pod

=head1 NAME

BioGraph::Random

=head1 SYNOPSIS

use Biograph::Random;

=head1 DESCRIPTION

Package for manipulate graphs represented as well as adjacent matrix or adjacent list. Library for generating random graphs.


=head1 AVAILABLE FUNCTIONS

This is the list of the differents functions implemented in this library.

=cut

sub generate
#####################################################
# Tristan Colombo                                   #
# Création : le 19/06/2004                          #
# Modifications : le 16/07/2004                     #
#####################################################
# Génère un graphe aléatoire                        #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Nombre de sommets                        #
#          Nombre de classes                        #
#          Liste des densités internes à chaque     #
#          classe                                   #
#          Densité externe                          #
# Output : Le graphe généré                         #
#####################################################
{

=pod

=over 4

=item B<generate>

=item

SYNOPSIS	%T=generate(representation, nb_vertices, nb_classes, internal_density_list, external_density)

=item

PARAMETERS

=over 6

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<nb_vertices>

number of vertices of the graph

=item I<nb_classes>

number of classes in the graph

=item I<internal_density_list>

list of internal density of each class separate by a blank character

=item I<external_density>

external density

=back

=item

OUTPUT	The graph randomly generated

=back

=cut

	my $type=shift;
	my $nb_som=shift;
	my $nb_class=shift;
	my $list_di=shift;
	my $de=shift;
	my ($n, $c, $k, $k2, $r, $i, $j, %T, @liste_som, @liste_som2, @tmp, @tmp2, $traite);
	my @di=split(/\ /, $list_di);
	# On détermine d'abord les classes initiales
	for ($k=1; $k <= $nb_som; $k++)
	{ 
		$r=int(rand($nb_class))+1;
		if (not defined $C[$r])
			{ $C[$r]=" $k "; }
		else
			{ $C[$r].= "$k "; }
	}
	#for ($r=1; $r <= $nb_class; $r++)
	#	{ print "Classe $r :$C[$r]\n"; }
	# On complète le graphe avec les arêtes internes pour chaque classe
	for ($r=1; $r <= $nb_class; $r++)
	{
		@liste_som=split(/\ /, $C[$r]);
		if ($#liste_som <= 1)
			{ die "BioGraph::Random::genere_Tristan : not enough vertices in cluster $r\n"; }
		$n=($#liste_som*($#liste_som-1))/2;
		$c=0;
		while (($c/$n) < $di[$r-1])
		{
			#$lm=BioGraph::Compute::internal_density_cluster($type, $C[$r], %T);
			#print "$lm < ".$di[$r-1]." ??\n";
			$i=int(rand($#liste_som));
			do
				{ $j=int(rand($#liste_som)); }
			while ($i == $j);
			next if (($liste_som[$i] eq "") || ($liste_som[$j] eq ""));
			if ($type == 1)
			{
				if ((not defined $T{$liste_som[$i]}{$liste_som[$j]}) && (not defined $T{$liste_som[$j]}{$liste_som[$i]}))
				{
					$T{$liste_som[$i]}{$liste_som[$j]}=1;
					$T{$liste_som[$j]}{$liste_som[$i]}=1;
					$c++;
				}
			}
			else
			{
				next if ((defined $T{$liste_som[$i]}) && ($T{$liste_som[$i]} =~ /\ $liste_som[$j]\ /));
				next if ((defined $T{$liste_som[$j]}) && ($T{$liste_som[$j]} =~ /\ $liste_som[$i]\ /));
				if (defined $T{$liste_som[$i]})
					{ $T{$liste_som[$i]}.="$liste_som[$j] "; }
				else
					{ $T{$liste_som[$i]}=" $liste_som[$j] "; }
				if (defined $T{$liste_som[$j]})
					{ $T{$liste_som[$j]}.="$liste_som[$i] "; }
				else
					{ $T{$liste_som[$j]}=" $liste_som[$i] "; }
			}
			# print "arete $liste_som[$i]-$liste_som[$j]\n"; 
		}
	}
	# On complète le graphe avec les arêtes externes
	$n=0;
	$c=0;
	for ($k=1; $k<$nb_class; $k++)
	{ 
		@tmp=split(/\ /, $C[$k]); 
		for ($k2=2; $k2<=$nb_class; $k2++)
		{ 
			@tmp2=split(/\ /, $C[$k2]); 
			$n+=($#tmp*$#tmp2);
			$traite=" ";
			foreach $k (@tmp)
			{
				next if ($k eq "");
				foreach $k2 (@tmp2)
				{
					next if (($k2 eq "") || ($traite =~ /\ $k-$k2\ /) || ($traite =~ /\ $k2-$k\ /));
					$traite.="$k-$k2 ";
					if ($type == 1)
					{
						if ((defined $T{$k}{$k2}) || (defined $T{$k}{$k2}))
							{ $c++; }
					}
					else
					{
						if (((defined $T{$k}) && ($T{$k}=~/\ $k2\ /)) || ((defined $T{$k2}) && ($T{$k2}=~/\ $k\ /)))
							{ $c++; }
					}
				}
			}

		}
	}
	while (($c/$n) < $de)
	{
		$i=int(rand($nb_class))+1;
		do
			{ $j=int(rand($nb_class))+1; }
		while ($i == $j);
		next if (($liste_som[$i] eq "") || ($liste_som[$j] eq ""));
		@liste_som=split(/\ /, $C[$i]);
		@liste_som2=split(/\ /, $C[$j]);
		$i=int(rand($#liste_som));
		$j=int(rand($#liste_som2)); 
		next if (($liste_som[$i] eq "") || ($liste_som2[$j] eq ""));
		if ($type == 1)
		{
			if ((not defined $T{$liste_som[$i]}{$liste_som2[$j]}) && (not defined $T{$liste_som2[$j]}{$liste_som[$i]}))
			{
				$T{$liste_som[$i]}{$liste_som2[$j]}=1;
				$T{$liste_som2[$j]}{$liste_som[$i]}=1;
				$c++;
			}
		}
		else
		{
			next if ((defined $T{$liste_som[$i]}) && ($T{$liste_som[$i]} =~ /\ $liste_som2[$j]\ /));
			next if ((defined $T{$liste_som2[$j]}) && ($T{$liste_som2[$j]} =~ /\ $liste_som[$i]\ /));
			if (defined $T{$liste_som[$i]})
				{ $T{$liste_som[$i]}.="$liste_som2[$j] "; }
			else
				{ $T{$liste_som[$i]}=" $liste_som2[$j] "; }
			if (defined $T{$liste_som2[$j]})
				{ $T{$liste_som2[$j]}.="$liste_som[$i] "; }
			else
				{ $T{$liste_som2[$j]}=" $liste_som[$i] "; }
			$c++;
		}
	}
	return(%T);
}

=pod

=head1 AUTHOR AND COPYRIGHT

  Graph::Calculs is Copyright (C) 2004, Tristan Colombo
                                     CNRS - LCB, 31 chemin Joseph Aiguier
                                     13009 Marseille
                                     France

                                     Email: tristan.colombo@ibsm.cnrs-mrs.fr

  All rights reserved.

  You may distribute this package under the terms of either the GNU
  General Public License or the Artistic License, as specified in the
  Perl README file.

=cut

1;
