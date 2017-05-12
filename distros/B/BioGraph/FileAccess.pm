package BioGraph::FileAccess;

# Auteur : Tristan Colombo
# Librairie de traitement des graphes
# Création : le 17/06/2004
# Modifications : le 16/07/2004 

use BioGraph::Analyze;

$VERSION="1.0.1";

=pod

=head1 NAME

BioGraph::FileAccess

=head1 SYNOPSIS

use BioGraph::FileAccess;

=head1 DESCRIPTION

Package for manipulate graphs represented as well as adjacent matrix or adjacent list. Library for read and write different types of graph.


=head1 AVAILABLE FUNCTIONS

This is the list of the differents functions implemented in this library.

=cut

sub read_graph
#####################################################
# Tristan Colombo                                   #
# Création : le 17/06/2004                          #
# Modifications : le 22/06/2004                     #
#####################################################
# Lecture d'un graphe au format .gr                 #
# Input  : Nom du fichier                           #
#        : Type de sortie : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#        : Symétriser le graphe : 0 = Non           #
#                                 1 = Oui           #
# Output : Table contenant le graphe                #
#####################################################
{

=pod

=over 4

=item B<read_graph>

Use this function to read graph from file

=over 6

=item

SYNOPSIS	%G=read_graph(file, representation, symetrisation)

=item 

PARAMETERS

=over 8

=item I<file>

the name of the graph file to read ; the recognized formats of graphs are

=over 10

=item I<dot> (extension '.dot') Graph format used by the B<dot> program of the package graphviz from AT&T (http://www.graphviz.org)

=item I<graph> (extension '.gr') In this graph format, the first line is the number of edges and the other lines are the edges in the form : edge1 tabulate edge2

=item I<biolayout> (extension '.biolayout') Graph format used by the B<biolayout> program (http://www.biolayout.org)

=item I<pajek> (extension '.net') Graph format used by the B<pajek> program

=back

Note that the format of the graph is detected by checking the name file, so ensure that your file has the correct extension.

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<symetrisation>

enable (or not) the symetrisation of the edges of the graph : 0 = disable, 1 = enable

=back

=item

OUTPUT	The hash table of the graph read

=over 8

=item I<adjacent matrix>

$G{$s1}{$s2} exists if (and only if) the edge ($s1, $s2) exists

=item I<adjacent list>

$G{$s1} contains the list of all the vertices connected to $s1

=back

=back

=back

=cut

	my $nom_fic=shift;
	my $choix=shift;
	my $symetriser=shift;
	my ($nb_aretes, $ligne, %T, $format);
	# Détection du format
	foreach ($nom_fic)
	{
		/\.gr$/ && do        { $format="gr"; last; };
		/\.biolayout$/ && do { $format="biolayout"; last; };
		/\.net$/ && do       { $format="net"; last; };
		/\.dot$/ && do       { $format="dot"; last; };
		die("Graph::FileAccess::read_graph : File format not recognized $nom_fic (ensure your file is a dot, pajek (.net), biolayout (.biolayout), or graph (.gr) file and has the correct extension)\n");
	}
	open(F, "$nom_fic") or die("Graph::FileAccess::read_graph : Can't open the file $nom_fic - $!\n"); 
	foreach ($format)
	{
		($_ eq "gr") && do { $nb_aretes=<F>; last; };
		($_ eq "net") && do 
				 {
					while ($ligne=<F>) 
						{ last if ($ligne eq "\*Edges\n"); }
					if ($ligne ne "\*Edges\n")
						{ die("Graph::FileAccess::read_graph : File format pajek corrupted in $nom_fic\n") ; }
					last;
				 };
	}
	while ($ligne=<F>)
	{
		chomp($ligne);
		next if ($ligne =~ /^\\\\/);
		next if (($format eq "dot") && ($ligne!~/\"[\w\d\_\-\.]+\"\ \-\-\ \"[\w\d\_\-\.]+\"/));
		foreach ($format)
		{
			(($_ eq "gr") || ($_ eq "biolayout")) && do  { @s_ligne=split(/\t/, $ligne); last; };
			($_ eq "net") && do                          { @s_ligne=split(/\ /, $ligne); last; };
			($_ eq "dot") && do 
				         { 
					 	$ligne=~/\"([\w\d\_\-\.]+)\"\ \-\-\ \"([\w\d\_\-\.]+)\"/;
						$s_ligne[0]=$1;
						$s_ligne[1]=$2;
					 }
		}
		if ($choix==1)
		{
			$T{$s_ligne[0]}{$s_ligne[1]}=1;
			if ($symetriser)
				{ $T{$s_ligne[1]}{$s_ligne[0]}=1; }
		}
		else
		{
			if (not defined $T{$s_ligne[0]})
				{ $T{$s_ligne[0]}=" $s_ligne[1] "; }
			else
			{
				if ($T{$s_ligne[0]} !~ /\ $s_ligne[1]\ /)
					{ $T{$s_ligne[0]}.="$s_ligne[1] "; }
			}
			if ($symetriser)
			{
				if (not defined $T{$s_ligne[1]})
					{ $T{$s_ligne[1]}=" $s_ligne[0] "; }
				else
				{
					if ($T{$s_ligne[1]} !~ /\ $s_ligne[0]\ /)
						{ $T{$s_ligne[1]}.="$s_ligne[0] "; }
				}
			}
		}
	}
	close(F);
	return(%T);
} # fin de 'read_graph'

sub read_association
#####################################################
# Tristan Colombo                                   #
# Création : le 22/06/2004                          #
# Modifications : -                                 #
#####################################################
# Lecture d'un fichier d'association                #
# Input  : Nom du fichier                           #
#          Type de representation                   #
#          Le graphe                                #
# Output : Table les correspondances                #
#####################################################
{

=pod

=over 4

=item B<read_association>

Associate a comment to vertices (ex: associate a function to a protein, ...)

=over 6

=item

SYNOPSIS	%C=read_association(file, representation, graph)

=item 

PARAMETERS

=over 8

=item I<file>

the name of the associations file (format : vertex tabulate comment)

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	The hash table of the associations : vertex <=> comment

=back

=back

=cut

	my $nom_fic=shift;
	my $type=shift;
	my %T=@_;
	my ($ligne, %A);
	my %V=BioGraph::Analyze::vertices_list($type, %T);
	open(F, "$nom_fic") or die("BioGraph::FileAccess::read_association : Can't open the file $nom_fic - $!\n"); 
	while ($ligne=<F>)
	{
		chomp($ligne);
		@s_ligne=split(/\t/, $ligne);
		if ((not defined $s_ligne[0]) || (not defined $s_ligne[1]))
			{ die("BioGraph::FileAccess::read_association : Syntax error in the file association\n"); }
		if (not defined $V{$s_ligne[0]})
			{ die("BioGraph::FileAccess::read_association : Vertex '$s_ligne[0]' not in graph\n"); }
		$A{$s_ligne[0]}=$s_ligne[1];
	}
	close(F);
	return(%A);
} # fin de 'read_association'

sub write_graph
#####################################################
# Tristan Colombo                                   #
# Création : le 17/06/2004                          #
# Modifications : le 22/06/2004                     #
#####################################################
# Sauvegarde du graphe vers un format               #
# spécifié (dot, pajek, biolayout, graph)           #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Nom du fichier de sortie (sans           #
#          l'extension)                             #
#          Format (dot, ps, gif, jpeg, fig)         #
#          Graphe                                   #
# Output : -                                        #
#####################################################
{

=pod

=over 4

=item B<write_graph>

Use this function to write graph to disk in the required format

=over 6

=item

SYNOPSIS	write_graph(representation, file_name, format, graph)

=item

PARAMETERS

=over 8

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<file_name>

the basename of the output file (ex: graph => graph.dot)

=item I<format>

one type of format in : dot, gr, biolayout, net

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	Nothing else the file written to disk

=back

=back

=cut

	my $type=shift;
	my $nom_fic=shift;
	my $format=shift;
	my %T=@_;
	my ($traite, $affiche, $nb_aretes, $format_valide)=(" ", "", 0, "dot, gr, biolayout, net");
	my ($k, $k2, @succ);
	if ($format_valide !~ /$format/)
		{ die("BioGraph::FileAccess::write_graph : file format not recognized ($format). Choose one in $format_valide\n"); }
	if ($format eq "dot")
	{
		open(S, ">$nom_fic.dot") or die("BioGraph::FileAccess::write_graph : Can't create the file $nom_fic.dot - $!\n"); 
		print S "graph G\n{\n";
		if ($type == 1)
		{
			foreach $k (keys %T)
			{ 
				foreach $k2 (keys %{$T{$k}})
				{
					if (($traite !~ /\ $k-$k2\ /) && ($traite !~ /\ $k2-$k\ /))
					{ 
						print S "\t\"$k\" -- \"$k2\";\n";
						$traite.="$k-$k2 ";
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
					if (($traite !~ /\ $k-$k2\ /) && ($traite !~ /\ $k2-$k\ /))
					{ 
						print S "\t\"$k\" -- \"$k2\";\n";
						$traite.="$k-$k2 ";
					}
				}
			}
		}
		print S "}";
		close(S);
	}
	else
	{
		if ($format eq "net")
		{
			open(S, ">$nom_fic.net") or die("BioGraph::FileAccess::write_graph : Can't create the file $nom_fic.net - $!\n"); 
			print S "*Vertices\n";
			foreach $k (keys %T)
			{
				if ($type == 1)
					{ @succ=keys %{$T{$k}}; }
				else
					{ @succ=split(/\ /, $T{$k}); }
				foreach $k2 (@succ)
				{
					next if ($k2 eq "");
					if ($traite !~ /\ $k\ /)
					{
						$traite.="$k ";
						print S "$k\n";
					}
					if ($traite !~ /\ $k2\ /)
					{
						$traite.="$k2 ";
						print S "$k2\n";
					}
				}
			}
			print S "*Edges\n";
		}
		foreach $k (keys %T)
		{
			if ($type == 1)
				{ @succ=keys %{$T{$k}}; }
			else
				{ @succ=split(/\ /, $T{$k}); }
			foreach $k2 (@succ)
			{
				next if ($k2 eq "");
				if ($format eq "net")
					{ $affiche.="$k $k2\n"; }
				else
				{ 
					$affiche.="$k\t$k2\n"; 
					$nb_aretes++;
				}
			}
		}
		if ($format eq "biolayout")
			{ open(S, ">$nom_fic.biolayout") or die("BioGraph::FileAccess::write_graph : Can't create the file $nom_fic.biolayout - $!\n"); }
		if ($format eq "gr")
		{
			open(S, ">$nom_fic.gr") or die("BioGraph::FileAccess::write_graph : Can't create the file $nom_fic.gr - $!\n"); 
			print S "$nb_aretes\n";
		}
		print S $affiche;
		close(S);
	}
} # fin de 'write_graph'

sub write_valuated_graph
#####################################################
# Tristan Colombo                                   #
# Création : le 25/06/2004                          #
# Modifications : -                                 #
#####################################################
# Sauvegarde du graphe vers un format               #
# spécifié (dot, pajek, biolayout, graph)           #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Nom du fichier de sortie (sans           #
#          l'extension)                             #
#          Format (dot, ps, gif, jpeg, fig)         #
#          Graphe                                   #
# Output : -                                        #
#####################################################
{

=pod

=over 4

=item B<write_valuated_graph>

Use this function to write valuated graph to disk in the required format

=over 6

=item

SYNOPSIS	write_graph(representation, file_name, format, ref_distance, graph)

=item

PARAMETERS

=over 8

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<file_name>

the basename of the output file (ex: graph => graph.dot)

=item I<format>

one type of format in : dot, gr, biolayout, net

=item I<ref_distance>

the reference to the table of distances

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	Nothing else the file written to disk

=back

=back

=cut

	my $type=shift;
	my $nom_fic=shift;
	my $format=shift;
	my $ref_dist=shift;
	my %T=@_;
	my ($traite, $affiche, $nb_aretes, $format_valide)=(" ", "", 0, "dot, gr, biolayout, net");
	my ($k, $k2, @succ);

	if ($format_valide !~ /$format/)
		{ die("BioGraph::FileAccess::write_graph : file format not recognized ($format). Choose one in $format_valide\n"); }
	if ($format eq "dot")
	{
		open(S, ">$nom_fic.dot") or die("BioGraph::FileAccess::write_graph : Can't create the file $nom_fic.dot - $!\n"); 
		print S "graph G\n{\n";
		if ($type == 1)
		{
			foreach $k (keys %T)
			{ 
				foreach $k2 (keys %{$T{$k}})
				{
					if (($traite !~ /\ $k-$k2\ /) && ($traite !~ /\ $k2-$k\ /))
					{
						print S "\t\"$k\" -- \"$k2\" [ label=\"$$ref_dist{$k}{$k2}\" ];\n";
						$traite.="$k-$k2 ";
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
					if (($traite !~ /\ $k-$k2\ /) && ($traite !~ /\ $k2-$k\ /))
					{ 
						print S "\t\"$k\" -- \"$k2\" [ label=\"$$ref_dist{$k}{$k2}\" ];\n";
						$traite.="$k-$k2 ";
					}
				}
			}
		}
		print S "}";
		close(S);
	}
	else
	{
		if ($format eq "net")
		{
			open(S, ">$nom_fic.net") or die("BioGraph::FileAccess::write_graph : Can't create the file $nom_fic.net - $!\n"); 
			print S "*Vertices\n";
			foreach $k (keys %T)
			{
				if ($type == 1)
					{ @succ=keys %{$T{$k}}; }
				else
					{ @succ=split(/\ /, $T{$k}); }
				foreach $k2 (@succ)
				{
					next if ($k2 eq "");
					if ($traite !~ /\ $k\ /)
					{
						$traite.="$k ";
						print S "$k\n";
					}
					if ($traite !~ /\ $k2\ /)
					{
						$traite.="$k2 ";
						print S "$k2\n";
					}
				}
			}
			print S "*Edges\n";
		}
		foreach $k (keys %T)
		{
			if ($type == 1)
				{ @succ=keys %{$T{$k}}; }
			else
				{ @succ=split(/\ /, $T{$k}); }
			foreach $k2 (@succ)
			{
				next if ($k2 eq "");
				if ($format eq "net")
					{ $affiche.="$k $k2 $$ref_dist{$k}{$k2}\n"; }
				else
				{ 
					$affiche.="$k\t$k2\t$$ref_dist{$k}{$k2}\n"; 
					$nb_aretes++;
				}
			}
		}
		if ($format eq "biolayout")
			{ open(S, ">$nom_fic.biolayout") or die("BioGraph::FileAccess::write_graph : Can't create the file $nom_fic.biolayout - $!\n"); }
		if ($format eq "gr")
		{
			open(S, ">$nom_fic.gr") or die("BioGraph::FileAccess::write_graph : Can't create the file $nom_fic.gr - $!\n"); 
			print S "$nb_aretes\n";
		}
		print S $affiche;
		close(S);
	}
} # fin de 'write_valuated_graph'

sub write_graph_clusters
#####################################################
# Tristan Colombo                                   #
# Création : le 25/06/2004                          #
# Modifications : le 28/06/2004, 16/07/2004         #
#####################################################
# Sauvegarde du graphe vers un format               #
# spécifié (dot, pajek, biolayout, graph)           #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Nom du fichier de sortie (sans           #
#          l'extension)                             #
#          Format (dot, ps, gif, jpeg, fig)         #
#          Graphe                                   #
# Output : -                                        #
#####################################################
{

=pod

=over 4

=item B<write_graph_clusters>

Use this function to write graph with clusters to disk in the required format

=over 6

=item

SYNOPSIS	write_graph_clusters(representation, file_name, format, cluster_nb, ref_cluster, graph)

=item

PARAMETERS

=over 8

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<file_name>

the basename of the output file (ex: graph => graph.dot)

=item I<format>

one type of format in : dot, gr, biolayout, net

=item I<cluster_nb>

the number of clusters

=item I<ref_cluster>

the table of clusters's elements

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	Nothing else the file written to disk

=back

=back

=cut

	my $type=shift;
	my $nom_fic=shift;
	my $format=shift;
	my $nb_clust=shift;
	my $ref_clust=shift;
	my %T=@_;
	my ($traite, $affiche, $nb_aretes, $format_valide, $coul)=(" ", "", 0, "dot, gr, biolayout, net", 0);
	my ($k, $k2, @succ, %Cluster);
	my @couleurs=( "antiquewhite", "darkslategray", "black", "coral", "beige", "darkorange", "darkgoldenrod", "chartreuse", "aquamarine", "aliceblue", "blueviolet", "whitesmoke", "slategray", "violetred", "tan", "orangered", "yellowgreen", "turquoise", "steelblue", "lavender", "gray", "maroon", "peru", "orange", "lightgoldenrod", "limegreen", "lightcyan", "indigo", "orchid", "dimgray", "chocolate", "hotpink", "firebrick", "indianred", "brown", "sienna", "darkkhaki", "burlywood", "gold", "yellow", "mintcream", "seagreen", "forestgreen", "darkturquoise", "paleturquoise", "blue", "navy", "deepskyblue", "royalblue", "skyblue", "magenta", "plum", "purple", "dodgerblue", "bisque", "wheat", "rosybrown", "tomato", "salmon" );
	if ($format_valide !~ /$format/)
		{ die("BioGraph::FileAccess::write_graph : file format not recognized ($format). Choose one in $format_valide\n"); }
	for ($k=1; $k<=$nb_clust; $k++)
	{
		@succ=split(/\ /, $$ref_clust{$k});
		foreach $k2 (@succ)
		{
			next if ($k2 eq "");
			$Cluster{$k2}=$k;
		}
	}
	if ($format eq "dot")
	{
		open(S, ">$nom_fic.dot") or die("BioGraph::FileAccess::write_graph : Can't create the file $nom_fic.dot - $!\n"); 
		print S "graph G\n{\n";
		foreach $k (keys %Cluster)
		{
			if (not defined $succ[$Cluster{$k}])
				{ $succ[$Cluster{$k}]="subgraph cluster_$k\n{\n\tlabel=\"Class $k\";\n"; }
			if (defined $couleurs[$coul])
				{ $succ[$Cluster{$k}].="\tbgcolor=\"$couleurs[$coul]\";\n"; }
			else
				{ $succ[$Cluster{$k}].="\tbgcolor=\"lightslategray\";\n"; }
			$succ[$Cluster{$k}].="\t\"$k\";\n";
			$coul++;
		}
		foreach $k (@succ)
			{ print S "$k}\n"; }
		@succ=();

		if ($type == 1)
		{
			foreach $k (keys %T)
			{ 
				foreach $k2 (keys %{$T{$k}})
				{
					if (($traite !~ /\ $k-$k2\ /) && ($traite !~ /\ $k2-$k\ /))
					{ 
						print S "\t\"$k\" -- \"$k2\";\n";
						$traite.="$k-$k2 ";
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
					if (($traite !~ /\ $k-$k2\ /) && ($traite !~ /\ $k2-$k\ /))
					{ 
						print S "\t\"$k\" -- \"$k2\";\n";
						$traite.="$k-$k2 ";
					}
				}
			}
		}
		print S "}";
		close(S);
	}
	else
	{
		if ($format eq "net")
		{
			open(S, ">$nom_fic.net") or die("BioGraph::FileAccess::write_graph : Can't create the file $nom_fic.net - $!\n"); 
			print S "*Vertices\n";
			foreach $k (keys %T)
			{
				if ($type == 1)
					{ @succ=keys %{$T{$k}}; }
				else
					{ @succ=split(/\ /, $T{$k}); }
				foreach $k2 (@succ)
				{
					next if ($k2 eq "");
					if ($traite !~ /\ $k\ /)
					{
						$traite.="$k ";
						print S "$k\n";
					}
					if ($traite !~ /\ $k2\ /)
					{
						$traite.="$k2 ";
						print S "$k2\n";
					}
				}
			}
			print S "*Edges\n";
		}
		foreach $k (keys %T)
		{
			if ($type == 1)
				{ @succ=keys %{$T{$k}}; }
			else
				{ @succ=split(/\ /, $T{$k}); }
			foreach $k2 (@succ)
			{
				next if ($k2 eq "");
				if ($format eq "net")
					{ $affiche.="$k $k2\n"; }
				else
				{ 
					$affiche.="$k\t$k2\n"; 
					$nb_aretes++;
				}
			}
		}
		if ($format eq "biolayout")
			{ open(S, ">$nom_fic.biolayout") or die("BioGraph::FileAccess::write_graph_cluster : Can't create the file $nom_fic.biolayout - $!\n"); }
		if ($format eq "gr")
		{
			open(S, ">$nom_fic.gr") or die("BioGraph::FileAccess::write_graph_cluster : Can't create the file $nom_fic.gr - $!\n"); 
			print S "$nb_aretes\n";
		}
		print S $affiche;
		if ($format eq "gr")
		{
			close(S);
			open(S, ">$nom_fic.class") or die("BioGraph::FileAccess::write_graph_cluster : Can't create the file $nom_fic.class : $!\n"); 
		}
		$traite=" ";
		foreach $k (keys %T)
		{
			if ($type == 1)
				{ @succ=keys %{$T{$k}}; }
			else
				{ @succ=split(/\ /, $T{$k}); }
			foreach $k2 (@succ)
			{
				next if ($k2 eq "");
				if ($traite !~ /\ $k2\ /)
				{
					$traite.="$k2 ";
					if (defined $Cluster{$k2})
					{ 
						if ($format eq "gr")
							{ print S "$k2\t$Cluster{$k2}\n"; }
						else
							{ print S "//NODECLASS\t$k2\t$Cluster{$k2}\n"; }
					}
					else
					{
						if ($format eq "gr")
							{ print S "$k2\tNC\n"; }
						else
							{ print S "//NODECLASS\t$k2\tNC\n"; }
					}
				}
				if ($traite !~ /\ $k\ /)
				{
					$traite.="$k ";
					if (defined $Cluster{$k})
					{ 
						if ($format eq "gr")
							{ print S "$k\t$Cluster{$k}\n"; }
						else
							{ print S "//NODECLASS\t$k\t$Cluster{$k}\n"; }
					}
					else
					{ 
						if ($format eq "gr")
							{ print S "$k\tNC\n"; }
						else
							{ print S "//NODECLASS\t$k\tNC\n"; }
					}
				}
			}
		}
		close(S);
	}
	if ($format eq "net")
	{
		open(S, ">$nom_fic.clu") or die("BioGraph::FileAccess::write_graph : Can't create the file $nom_fic.clu - $!\n"); 
		print S "*Vertices\n";
		foreach $k (keys %T)
		{
			if ($type == 1)
				{ @succ=keys %{$T{$k}}; }
			else
				{ @succ=split(/\ /, $T{$k}); }
			foreach $k2 (@succ)
			{
				next if ($k2 eq "");
				if ($traite !~ /\ $k\ /)
				{
					$traite.="$k ";
					print S "$Cluster{$k}\n";
				}
				if ($traite !~ /\ $k2\ /)
				{
					$traite.="$k2 ";
					print S "$Cluster{$k2}\n";
				}
			}
		}
		close(S);
	}
	return(1);
} # fin de 'write_graph_clusters'

sub write_treedyn_clusters
#####################################################
# Tristan Colombo                                   #
# Création : le 01/07/2004                          #
# Modifications : le 16/07/2004                     #
#####################################################
{

=pod

=over 4

=item B<write_treedyn_clusters>

Use this function to write clusters to disk in the treedyn format

=over 6

=item

SYNOPSIS	write_treedyn_clusters(file_name, cluster_nb, ref_cluster)

=item

PARAMETERS

=over 8

=item I<file_name>

the basename of the output file (ex: graph => graph.dot)

=item I<cluster_nb>

the number of clusters

=item I<ref_cluster>

the table of clusters's elements

=back

=item

OUTPUT	Nothing else the file written to disk

=back

=back

=cut

	my $nom_fic=shift;
	my $nb_clust=shift;
	my $ref_clust=shift;
	my ($k, $k2, @succ, %Cluster);
	for ($k=1; $k<=$nb_clust; $k++)
	{
		@succ=split(/\ /, $$ref_clust{$k});
		foreach $k2 (@succ)
		{
			next if ($k2 eq "");
			$Cluster{$k2}=$k;
		}
	}
	open(S, ">$nom_fic.tlf") or die("BioGraph::FileAccess::write_graph_cluster : Can't create the file $nom_fic.tlf : $!\n"); 
	foreach $k (keys %Cluster)
		{ print S "$k\tClasse $Cluster{$k}\n";}
	close(S);
	return(1);
} # fin de 'write_treedynclusters'


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
