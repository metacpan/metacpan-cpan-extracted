package BioGraph::Visual;

# Auteur : Tristan Colombo
# Librairie de traitement des graphes
# Création : le 17/06/2004
# Modifications : le 22/06/2004, 16/07/2004

use BioGraph::FileAccess;

$VERSION="1.0.1";

=pod

=head1 NAME

BioGraph::Visual

=head1 SYNOPSIS

use BioGraph::Visual;

=head1 DESCRIPTION

Package for manipulate graphs represented as well as adjacent matrix or adjacent list. Library for visualize graphs in different format (txt, pdf, ps, 3d, ...).


=head1 AVAILABLE FUNCTIONS

This is the list of the differents functions implemented in this library.

=cut

sub export
#####################################################
# Tristan Colombo                                   #
# Création : le 17/06/2004                          #
# Modifications : le 22/06/2004, 16/07/2004         #
#####################################################
# Exportation du graphe vers un format              #
# spécifié (dot, ps, gif, jpeg, fig)                #
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

=item B<export>

Export the graph in a file image format. To use this function you MUST have installed the 'dot' program from AT&T (http://www.research.att.com/sw/tools/graphviz).

=over 6

=item

SYNOPSIS	export(representation, file_name, format, graph)

=item

PARAMETERS

=over 8

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<file_name>

the basename of the output file (ex: graph => graph.dot)

=item I<format>

one type of format in : ps, gif, jpeg, fig, xdot

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	Nothing else the converted file

=back

=back

=cut

	my $type=shift;
	my $nom_fic=shift;
	my $format=shift;
	my %T=@_;
	my ($traite, $format_valide)=(" ", "ps, gif, jpeg, fig, xdot");
	my ($k, $k2);
	if ($format ne "dot")
	{
		export($type, $nom_fic, "dot", %T);
		if ($format_valide =~ /$format/)
		{
			system("dot -T$format $nom_fic.dot -o $nom_fic.$format");
			system("rm $nom_fic.dot");
		}
		else
			{ die("BioGraph::Visual::export : format ($format) de fichier non valide\n                formats acceptés : $format_valide\n"); }
	}
	else
	{
		open(S, ">$nom_fic.dot") or die("BioGraph::Visual::export : Impossible de créer le fichier $nom_fic.dot - $!\n"); 
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
	return(1);
} # fin de 'export'

sub display
#####################################################
# Tristan Colombo                                   #
# Création : le 17/06/2004                          #
# Modifications : le 22/06/2004, 16/07/2004         #
#####################################################
# Affichage d'un graphe                             #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Graphe                                   #
# Output : -                                        #
#####################################################
{

=pod

=over 4

=item B<display>

This function display on the screen (as text) a graph contained in a hash table

=over 6

=item

SYNOPSIS	display(representation, graph)

=item

PARAMETERS

=over 8

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	Nothing else the graph on the screen

=back

=back

=cut

	my $type=shift;
	my %T=@_;
	my ($k, $k2, $i, $j, $traite);
	my (%marque, %pos, @affiche);
	$traite=" ";
	if ($type == 1)
	{
		$i=0;
		foreach $k (sort keys %T)
		{ 
			if ($traite !~ /\ $k\ /)
			{
				push(@affiche, $k); 
				$pos{$k}=$i++;
				$traite.="$k ";
			}
			foreach $k2 (sort keys %{$T{$k}})
			{
				if ($traite !~ /\ $k2\ /)
				{
					push(@affiche, $k2); 
					$pos{$k2}=$i++;
					$traite.="$k2 ";
				}
			}
		}
		foreach $k (sort @affiche)
			{ print "\t$k"; }
		print "\n";
		foreach $k (sort keys %T)
		{
			%marque=();
			foreach $k2 (sort keys %{$T{$k}})
				{ $marque{$pos{$k2}}=1; }
			print "$k\t";
			for ($j=0; $j<$i; $j++)
			{
				if (defined $marque{$j})
					{ print "1\t"; }
				else
					{ print "0\t"; }
			}
			print "\n";
		}
	}
	else
	{
		foreach $k (sort keys %T)
			{ print "$k => $T{$k}\n"; }
	}
	return(1);
} # fin de 'display'

sub generate_3D
#####################################################
# Tristan Colombo                                   #
# Création : le 23/06/2004                          #
# Modifications : le 16/07/2004                     #
#####################################################
# Génère un graphe en 3D                            #
# Input  : Type du graphe : 1 = Matrice d'adjacence #
#                           2 = Liste d'adjacence   #
#          Référence vers la liste des densités     #
#          Graphe                                   #
# Output : -                                        #
#####################################################
{

=pod

=over 4

=item B<generate_3D>

Generate the representation in 3 dimensions of the vertices densities of a graph (pdf file). You MUST have installed the R package to use this function (http://www.R-project.org).

=over 6

=item

SYNOPSIS	generate_3D(file_name, representation, ref_densities, graph)

=item

PARAMETERS

=over 8

=item I<file_name>

the name of the file to produce without extension

=item I<representation>

the type of representation choosen : 1 = adjacent matrix, and 2 = adjacent list

=item I<ref_densities>

the reference of the hash table of densities

=item I<graph>

the hash table of the graph

=back

=item

OUTPUT	The 3D graph in pdf format

=back

=back

=cut

	sub insere_matrix
	{
		my $degre=shift;
		my $x=shift;
		my $y=shift;
		my $v=shift;
		my $PAS=shift;
		my @M=@_;
		my ($i, $j, $k, $valeur, $l);
		$M[$x][$y]=$v;
		$k=3;
		for ($j=0; $j<$degre; $j++)
		{
			$i=$j+1;
			$valeur=$v-($i*$PAS);
			if ($valeur<0)
				{ $valeur=0; }
			for ($l=0; $l<$k; $l++)
			{
				next if (($y-$i+$l)<0);
				if ((not defined $M[$x+$i][$y-$i+$l]) || ($M[$x+$i][$y-$i+$l]<$valeur))
					{ $M[$x+$i][$y-$i+$l]=$valeur; }
			}
			for ($l=0; $l<$k; $l++)
			{
				next if ((($y-$i+$l)<0) || (($x-$i)<0));
				if ((not defined $M[$x-$i][$y-$i+$l]) || ($M[$x-$i][$y-$i+$l]<$valeur))
					{ $M[$x-$i][$y-$i+$l]=$valeur; }
			}
			for ($l=0; $l<($k-2); $l++)
			{	
				next if (($x-$i+$l+1)<0);
				if ((not defined $M[$x-$i+$l+1][$y+$i]) || ($M[$x-$i+$l+1][$y+$i]<$valeur))
					{ $M[$x-$i+$l+1][$y+$i]=$valeur; }
			}
			for ($l=0; $l<($k-2); $l++)
			{
				next if ((($x-$i+$l+1)<0) || (($y-$i)<0));
				if ((not defined $M[$x-$i+$l+1][$y-$i]) || ($M[$x-$i+$l+1][$y-$i]<$valeur))
					{ $M[$x-$i+$l+1][$y-$i]=$valeur; }
			}
			$k+=2;
		}
		return(@M);
	}

	sub max
	{
		my $a=shift;
		my $b=shift;
		my $c=shift;
		my $d=shift;
		my $r=0;
		if ($a > $r)
			{ $r=$a; }
		if ($b > $r)
			{ $r=$b; }
		if ($c > $r)
			{ $r=$c; }
		if ($d > $r)
			{ $r=$d; }
		return($r);
	}

	my $file_name=shift;
	my $type=shift;
	my $ref_density=shift;
	my %T=@_;
	my ($PAS, $DEGRE, $ECHELLE, $XMAX, $YMAX)=(0.05, 10, 20, 0, 0);
	my ($a, $b, $c, $d, $i, $j, $v, $xmax, $ymax, @M, @N, $ligne, $esp, $aff);

	# sauvegarde du fichier en .dot
	BioGraph::FileAccess::write_valuated_graph($type, $file_name, "dot", \%$ref_density, %T);

	# export du fichier en .xdot 
	system("dot -Tdot $file_name.dot -o $file_name.xdot");

	open(F, "$file_name.xdot") or die("BioGraph::Visual::generate_3D : Impossible d'ouvrir le fichier $file_name - $!\n"); 
	while ($ligne=<F>)
	{
		#if ($ligne=~/^\t\"[\w\d\(\)\ \.]+\" \[/)
		#{
		#	if ($ligne=~/pos=\"(\d+),(\d+)\"/)
		#		{ $x=int($1/$ECHELLE); $y=int($2/$ECHELLE); }
		#	if ($ligne=~/^\t\"[\d\w\ ]+\ \(([\d\.]+)\)/)
		if ($ligne=~/^\t[\w\d\-\_\.]+\ --\ [\w\d\-\_\.]+\ \[label=([\"\.\d]+),/)
		{
			$v=$1;
			$v=~s/\"//g;
			if ($ligne=~/lp=\"(\d+),(\d+)\"/)
				{ $x=int($1/$ECHELLE); $y=int($2/$ECHELLE); }
			if ($x > $XMAX)
				{ $XMAX=$x; }
			if ($y > $YMAX)
				{ $YMAX=$y; }
			@M=insere_matrix($DEGRE, $x, $y, $v, $PAS, @M);
		}
	}
	close(F);

	open(S, ">$file_name.cmd") or die("BioGraph::Visual::generate_3D : Impossible de créer le fichier $file_name.cmd - $!\n"); 
	print S "bitmap(\"$file_name.pdf\", type=\"pdfwrite\")\n\n";
	$ymax=$YMAX+$DEGRE+1;
	$xmax=$XMAX+$DEGRE+1;
	print S "x <- c(1:".$ymax.")\n\n";
	print S "y <- c(1:".$xmax.")\n\n";
	print S "z <- matrix(nr=".$ymax.", nc=".$xmax.")\n";
	for ($i=1; $i<=$ymax; $i++)
	{
		print S "z[$i,] <- c(";
		$esp=0;
		for ($j=1; $j<=$XMAX+$DEGRE; $j++)
		{
			if (defined $M[$j][$i])
			{
				$aff=sprintf("%.2f, ",$M[$j][$i]);
				print S $aff;
			}
			else
			{ print S "0, "; }
			if (++$esp==100)
			{
				print S "\n";
				$esp=0;
			}
		}
		print S "0)\n";
	}

	# Preparation de la matrice des couleurs
	for ($i=1; $i<$ymax; $i++)
	{
		for ($j=1; $j<$xmax; $j++)
		{
			if (defined $M[$j][$i])
				{ $a=$M[$j][$i]; }
			else
				{ $a=0; }
			if (defined $M[$j][$i+1])
				{ $b=$M[$j][$i+1]; }
			else
				{ $b=0; }
			if (defined $M[$j+1][$i+1])
				{ $c=$M[$j+1][$i+1]; }
			else
				{ $c=0; }
			if (defined $M[$j+1][$i])
				{ $d=$M[$j+1][$i]; }
			else
				{ $d=0; }
			$N[$j][$i]=max($a, $b, $c, $d);
		}
	}

	$ymax-=1;
	$xmax-=1;
	print S "\nc <- heat.colors(11)\n";
	print S "fcol <- matrix(nr=".$ymax.", nc=".$xmax.")\n";
	for ($i=1; $i<=$ymax; $i++)
	{
		print S "fcol[$i,] <- c(";
		$esp=0;
		for ($j=1; $j<$xmax; $j++)
		{
			if (defined $N[$j][$i])
				{ print S "c[".int(11-($N[$j][$i]*10))."], "; }
			else
				{ print S "c[11], "; }
			if (++$esp==100)
			{
				print S "\n";
				$esp=0;
			}
		}
		print S "c[11])\n";
	}

	print S "\npersp(x,y,z, theta=130, shade=0.75, phi=50, ltheta=120, ticktype=\"detailed\", expand=0.5, col=fcol)\n";
	close(S);
	system("R --save < $file_name.cmd > /dev/null");
	return(1);
	#system("rm $file_name.dot $file_name.xdot $file_name.cmd");
} # fin de 'generate_3D'

=pod

=head1 AUTHOR AND COPYRIGHT

  BioGraph::Visual is Copyright (C) 2004, Tristan Colombo
                                     CNRS - LCB, 31 chemin Joseph Aiguier
                                     13009 Marseille
                                     France

                                     Email: tristan.colombo@ibsm.cnrs-mrs.fr

  All rights reserved.

  You may distribute this package under the terms of the GNU
  General Public License.

=cut

1;
