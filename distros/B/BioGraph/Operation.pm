package BioGraph::Operation;

# Auteur : Tristan Colombo
# Librairie de traitement des graphes
# Création : le 22/06/2004
# Modifications : le 16/07/2004

$VERSION="1.0.1";

=pod

=head1 NAME

BioGraph::Operation

=head1 SYNOPSIS

use BioGraph::Operation;

=head1 DESCRIPTION

Package for manipulate graphs represented as well as adjacent matrix or adjacent list. Library for graph operations such as copy, modification, ...


=head1 AVAILABLE FUNCTIONS

This is the list of the differents functions implemented in this library.

=cut

sub copy_graph
#####################################################
# Tristan Colombo                                   #
# Création : le 18/06/2004                          #
# Modifications : -                                 #
#####################################################
# Copie du graphe                                   #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Graphe                                   #
# Output : Graphe copié                             #
#####################################################
{

=pod

=over 4

=item B<copy_graph>

Copy a graph.

=over 6

=item

SYNOPSIS	%T=copy_graph(representation, graph)

=item

PARAMETERS

=over 8

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	The copied graph (you can use directly %T2=%T instead of this function but in this case, the modifications on %T will affect %T2).

=back

=back

=cut

	my $type=shift;
	my %Ttmp=@_;
	my %T;
	my ($k, $k2);
	if ($type == 1)
	{
		foreach $k (keys %Ttmp)
		{
			foreach $k2 (keys %{$Ttmp{$k}})
			{
				if (defined $Ttmp{$k}{$k2})
					{ $T{$k}{$k2}=1; }
			}
		}
	}
	else
	{
		foreach $k (keys %Ttmp)
			{ $T{$k}=$Ttmp{$k}; }
	}

	return(%T);
} # fin de 'copy_graph'

sub cut_edge
#####################################################
# Tristan Colombo                                   #
# Création : le 18/06/2004                          #
# Modifications : -                                 #
#####################################################
# Coupe une arete du graphe                         #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Sommet de départ                         #
#          Sommet d'arrivée                         #
#          Graphe                                   #
# Output : Graphe dont on a retiré l'arête          #
#####################################################
{

=pod

=over 4

=item B<cut_edge>

Cut an edge of the graph

=over 6

=item

SYNOPSIS	%G=cut_edge(representation, vertex_start, vertex_end, graph)

=item

PARAMETERS

=over 8

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<vertex_start>

start vertex

=item I<vertex_end>

end vertex ('start - end' is an edge)

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	The graph without the edge 'start - end'

=back

=back

=cut
	
	my $type=shift;
	my $s1=shift;
	my $s2=shift;
	my %Ttmp=@_;
	my %T=copy_graph($type, %Ttmp);
	if ($type==1)
	{
		if (defined $T{$s1}{$s2})
			{ delete($T{$s1}{$s2}); }
		if (defined $T{$s2}{$s1})
			{ delete($T{$s2}{$s1}); }
	}
	else
	{
		if (defined $T{$s1})
			{ $T{$s1}=~s/\ $s2\ /\ /; }
		if (defined $T{$s2})
			{ $T{$s2}=~s/\ $s1\ /\ /; }
	}
	return(%T);
} # fin de 'cut_edge'

sub cut_vertex
#####################################################
# Tristan Colombo                                   #
# Création : le 23/06/2004                          #
# Modifications : -                                 #
#####################################################
# Coupe un sommet du graphe                         #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Sommet à supprimer                       #
#          Graphe                                   #
# Output : Graphe dont on a retiré le sommet        #
#####################################################
{

=pod

=over 4

=item B<cut_vertex>

Cut a vertex of the graph

=over 6

=item

SYNOPSIS	%G=cut_vertex(representation, vertex_to_cut, graph)

=item

PARAMETERS

=over 8

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<vertex_to_cut>

the vertex to cut

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	The graph without the vertex 'vertex_to_cut'

=back

=back

=cut
	
	my $type=shift;
	my $s1=shift;
	my %Ttmp=@_;
	my $k;
	my %T=copy_graph($type, %Ttmp);
	if ($type==1)
	{
		if (defined $T{$s1})
		{
			foreach $k (keys %{$T{$s1}})
				{ delete($T{$s1}{$k}); }
		}
		foreach $k (keys %T)
		{
			if (defined $T{$k}{$s1})
				{ delete($T{$k}{$s1}); }
		}
	}
	else
	{
		if (defined $T{$s1})
			{ delete($T{$s1}); }
		foreach $k (keys %T)
			{ $T{$k}=~s/\ $s1\ /\ /; }
	}
	return(%T);
} # fin de 'cut_vertex'

