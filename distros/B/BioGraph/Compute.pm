package BioGraph::Compute;

# Auteur : Tristan Colombo
# Librairie de traitement des graphes
# Création : le 17/06/2004
# Modifications : le 16/07/2004

use BioGraph::Operation;

$VERSION="1.0.1";

=pod

=head1 NAME

BioGraph::Compute

=head1 SYNOPSIS

use Biograph::Compute;

=head1 DESCRIPTION

Package for manipulate graphs represented as well as adjacent matrix or adjacent list. The common format of representation adopted for the graphs files is : number_of_edges on the first line, and then vertice_i \t vertice_j on the other one.


=head1 AVAILABLE FUNCTIONS

This is the list of the differents functions implemented in this library.

=cut

sub vertices_nb
#####################################################
# Tristan Colombo                                   #
# Création : le 17/06/2004                          #
# Modifications : -                                 #
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

=item  B<vertices_nb>

Compute the number of vertices in a graph

=over 6

=item 

SYNOPSIS	$N=vertices_nb(representation, graph)

=item 

PARAMETERS

=over 8

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<graph>

the hash table of the graph

=back

=item 

OUTPUT	The number of vertices in the graph

=back

=back

=cut

	my $type=shift;
	my %T=@_;
	my ($N, $traite)=(0, " ");
	my ($k, $k2);
	if ($type == 1)
	{
		foreach $k (keys %T)
		{ 
			if ($traite !~ /\ $k\ /)
			{
				$traite.="$k ";
				$N++;
			}
			foreach $k2 (keys %{$T{$k}})
			{
				if ($traite !~ /\ $k2\ /)
				{
					$traite.="$k2 ";
					$N++;
				}
			}

		}
	}
	else
	{
		foreach $k (keys %T)
		{ 
			if ($traite !~ /\ $k\ /)
			{
				$traite.="$k ";
				$N++;
			}
			@s_k=split(/\ /, $T{$k});
			foreach $k2 (@s_k)
			{
				next if ($k2 eq "");
				if ($traite !~ /\ $k2\ /)
				{
					$traite.="$k2 ";
					$N++;
				}

			}
		}
	}
	return($N);
} # fin de 'vertices_nb'

sub edges_nb
#####################################################
# Tristan Colombo                                   #
# Création : le 17/06/2004                          #
# Modifications : -                                 #
#####################################################
# Nombre d'aretes d'un graphe                       #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Graphe                                   #
# Output : Nombre d'aretes                          #
#####################################################
{

=pod

=over 4

=item B<edges_nb>

Compute the number of edges in a graph

=item

SYNOPSIS	$N=edges_nb(representation, graph)

=item

PARAMETERS

=over 6

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	The number of edges in the graph

=back

=cut

	my $type=shift;
	my %T=@_;
	my ($N, $traite)=(0, " ");
	my ($k, $k2, @s_k);
	if ($type == 1)
	{
		foreach $k (keys %T)
		{ 
			foreach $k2 (keys %{$T{$k}})
			{
				if ($traite !~ /\ $k-$k2\ /)
				{
					$traite.="$k-$k2 ";
					$N++;
				}
			}
		}
	}
	else
	{
		foreach $k (keys %T)
		{ 
			@s_k=split(/\ /, $T{$k});
			foreach $k2 (@s_k)
			{
				next if ($k2 eq "");
				if ($traite !~ /\ $k-$k2\ /)
				{
					$traite.="$k-$k2 ";
					$N++;
				}
			}
		}
	}
	return($N);
} # fin de 'edges_nb'

sub mean
#####################################################
# Tristan Colombo                                   #
# Création : le 28/06/2004                          #
# Modifications : -                                 #
#####################################################
# Moyenne d'une table                               #
# Input  : Table de hachage                         #
# Output : Moyenne                                  #
#####################################################
{

=pod

=over 4

=item B<mean>

Compute the mean number of a table excluding the null values

=item

SYNOPSIS	$M=mean(table)

=item

PARAMETERS

=over 6

=item I<table>

the hash table

=back

=item

OUTPUT	The mean number of the table

=back

=cut

	my %T=@_;
	my $k;
	my ($moy, $n)=(0, 0);
	foreach $k (keys %T)
	{ 
		$moy+=$T{$k}; 
		if ($T{$k} != 0) 
			{ $n++ };
	}
	return($moy/$n);
} # fin de 'mean'

