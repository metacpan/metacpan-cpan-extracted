package BioGraph::Analyze;

# Auteur : Tristan Colombo
# Librairie de traitement des graphes
# Création : le 22/06/2004
# Modifications : -

$VERSION="1.0.0";

=pod

=head1 NAME

BioGraph::Analyze

=head1 SYNOPSIS

use BioGraph::Analyze;

=head1 DESCRIPTION

Package for manipulate graphs represented as well as adjacent matrix or adjacent list. Library for study vertices, edges, degrees, ... of a graph


=head1 AVAILABLE FUNCTIONS

This is the list of the differents functions implemented in this library.

=cut

sub vertices_list
#####################################################
# Tristan Colombo                                   #
# Création : le 22/06/2004                          #
# Modifications : -                                 #
#####################################################
# Donne la liste des sommets d'un graphe            #
# Input  : Type de representation                   #
#          Le graphe                                #
# Output : table de hachage des sommets             #
#####################################################
{

=pod

=over 4

=item B<vertices_list>

Research the list of vertices in a graph.

=over 6

=item

SYNOPSIS	%Lv=vertices_list(representation, graph)

=item 

PARAMETERS

=over 8

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	The hash table of the vertices : if (defined $Lv{A}) then A is a vertex of the graph

=back

=back

=cut

	my $type=shift;
	my %T=@_;
	my (%V, $k, $k2, @succ);
	foreach $k (keys %T)
	{
		$V{$k}=1;
		if ($type == 1)
			{ @succ=keys %{$T{$k}}; }
		else
			{ @succ=split(/\ /, $T{$k}); }
		foreach $k2 (@succ)
		{
			next if ($k2 eq "");
			$V{$k2}=1;
		}
	}
	return(%V);
} # fin de 'vertices_list'

sub degree_distribution
#####################################################
# Tristan Colombo                                   #
# Création : le 23/06/2004                          #
# Modifications : -                                 #
#####################################################
# Distribution du degré des sommets du graphe       #
# Input  : Type de representation                   #
#          Le graphe                                #
# Output : table de distribution des degrés         #
#####################################################
{

=pod

=over 4

=item B<degree_distribution>

Distribution of the degrees of the vertices of the graph.

=over 6

=item

SYNOPSIS	%Dd=degree_distribution(representation, graph)

=item 

PARAMETERS

=over 8

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	The table of the distribution of the vertices of the graph

=back

=back

=cut

	my $type=shift;
	my %T=@_;
	my %Dd;
	my %Deg=BioGraph::Compute::degree($type, %T);
	foreach $k (keys %Deg)
	{
		if (not defined $Dd{$Deg{$k}})
			{ $Dd{$Deg{$k}}=1; }
		else
			{ $Dd{$Deg{$k}}++; }
	}
	return(%Dd);
} # fin de 'degree_distribution'

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
