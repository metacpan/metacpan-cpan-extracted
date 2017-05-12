package BioGraph::Clustering;

# Auteur : Tristan Colombo
# Librairie de traitement des graphes
# Création : le 18/06/2004
# Modifications : le 28/06/2004

$VERSION="1.0.0";

=pod

=head1 NAME

BioGraph::Clustering

=head1 SYNOPSIS

use BioGraph::Clustering;

=head1 DESCRIPTION

Package for manipulate graphs represented as well as adjacent matrix or adjacent list. Library for clustering graphs.


=head1 AVAILABLE FUNCTIONS

This is the list of the differents functions implemented in this library.

=cut

use BioGraph::Compute;
use BioGraph::Operation;

sub ZD_kernel
#####################################################
# Tristan Colombo (adaptation du C de A. Guenoche)  #
# Création : le 28/06/2004                          #
# Modifications : -                                 #
#####################################################
# Calcul des noyaux du graphe                       #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Référence vers la table des densités     #
#          Graphe                                   #
# Output : Nombre de sommets                        #
#####################################################
{

=pod

=over 4

=item  B<ZD_kernel>

Compute the kernels of the graph

=over 6

=item 

SYNOPSIS	%K=ZD_kernel(representation, ref_density, graph)

=item 

PARAMETERS

=over 8

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<ref_density>

reference to the table of densities

=item I<graph>

the hash table of the graph

=back

=item 

OUTPUT	The kernels (view as clusters) of the graph computed according to the definition of T. Colombo, A. Guenoche and Y. Quentin, "Research of density areas in a graph - Application to orthologous genes", Proceedings of the Fourth International Conference on Knowledge Discovery and Discrete Mathematics (2003).

=back

=back

=cut

	my $type=shift;
	my $ref_density=shift;
	my %Ttmp=@_;
	my ($k, $k2, %Clust, @elts, %grpe, @succ);
	my ($n, $liste)=(1, " ");
	my %T=BioGraph::Operation::symetric($type, %Ttmp);
	my %D=BioGraph::Compute::degree($type, %T);
	my $DeMoy=BioGraph::Compute::mean(%$ref_density);
    	foreach $k (keys %$ref_density)
	{
		if ($$ref_density{$k} >= $DeMoy)
			{ $liste.="$k "; }
	}
	@elts=split(/\ /, $liste);
	# On détermine les clusters
	foreach $k (@elts)
	{
		next if ($k eq "");
		if ($type==1)
			{ @succ=keys %{$T{$k}}; }
		else
			{ @succ=split(/\ /, $T{$k}); }
		foreach $k2 (@succ)
		{
			next if ($k2 eq "");
			if (defined $grpe{$k2})
			{
				$grpe{$k}=$grpe{$k2};
				last;
			}
		}
		if (not defined $grpe{$k})
			{ $grpe{$k}=$n++; }
	}
	# Pour chaque sommet de degré 1 lié à un noyau on l'agglomère
	foreach $k (keys %D)
	{
		next if ($D{$k} != 1);
		if ($type==1)
			{ $k2=keys %{$T{$k}}; }
		else
		{ 
			$k2=$T{$k}; 
			$k2=~s/\ //g;
		}
		if ($liste=~/\ $k2\ /)
		{
			$grpe{$k}=$grpe{$k2};
			$liste.="$k ";
		}
	}
	# Résultat final
	foreach $k (keys %grpe)
	{
		if (not defined $Clust{$grpe{$k}})
			{ $Clust{$grpe{$k}}=" $k "; }
		else
			{ $Clust{$grpe{$k}}.="$k "; }
	}
	return(%Clust);
} # fin de 'kernel'