sub global_density
#####################################################
# Tristan Colombo                                   #
# Création : le 18/06/2004                          #
# Modifications : -                                 #
#####################################################
# Calcul de la densité d'un graphe                  #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Graphe                                   #
# Output : Densité du graphe                        #
#####################################################
{

=pod

=over 4

=item B<global_density>

Computing of the global density of a graph

=item

SYNOPSIS	$d=densite(representation, graph)

=item

PARAMETERS

=over 6

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	The density of the graph. (Usefull with the graph with multiple connected components)

=back

=cut

	my $type=shift;
	my %T=@_;
	my $som=vertices_nb($type, %T);
	my $aretes=edges_nb($type, %T);
	return($aretes/(($som*($som-1))/2));
} # fin de 'global_density'

sub degree
#####################################################
# Tristan Colombo                                   #
# Création : le 18/06/2004                          #
# Modifications : -                                 #
#####################################################
# Calcul du degré de chaque sommet d'un graphe      #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Graphe                                   #
# Output : Liste des degrés par sommet              #
#####################################################
{

=pod

=over 4

=item B<degree>

Compute the degree of each vertex

=item

SYNOPSIS	%D=degree(representation, graph)

=item

PARAMETERS

=over 6

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	The hash table of each vertice's degree

=back

=cut

	my $type=shift;
	my %T=@_;
	my ($k, $k2, @succ, %degre);
	my $traite=" ";
	foreach $k (keys %T)
	{
		if ($type == 1)
			{ @succ=keys %{$T{$k}}; }
		else
			{ @succ=split(/\ /, $T{$k}); }
		foreach $k2 (@succ)
		{
			next if ($k2 eq "");
			if (($traite !~ /\ $k-$k2/) && ($traite !~ /\ $k2-$k\ /))
			{
				if (defined $degre{$k})
					{ $degre{$k}++; }
				else
					{ $degre{$k}=1; }
				if (defined $degre{$k2})
					{ $degre{$k2}++; }
				else
					{ $degre{$k2}=1; }
				$traite.="$k-$k2 ";
			}
		}
	}
	return(%degre);
} # fin de 'degree'

sub cluster_coeff
#####################################################
# Tristan Colombo                                   #
# Création : le 18/06/2004                          #
# Modifications : le 16/07/2004                     #
#####################################################
# Calcul du coefficient de clustering d'un graphe   #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Graphe                                   #
# Output : Liste des degrés par sommet              #
#####################################################
{

=pod

=over 4

=item B<cluster_coeff>

Compute the cluster coefficient of a graph

=item

SYNOPSIS	$C=cluster_coeff(representation, graph)

=item

PARAMETERS

=over 6

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	Computing of the clustering coefficient defined by Watts and Strogatz ("Collective dynamics of 'small-world' networks", Nature, 393, 440-442 (1998)). Taking two neigbours vertices, this is the probability that a third vertex exists which is neigbour to the two others. C=(Number of neighbours vertices with a third neighbour vertex to the two others)/(Number of neighbour vertices = number of edges)

=back

=cut

	my $type=shift;
	my %T=@_;
	my ($k, $k2, $k3, @succ, %degre);
	my $traite=" ";
	my $C=0;
	my $N=edges_nb($type, %T);
	%T=BioGraph::Operation::symetric($type, %T);
	foreach $k (keys %T)
	{
		if ($type == 1)
			{ @succ=keys %{$T{$k}}; }
		else
			{ @succ=split(/\ /, $T{$k}); }
		foreach $k2 (@succ)
		{
			next if ($k2 eq "");
			if (($traite !~ /\ $k-$k2/) && ($traite !~ /\ $k2-$k\ /))
			{
				foreach $k3 (@succ)
				{
					if ($type == 1)
					{
						if ((defined $T{$k2}{$k3}) || (defined $T{$k3}{$k2}))
						{ 
							$C++; 
							last;
						}
					}
					else
					{
						if (((defined $T{$k2}) && ($T{$k2} =~ /\ $k3\ /)) || ((defined $T{$k3}) && ($T{$k3} =~ /\ $k2\ /)))
						{ 
							$C++; 
							last;
						}
					}
				}
				$traite .= "$k-$k2 "; 
			}
		}
	}
	return($C/$N);
} # fin de 'cluster_coeff'