sub symetric
#####################################################
# Tristan Colombo                                   #
# Création : le 17/06/2004                          #
# Modifications : -                                 #
#####################################################
# Calcul du graphe symétrisé Gs associé à G         #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Graphe                                   #
# Output : Graphe Gs                                #
#####################################################
{

=pod

=over 4

=item B<symetric>

Compute the symetric graph Gs associated to G

=over 6

=item

SYNOPSIS	%Gs=symetric(representation, graph)

=item

PARAMETERS

=over 8

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	The symetrised graph associated to G (called Gs)

=back

=back

=cut

	my $type=shift;
	my %Ttmp=@_;
	my ($k, $k2);
	my %T=copy_graph($type, %Ttmp);
	if ($type == 1)
	{
		foreach $k (keys %T)
		{ 
			foreach $k2 (keys %{$T{$k}})
			{
				if (defined $T{$k}{$k2})
					{ $T{$k2}{$k}=1; }
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
				if (defined $T{$k2})
				{
					if ($T{$k2} !~ /\ $k\ /)
						{ $T{$k2}.="$k "; }
				}	
				else
					{ $T{$k2}=" $k "; }
			}
		}
	}
	return(%T);
} # fin de 'symetric'

sub compute_CC
#####################################################
# Tristan Colombo                                   #
# Création : le 17/06/2004                          #
# Modifications : le 16/07/2004                     #
#####################################################
# Decoupage d'un graphe en CC                       #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Création des fichiers .gr associés       #
#          à chaque CC : 0 = Non                    #
#                        1 = Oui                    #
#          Nom de base des fichiers                 #              
#          Graphe                                   #
# Output : Nombre de CC                             #
#####################################################
{

=pod

=over 4

=item B<compute_CC>

Compute the number connected components of a graph and if selected, create them

=over 6

=item

SYNOPSIS	$N=compute_CC(representation, create_file, file_name, graph)

=item

PARAMETERS

=over 8

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<create_file>

enable (or not) the creation of a file for each connected component : 0 = disable, 1 = enable

=item <file_name>

basename of the files (ex: graph => graph_CCx.gr) ; if create_file=0, then indicate "" (or everything else) as file_name

=item <graph>

the hash table of the graph

=back

=item

OUTPUT	The number of connected components and if selected, the files of the CC in format graph (.gr).

=back

=back

=cut

	sub desc_prof
	###################################################
	# Descente en profondeur dans le graphe           #
	# Input : le sommet de départ                     #
	#         la liste des sommets déja traités       #
	#         la liste des éléments de la CC en cours #
	#         le graphe                               #
	###################################################
	{
		my $som=shift;
		my $traite=shift;
		my $liste_som=shift;
		my $type=shift;
		my %Ts=@_;
		my $r;
		my @succ;
		if ($type == 1)
			{ @succ=keys %{$Ts{$som}}; }
		else
			{ @succ=split(/\ /, $Ts{$som}); }
		foreach $r (@succ)
		{
			next if (($traite =~ /\ $r\ /) || ($r eq ""));
			$liste_som .= "$r ";
			$traite .= "$r ";
			($liste_som, $traite) = desc_prof($r, $traite, $liste_som, $type, %Ts);
		}
		return($liste_som, $traite);
	}

	my $type=shift;
	my $creation=shift;
	my $nom_fic=shift;
	my %T=@_;
	my ($k, $k2, $k3, %composante, @nb_elts, @s_T, @s_comp, $fic);
	my ($N, $traite, $nb_ligne, $buffer)=(0, " ", 0, "");
	my %Ts=symetric($type, %T);
	if ($type == 1)
	{
		foreach $k (keys %Ts)
		{
			next if ($traite =~ /\ $k\ /);
			$nb_elts[$N]=1;
			$traite .= "$k ";
			($composante[$N], $traite)=desc_prof($k, $traite, " $k ", $type, %Ts);
			$N++;
		}
		#for ($i=0; $i<$N; $i++)
		#{
		#	print "$i => $composante[$i]\n";
		#}
	}
	else
	{
		foreach $k (keys %Ts)
		{
			next if ($traite =~ /\ $k\ /);
			$nb_elts[$N]=1;
			$traite .= "$k ";
			($composante[$N], $traite)=desc_prof($k, $traite, " $k ", $type, %Ts);
			$N++;
		}
		#for ($i=0; $i<$N; $i++)
		#{
		#	print "$i => $composante[$i]\n";
		#}
	}
	if ($creation)
	{
		for ($k=0; $k<$N; $k++)
		{
			$fic=sprintf("%s_CC%d.gr",$nom_fic, $k+1);
			@s_comp=split(/\ /, $composante[$k]);
			open(S, ">$fic") or die("Impossible de créer le fichier $fic : $!\n");	
			foreach $k2 (@s_comp)
			{
				next if (($k2 eq "") || (not defined $T{$k2}));
				if ($type == 1)
					{ @s_T=keys %{$T{$k2}}; }
				else
					{ @s_T=split(/\ /, $T{$k2}); }
				foreach $k3 (@s_T)
				{
					next if ($k3 eq "");
					if ($composante[$k] =~ /\ $k3\ /)
					{ 
						$buffer.="$k2\t$k3\n"; 
						$nb_ligne++;
					}
				}
			}
			print S "$nb_ligne\n";
			print S $buffer;
			close(S);
		}
	}
	return($N);
} # fin de 'decoupage_CC'

=pod

=head1 AUTHOR AND COPYRIGHT

  Graph::Operation is Copyright (C) 2004, Tristan Colombo
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