sub ZD_extension
#####################################################
# Tristan Colombo                                   #
# Création : le 28/06/2004                          #
# Modifications : le 06/07/2004                     #
#####################################################
# Nombre de sommets d'un graphe                     #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Graphe                                   #
# Output : Nombre de sommets                        #
#####################################################
{

=pod

=over 4

=item  B<ZD_extension>

Compute the clusters of the graph

=over 6

=item 

SYNOPSIS	%C=ZD_extension(representation, ref_density, ref_kernel, graph)

=item 

PARAMETERS

=over 8

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<ref_density>

reference to the table of densities

=item I<ref_kernel>

reference to the hash table of kernels

=item I<graph>

the hash table of the graph

=back

=item 

OUTPUT	The clusters of the graph computed according to the definition of T. Colombo, A. Guenoche and Y. Quentin, "Research of density areas in a graph - Application to orthologous genes", Proceedings of the Fourth International Conference on Knowledge Discovery and Discrete Mathematics (2003).

=back

=back

=cut

	my $type=shift;
	my $ref_density=shift;
	my $ref_noyaux=shift;
	my %Ttmp=@_;
	my %T=BioGraph::Operation::symetric($type, %Ttmp);
	my %Clust=%$ref_noyaux;
	my ($k, $k2, $k3, %connect, @succ, @succ2, %grpe, $max, $id_max);
	my ($liste, $garbage)=("", 0);
	foreach $k (keys %$ref_noyaux)
	{ 	
		$liste.=$$ref_noyaux{$k}; 
		@succ=split(/\ /, $$ref_noyaux{$k});
		foreach $k2 (@succ)
		{
			next if ($k2 eq "");
			$grpe{$k2}=$k;
		}
	}
	foreach $k (sort { $$ref_density{$b} <=> $$ref_density{$a} } keys %T)
	{
		next if ($liste =~ /\ $k\ /);
		%connect=();	
		if ($type==1)
			{ @succ=keys %{$T{$k}}; }
		else
			{ @succ=split(/\ /, $T{$k}); }
		foreach $k2 (@succ)
		{
			if (defined $grpe{$k2})
			{
				if (defined $connect{$grpe{$k2}})
					{ $connect{$grpe{$k2}}++; }
				else
					{ $connect{$grpe{$k2}}=1; }
			}
		}
		$max=0;
		$id_max=0;
		foreach $k2 (keys %connect)
		{
			if ($connect{$k2}>$max)
			{
				$max=$connect{$k2};
				$id_max=$k2;
			}
		}
		if ($id_max != 0)
		{ 	
			$Clust{$id_max}.="$k "; 
			$grpe{$k}=$id_max;
		}
		else
		{ 
			$Clust{"Garbage"}.="$k "; 
			$garbage++;
		}
	}
	# Traitement des éléments restant
	while ($garbage)
	{
		@succ=split(/\ /, $Clust{"Garbage"});
		$Clust{"Garbage"}=" ";
		foreach $k2 (@succ)
		{
			next if ($k2 eq "");
			# On traite $k2 ici et on l'accroche a sa famille ($garbage--) sinon garbage
			%connect=();	
			if ($type==1)
				{ @succ2=keys %{$T{$k2}}; }
			else
				{ @succ2=split(/\ /, $T{$k2}); }
			foreach $k3 (@succ2)
			{
				if (defined $grpe{$k3})
				{
					if (defined $connect{$grpe{$k3}})
						{ $connect{$grpe{$k3}}++; }
					else
						{ $connect{$grpe{$k3}}=1; }
				}
			}
			$max=0;
			$id_max=0;
			foreach $k3 (keys %connect)
			{
				if ($connect{$k3}>$max)
				{
					$max=$connect{$k3};
					$id_max=$k3;
				}
			}
			if ($id_max != 0)
				{ $Clust{$id_max}.="$k2 ";}
			$garbage--;
		}
	}
	delete($Clust{"Garbage"});
	return(%Clust);
} # fin de 'ZD_extension'

=pod

=head1 AUTHOR AND COPYRIGHT

  BioGraph::FileAccess is Copyright (C) 2004, Tristan Colombo
                                     CNRS - LCB, 31 chemin Joseph Aiguier
                                     13009 Marseille
                                     France

                                     Email: tristan.colombo@ibsm.cnrs-mrs.fr

  All rights reserved.

  You may distribute this package under the terms of the GNU
  General Public License.

=cut

1;