sub shortest_paths
#####################################################
# Tristan Colombo                                   #
# Création : le 18/06/2004                          #
# Modifications : -                                 #
#####################################################
# Calcul des plus court chemin depuis un sommet     #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Sommet de départ                         #
#          Graphe                                   #
# Output : Liste des chemins                        #
#####################################################
{

=pod

=over 4

=item B<shortest_paths>

Compute the sortest paths in a graph from a given starting vertex

=item

SYNOPSIS	%PCC=shortest_paths(representation, start, graph)

=item

PARAMETERS

=over 6

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<start>

start vertex

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	Computing of the list of the shortest paths from a start vertex in a graph using the Dijkstra's algorithm.

=back

=cut

	sub choix_element
	# Pour une liste des sommets déja traités et une table des distances,
	# renvoi le sommet non traité le plus proche
	{
		my $traite=shift;
		my %Dist=@_;
		my ($k, $candidat);
		my $min=32767;
		foreach $k (keys %Dist)
		{
			next if ($traite =~ /\ $k\ /);
			if ($Dist{$k} < $min)
			{
				$min=$Dist{$k};
				$candidat=$k;
			}
		}
		if ($min == 32767)
			{ $candidat="FIN"; }
		return($candidat);
	} # fin de 'choix_element'

	sub val
	# Fonction de valuation : renvoi 1 si les deux sommets passés en arguments son voisins,
	# et 32767 sinon
	{
		my $s1=shift;
		my $s2=shift;
		my $type=shift;
		my %T=@_;
		if ($type == 1)
		{
			if (defined $T{$s1}{$s2})
				{ return(1); }
			else
				{ return(32767); }
		}
		else
		{
			if ($T{$s1} =~ /\ $s2\ /)
				{ return(1); }
			else
				{ return(32767); }
		}
	} # fin de 'val'

	my $type=shift;
	my $som=shift;
	my %Ttmp=@_;
	my ($i, $k, $k2, $k3, @succ, %D, %P);
	my %T=BioGraph::Operation::symetric($type, %Ttmp);
	my $traite=" $som ";
	my $N=vertices_nb($type, %T);
	if (not defined $T{$som})
		{ die("Graph::Calculs::plus_court_chemin : le sommet $som n'existe pas\n"); }
	$D{$som}=0;
	$P{$som}="-";
	if ($type == 1)
		{ @succ=keys %{$T{$som}}; }
	else
		{ @succ=split(/\ /, $T{$som}); }
	foreach $k2 (@succ)
	{
		next if ($k2 eq "");
		$D{$k2}=1; 
		$P{$k2}=$som;
	}
	foreach $k (keys %T)
	{
		if (not defined $D{$k})
		{ 
			$D{$k}=32767; 
			$P{$k}="-";
		}
	}
	for ($i=2; $i<$N; $i++)
	{
		$k=choix_element($traite, %D);
		last if ($k eq "FIN");
		$traite.="$k ";
		foreach $k2 (keys %D)
		{
			next if ($traite =~ /\ $k2\ /);
			if ($D{$k2} > ($D{$k}+1))
			{
				$D{$k2}=$D{$k}+val($k, $k2, $type, %T);
				$P{$k2}=$k;
			}
		}
	}
	return(%P);
} # fin de 'shortest_paths'

sub triangle_nb
#####################################################
# Tristan Colombo                                   #
# Création : le 24/06/2004                          #
# Modifications : -                                 #
#####################################################
# Calcul du nb de triangles dans lesquels l'arete   #
# donnée intervient                                 #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Sommet de départ                         #
#          Sommet d'arrivée                         #
#          Graphe                                   #
# Output : Nb de triangle                           #
#####################################################
{

=pod

=over 4

=item B<triangle_nb>

Compute the number of triangles in which a given edge is implicated

=item

SYNOPSIS	%D=triangle_nb(representation, start_vertex, end_vertex, graph)

=item

PARAMETERS

=over 6

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<start_vertex>

first vertex of the edge

=item I<end_vertex>

second vertex of the edge

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	The number of triangles in wich the given edge is implicated.

=back

=cut

	my $type=shift;
	my $start=shift;
	my $end=shift;
	my %T=@_;
	my ($k, @succ);
	my $nb_tri=0;
	%T=BioGraph::Operation::symetric($type, %T);
	if (not defined %{$T{$start}})
		{ die("BioGraph::Compute::triangle_nb : the vertex $star is not in the graph\n"); }
	if (not defined %{$T{$end}})
		{ die("BioGraph::Compute::triangle_nb : the vertex $end is not in the graph\n"); }
	if ($type == 1)
	{
		foreach $k (keys %{$T{$start}})
		{
			next if ($k eq $end);
			if (defined $T{$k}{$end})
				{ $nb_tri++; }
		}
	}
	else
	{
		@succ=split(/\ /, $T{$start});
		foreach $k (@succ)
		{
			next if (($k eq "") || ($k eq $end));
			if ((defined $T{$k}) && ($T{$k} =~ /\ $end\ /))
				{ $nb_tri++; }
		}
	}
	return($nb_tri);
} # fin de 'triangle_nb'

sub distance
#####################################################
# Tristan Colombo                                   #
# Création : le 23/06/2004                          #
# Modifications : -                                 #
#####################################################
# Calcul des distances                              #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Type de distance : Betweeness,           #
#          Radicchi, Dice                           #
#          Graphe                                   #
# Output : Liste des distances                      #
#####################################################
{

=pod

=over 4

=item B<distance>

Compute a specific distance between vertices of the graph (distances are Dice, Radicchi, ...)

=item

SYNOPSIS	%D=distance(representation, distance, graph)

=item

PARAMETERS

=over 6

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<distance>

a type of distance in :

=over 8

=item I<Betweeness>

the betweeness of an edge is the number of shortest paths which going through this edge ; a definition is given by Girvan and Newman in "Community structure in social and biological networks", Proc. Natl. Acad. Sci. USA, 99, 7821-7826 (2002)

=item I<Dice>

=item I<Radicchi>

for an edge (i,j), the distance d(i,j) is (nb of triangles in which (i,j) is implicated + 1)/min(degree(i)-1, degree(j)-1). see F. Radicchi, C. Castellano, F. Cecconi, V. Loreto and D. Parisi, "Defining and identifying communities in networks", preprint condmat/0309263 (2003)

=back

All these distances are conform to the specification given previsiously

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	The table of the distance choosen. Note that the value '32767' indicate infinite distance.

=back

=cut

	my $type=shift;
	my $dist=shift;
	my %T=@_;
	my ($traite, $liste_fin, $choice)=(" ", " ", "'Betweeness', 'Dice', or 'Radicchi'");
	my (%Dist, $tri, $min, %PCC, $l, $p);
	if (($dist eq "Radicchi") || ($dist eq "Dice"))
	{
		%Deg=degree($type, %T);
		foreach $k (keys %T)
		{
			if ($type == 1)
				{ @succ=keys %{$T{$k}}; }
			else
				{ @succ=split(/\ /, $T{$k}); }
			foreach $k2 (@succ)
			{
				next if (($k2 eq "") || ($traite =~ /\ $k-$k2\ /) || ($traite =~ /\ $k2-$k\ /));
				$traite.="$k-$k2 ";
				if ($Deg{$k}<$Deg{$k2})
					{ $min=$Deg{$k}; }
				else
					{ $min=$Deg{$k2}; }
				$tri=triangle_nb($type, $k, $k2, %T);
				if (($min==1) && ($dist eq "Radicchi"))
				{
					$Dist{$k}{$k2}=32767;
					$Dist{$k2}{$k}=32767;
				}
				else
				{
					if ($dist eq "Radicchi")
					{
						$Dist{$k}{$k2}=($tri+1)/($min-1);
						$Dist{$k2}{$k}=$Dist{$k}{$k2};
					}
					else
					{
							$Dist{$k}{$k2}=1-((2*($tri+2))/($Deg{$k}+$Deg{$k2}+2));
							$Dist{$k2}{$k}=$Dist{$k}{$k2};
					}
				}
				#print "Dist($k,$k2)=($tri+1)/($min-1)=$Dist{$k}{$k2}\n";
			}
		}
	}
	elsif ($dist eq "Betweeness")
	{
		foreach $k (keys %T)
		{
			if ($type == 1)
				{ @succ=keys %{$T{$k}}; }
			else
				{ @succ=split(/\ /, $T{$k}); }
			foreach $k2 (@succ)
			{
				next if (($k2 eq "") || ($traite =~ /\ $k-$k2\ /) || ($traite =~ /\ $k2-$k\ /));
				$traite.="$k-$k2 ";
				%PCC=shortest_paths($type, $k, %T);
				foreach $l (sort keys %PCC)
				{ 	
					print "$l : $PCC{$l}\n"; 
					if ($PCC{$l} eq "$k")
					{ 
						$liste_fin.="$l "; 
						if (defined $Dist{$k}{$l})
						{ 
							$Dist{$k}{$l}++; 
							$Dist{$l}{$k}++; 
						}
						else
						{
							$Dist{$k}{$l}=1; 
							$Dist{$l}{$k}=1; 
						}
					}
				}
				foreach $l (sort keys %PCC)
				{
					next if (($liste_fin =~ /\ $l\ /) || ($l eq $k));
					$p=$l;
					while ($liste_fin !~ /\ $PCC{$p}\ /)
						{ $p=$PCC{$p}; }
					if (defined $Dist{$p}{$l})
					{ 
						$Dist{$p}{$l}++; 
						$Dist{$l}{$p}++; 
					}
					else
					{
						$Dist{$p}{$l}=1; 
						$Dist{$l}{$p}=1; 
					}
				}
			}
		}
	
	}
	else
		{ die("BioGraph::Compute::distance : bad distance specified '$dist' choose between $choice\n");}
	return(%Dist);
} # fin de 'distance'

sub internal_density
#####################################################
# Tristan Colombo                                   #
# Création : le 23/06/2004                          #
# Modifications : -                                 #
#####################################################
# Calcul de la densité d'un cluster d'un graphe     #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Référence vers une liste de sommets      #
#          Graphe                                   #
# Output : Densité du graphe                        #
#####################################################
{

=pod

=over 4

=item B<internal_density>

Computing of the internal density of a cluster of a graph

=item

SYNOPSIS	$d=internal_density(representation, cluster, graph)

=item

PARAMETERS

=over 6

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<cluster>

the list of vertices of the cluster

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	The internal density of the given cluster of the graph.

=back

=cut

	my $type=shift;
	my $liste_som=shift;
	my %T=@_;
	my ($n, $k, $k2, @s_liste_som);
	my ($d, $traite)=(0, " ");
	@s_liste_som=split(/\ /, $liste_som);
	$n=$#s_liste_som;
	foreach $k (@s_liste_som)
	{
		next if ($k eq "");
		if ($type == 1)
			{ @succ=keys %{$T{$k}}; }
		else
			{ @succ=split(/\ /, $T{$k}); }
		foreach $k2 (@succ)
		{
			if (($traite !~ /\ $k-$k2\ /) && ($traite !~ /\ $k2-$k\ /))
			{
				$traite.="$k-$k2 ";
				$d++;
			}
		}
	}
	if (($n-1) <=0)
		{ return(0); }
	else
		{ return($d/(($n*($n-1))/2)); }
} # fin de 'internal_density'

sub external_density
#####################################################
# Tristan Colombo                                   #
# Création : le 24/06/2004                          #
# Modifications : le 16/07/2004                     #
#####################################################
# Calcul de la densité externe d'un graphe          #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Référence vers liste de clusters         #
#          Graphe                                   #
# Output : Densité du graphe                        #
# Remarque : A OPTIMISER !!!!!!                     #
#####################################################
{

=pod

=over 4

=item B<external_density>

Computing of the external density of a graph

=item

SYNOPSIS	$d=external_density(representation, nb_cluster, ref_cluster, graph)

=item

PARAMETERS

=over 6

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<nb_cluster>

the number of clusters

=item I<ref_cluster>

a reference to the list of clusters

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	The external density of the graph.

=back

=cut

	my $type=shift;
	my $nb_cluster=shift;
	my $ref_clust=shift;
	my %T=@_;
	my ($i, $j, $k, $k2, @clust, @tmp, @tmp2, $traite);
	my ($sum, $n) = (0, 0);
	for ($i=1; $i<$nb_cluster; $i++)
	{ 
		@tmp=split(/\ /, $$ref_clust{$i}); 
		for ($j=2; $j<=$nb_cluster; $j++)
		{ 
			@tmp2=split(/\ /, $$ref_clust{$j}); 
			$sum+=($#tmp*$#tmp2); 
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
							{ $n++; }
					}
					else
					{
						if (((defined $T{$k}) && ($T{$k}=~/\ $k2\ /)) || ((defined $T{$k2}) && ($T{$k2}=~/\ $k\ /)))
							{ $n++; }
					}
				}
			}
		}
	}
	return($n/$sum);
} # fin de 'external_density'

sub maximal_distance
#####################################################
# Tristan Colombo                                   #
# Création : le 25/06/2004                          #
# Modifications : -                                 #
#####################################################
# Calcul de la distance maximale d'un graphe        #
# Input  : Liste de distances                       #
# Output : Distance Maxi                            #
#####################################################
{

=pod

=over 4

=item B<maximal_distance>

Computing of the maximal distance of a graph

=item

SYNOPSIS	$d=maximal_distance(distance_list)

=item

PARAMETERS

=over 6

=item I<distance_list>

hash table of the distances

=back

=item

OUTPUT	The maximal distance.

=back

=cut

	my %T=@_;
	my ($k, $k2);
	my $max=0;
	foreach $k (keys %T)
	{
		foreach $k2 (keys %{$T{$k}})
		{
			if (($max < $T{$k}{$k2}) && ($T{$k}{$k2} != 32767))
				{ $max=$T{$k}{$k2}; }
		}
	}
	return($max);
} # fin de 'maximal_distance'

sub distance2density
#####################################################
# Tristan Colombo                                   #
# Création : le 25/06/2004                          #
# Modifications : -                                 #
#####################################################
# Convert a list of edges distances in vertices     #
# densities                                         #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Référence vers liste de distances        #
#          Graphe                                   #
# Output : Densité du graphe                        #
#####################################################
{

=pod

=over 4

=item B<distance2density>

Convert a list of edges distances in vertices densities

=item

SYNOPSIS	%Dens=distance2density(representation, ref_distances, graph)

=item

PARAMETERS

=over 6

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<ref_distances>

a reference to the list of distances

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	The list of the densities of each vertex.

=back

=cut

	my $type=shift;
	my $ref_dist=shift;
	my %Tc=@_;
	my ($k, $k2, $SD, @succ);
	my $DMax=maximal_distance(%$ref_dist);
	my %T=BioGraph::Operation::symetric($type, %Tc);	
	my %D=degree($type, %T);
	foreach $k (keys %T)
	{
		$SD=0;
		if ($type == 1)
		{
			foreach $k2 (keys %{$T{$k}})
				{ $SD+=$$ref_dist{$k}{$k2}; }
		}
		else
		{
			@succ=split(/\ /, $T{$k});
			foreach $k2 (@succ)
			{
				next if ($k2 eq "");
				$SD+=$$ref_dist{$k}{$k2}; 
			}
		}
		if (($D{$k}==0) || ($SD >= 32767))
			{ $Dens{$k}=0; }
		else
			{ $Dens{$k}=1-$SD/$D{$k}/$DMax; }
	}
	return(%Dens);
} # fin de 'distance2density'

sub edge_density
#####################################################
# Tristan Colombo                                   #
# Création : le 25/06/2004                          #
# Modifications : -                                 #
#####################################################
# Convert a list of edges distances in vertices     #
# densities                                         #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Référence vers liste de distances        #
#          Graphe                                   #
# Output : Densité du graphe                        #
#####################################################
{

=pod

=over 4

=item B<edge_density>

Convert a list of vertices densities in edges densities

=item

SYNOPSIS	%Distance=edge_density(representation, ref_densities, graph)

=item

PARAMETERS

=over 6

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<ref_densities>

a reference to the list of densities

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	The list of the densities for each edge (expressed as a distance)

=back

=cut

	my $type=shift;
	my $ref_dens=shift;
	my %Tc=@_;
	my ($k, $k2, $SD, @succ, %Dist);
	my %T=BioGraph::Operation::symetric($type, %Tc);	
	foreach $k (keys %T)
	{
		if ($type == 1)
			{ @succ=keys %{$T{$k}}; }
		else
			{ @succ=split(/\ /, $T{$k}); }
		foreach $k2 (@succ)
		{
			next if ($k2 eq "");
			$Dist{$k}{$k2}=abs($$ref_dens{$k}-$$ref_dens{$k2});
			$Dist{$k2}{$k}=$Dist{$k}{$k2};
		}
	}
	return(%Dist);
} # fin de 'edge_density'

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
