package Autodia::Diagram;
use strict;

=head1 NAME

Autodia::Diagram - Class to hold a collection of objects representing parts of a Dia Diagram.

=head1 SYNOPSIS

use Autodia::Diagram;

my $Diagram = Autodia::Diagram->new;

=head2 Description

Diagram is an object that contains a collection of diagram elements and the logic to generate the diagram layout as well as to output the diagram itself in Dia's XML format using template toolkit.

=cut

use Template;
use Data::Dumper;

$Data::Dumper::Maxdepth = 2;

use Autodia::Diagram::Class;
use Autodia::Diagram::Component;
use Autodia::Diagram::Superclass;
use Autodia::Diagram::Dependancy;
use Autodia::Diagram::Inheritance;
use Autodia::Diagram::Relation;
use Autodia::Diagram::Realization;

my %dot_filetypes = (
		     gif => 'as_gif',
		     png => 'as_png',
		     jpg => 'as_jpeg',
		     jpeg => 'as_jpeg',
		     dot => 'as_canon',
		     svg => 'as_svg',
		     fig => 'as_fig',
		    );

my %vcg_filetypes = (
		     ps => 'as_ps',
		     pbm => 'as_pbm',
		     ppm => 'as_ppm',
		     vcg => 'as_vcg',
		     plainvcg => 'as_plainvcg',
		    );

#----------------------------------------------------------------
# Constructor Methods


=head1 METHODS

=head2 Class Methods

=over 4

=item new - constructor method

creates and returns an unpopulated diagram object.

=back

=cut

sub new
{
  my $class = shift;

  my $config_ref = shift;
  my $Diagram = {};
  bless ($Diagram, ref($class) || $class);
  $Diagram->directed(1);
  $Diagram->_initialise($config_ref);
  return $Diagram;
}

=head2 Object methods

To get a collection of a objects of a certain type you use the method of the same name. ie $Diagram->Classes() returns an array of 'class' objects.

The methods available are Classes(), Components(), Superclasses(), Inheritances(), Relations(), and Dependancies(); These are all called in the template to get the collections of objects to loop through.

To add an object to the diagram. You call the add_<object type> method, for example $Diagram->add_class($class_name), passing the name of the object in the case of Class, Superclass and Component but not Inheritance or Dependancy which have their names generated automagically.

Objects are not removed, they can only be superceded by another object; Component can be superceded by Superclass which can superceded by Class. This is handled by the object itself rather than the diagram.

=head2 Accessing and manipulating the Diagram

Elements are added to the Diagram through the add_<elementname> method (ie add_classes() ).

Collections of elements are retrieved through the <elementname> method (ie Classes() ).

The diagram is laid out and output to a file using the export_xml() method.

=cut

################
# Access Methods

sub directed {
    my $self = shift;
    my $value = shift;
    $self->{directed} = $value if (defined $value);
    $self->{directed} ||= 0;
    return $self->{directed};
}

sub add_inputfile {
    my $self = shift;
    my $inputfile = shift;
    $self->{input_files}{$inputfile} = 1;
    return;
}

sub is_inputfile {
    my $self = shift;
    my $name = shift;
    return $self->{input_files}{$name};
}


sub add_dependancy
{
    my $self = shift;
    my $dependancy = shift;

    $self->_package_add($dependancy);
    $dependancy->Set_Id($self->_object_count);

    return 1;
}

sub add_realization {
   my $self        = shift;
   my $realization = shift;

   $self->_package_add($realization);
   $realization->Set_Id( $self->_object_count );

   return 1;
 }

sub add_inheritance {
    my $self = shift;
    my $inheritance = shift;

    $self->_package_add($inheritance);
    $inheritance->Set_Id($self->_object_count);

    return 1;
}

sub add_relation {
    my $self = shift;
    my $relation = shift;

    $self->_package_add($relation);
    $relation->Set_Id($self->_object_count);

    return 1;
}

sub add_component
{
    my $self = shift;
    my $component = shift;
    my $return = 0;

    # check to see if package of this name already exists
    my $exists = $self->_package_exists($component);

    if (ref($exists))
    {
      if ($exists->Type eq "Component")
	{
	  # replace self with already present component
	  $component->Redundant($exists);
	  $return = $exists;
      	}
    }
    else
    {
	# component is new and unique
	$self->_package_add($component);
	$component->Set_Id($self->_object_count);
    }

    return $return;
}

sub add_superclass
{
  my $self = shift;
  my $superclass = shift;
  my $return = 0;

  # check to see if package of this name already exists
  my $exists = $self->_package_exists($superclass);

  if (ref($exists))
    {
      if ($exists->Type eq "superclass")
	{ $return = $exists;}
      else { print STDERR "eek!! wrong type of object returned by _package_exists\n"; }
    }
  else
    {
      $self->_package_add($superclass);
      $superclass->Set_Id($self->_object_count);
    }
  return $return;
}

sub add_class
{
    my $self = shift;
    my $class = shift;

    # some perl modules such as CGI.pm do things by redeclaring packages - eek!
    # this is a nasty hack to get around that nasty hack. ie class is not added
    # to diagram and so everything is discarded until next new package declared
    if (defined $self->{"packages"}{"class"}{$class->Name})
      {
	print STDERR "Diagram.pm : add_class : ignoring duplicate class",
	  $class->Name, "\n";
#	warn Dumper (original_class=>$self->{"packages"}{"class"}{$class->Name});
	return $self->{"packages"}{"class"}{$class->Name};
      }
    # note : when running benchmark.pl this seems to appear which I guess is a
    # scoping issue when calling autodial multiple times - odd, beware if using
    # mod_perl or something similar, not that it breaks anything but you never know

    $class->Set_Id($self->_object_count);
    $self->_package_add($class);

    return $class;
}

sub remove_duplicates
  {
    my $self = shift;

    if (defined $self->{"packages"}{"superclass"})
      {
	my @superclasses = @{$self->Superclasses};
	foreach my $superclass (@superclasses)
	  {
	    # if a component exists with the same name as the superclass
	    if (defined $self->{"packages"}{"Component"}{$superclass->Name})
	      {
		my $component = $self->{"packages"}{"Component"}{$superclass->Name};
		# mark component redundant
		$component->Redundant;
		# remove component
		$self->_package_remove($component);
		# kill its dependancies
		foreach my $dependancy ($component->Dependancies)
		  {
		    # remove dependancy
		    $self->_package_remove($dependancy);
		  }
	      }
	  }
      }

    if (defined $self->{"packages"}{"class"})
      {
	my @classes = @{$self->Classes};
	foreach my $class (@classes)
	  {
	    # if a superclass exists with the same name as the class
	    if (defined $self->{"packages"}{"superclass"}{$class->Name})
	      {
		# mark as redundant, remove and steal its children
		my $superclass = $self->{"packages"}{"superclass"}{$class->Name};
		$superclass->Redundant;
		$self->_package_remove($superclass);
		foreach my $inheritance ($superclass->Inheritances) {
		    if (ref($inheritance)) {
			$inheritance->Parent($class->Id); 
		    } else {
			warn "problem with inheritance : $inheritance - class : ",$class->Name,"\n";
		    }
		}
		$class->has_child(scalar $superclass->Inheritances);

		foreach my $relation ($superclass->Relations) {
		    $relation->Right($class);
		}

	      }

	    # if a component exists with the same name as the class
	    if (defined $self->{"packages"}{"Component"}{$class->Name})
	      {
		# mark as redundant, remove and steal its children
		my $component = $self->{"packages"}{"Component"}{$class->Name};
		$component->Redundant;
		$self->_package_remove($component);
		foreach my $dependancy ($component->Dependancies)
		  { $dependancy->Parent($class->Id); }
	      }

	  }
      }
    return 1;
  }

###

sub Classes
  {
    my $self = shift;

    my ($cp, $cf, $cl) = caller;

    my %config = %{$self->{_config}};
    unless (defined $self->{packages}{class})
    {
	print STDERR "Diagram.pm : Classes : no Classes to be printed\n";
	return 0;
    }
    my @classes;
    my %classes = %{$self->{"packages"}{"class"}};
    my @keys = keys %classes;
    my $i = 0;

    foreach my $key (@keys)
      {	$classes[$i++] = $classes{$key}; }

    my $return = \@classes;

    if (($config{sort}) && ($cp ne "Diagram"))
      { $return = $self->_sort(\@classes); }


    return $return;
  }


sub InputFiles {
    my $self = shift;
    return $self->{input_files};
}

sub Components
  {
    my $self = shift;
    unless (defined $self->{"packages"}{"Component"})
    {
	print STDERR "Diagram.pm : Components : no Components to be printed\n";
	return 0;
    }
    my @components;
    my %components = %{$self->{"packages"}{"Component"}};
    my @keys = keys %components;
    my $i = 0;

    foreach my $key (@keys)
      {	$components[$i++] = $components{$key}; }

    return \@components;
  }

sub Superclasses
  {
    my $self = shift;
    unless (defined $self->{"packages"}{"superclass"})
    {
	print STDERR "Diagram.pm : Superclasses : no superclasses to be printed\n";
	return 0;
    }
    my @superclasses;
    my %superclasses = %{$self->{"packages"}{"superclass"}};
    my @keys = keys %superclasses;
    my $i = 0;

    foreach my $key (@keys)
      {
	$superclasses[$i++] = $superclasses{$key};
      }
    return \@superclasses;
  }

sub Inheritances
  {
    my $self = shift;
    unless (defined $self->{"packages"}{"inheritance"})
    {
	print STDERR "Diagram.pm : Inheritances : no Inheritances to be printed - ignoring..\n";
	return 0;
    }
    my @inheritances;
    my %inheritances = %{$self->{"packages"}{"inheritance"}};
    my @keys = keys %inheritances;
    my $i = 0;

    foreach my $key (@keys)
      {
	$inheritances[$i++] = $inheritances{$key};
      }

    return \@inheritances;
  }

sub Relations {
    my $self = shift;

    unless (defined $self->{"packages"}{"relation"}) {
	print STDERR "Diagram.pm : Relations : no Relations to be printed - ignoring..\n";
	return 0;
    }

    my @relations;
    my %relations = %{$self->{"packages"}{"relation"}};
    my @keys = keys %relations;
 

    my $i = 0;
    foreach my $key (@keys)  {
      $relations[$i++] = $relations{$key};
    }

    return \@relations;
  }

sub Realizations {
   my $self = shift;

   unless( defined $self->{"packages"}{"realization"} ) {
     print STDERR "Realizations Diagram.pm : none to be printed - ignoring..\n
";
     return 0;
   }

   my @realizations;
   my %realizations = %{ $self->{"packages"}{"realization"} };
   my @keys         = keys %realizations;
   my $i            = 0;

   foreach my $key (@keys) {
     $realizations[ $i++ ] = $realizations{$key};
   }

   return \@realizations;
 }

sub Dependancies
  {
    my $self = shift;
    unless (defined $self->{"packages"}{"dependancy"})
    {
	print STDERR "Diagram.pm : Dependancies : no dependancies to be printed - ignoring..\n";
	return 0;
    }
    my @dependancies;
    my %dependancies = %{$self->{"packages"}{"dependancy"}};
    my @keys = keys %dependancies;
    my $i = 0;

    foreach my $key (@keys)
      {
	$dependancies[$i++] = $dependancies{$key};
      }

    return \@dependancies;
  }

##########################################################
# export_graphviz - output to file via GraphViz.pm and dot

sub export_graphviz
  {
    my $self = shift;
    require GraphViz;
    require Data::Dumper;

    my %config          = %{$self->{_config}};

    my $output_filename = $config{outputfile};

    my ($extension) = reverse (split(/\./,$output_filename));

    $extension = "gif" unless ($dot_filetypes{$extension});

    $output_filename =~ s/\.[^\.]+$/.$extension/;

    my %args = (directed => $self->directed, ratio => 'expand', concentrate => 1, splines=>'false', lines=>1);
#    $args{layout} = 'fdp' unless ($self->directed);
#    $args{overlap} = 'false' unless ($self->directed);
    my $g = GraphViz->new( %args );

    my %nodes = ();

    my $classes = $self->Classes;
    if (ref $classes) { 
      foreach my $Class (@$classes) {

	my $node = '{'.$Class->Name."|";

	if ($config{methods}) {
	  my @method_strings = ();
	  my ($methods) = ($Class->Operations);
	  foreach my $method (@$methods) {
	    next if ($method->{visibility} == 1 && $config{public});
	    my $method_string = ($method->{visibility} == 0) ? '+ ' : '- ';
	    $method_string .= $method->{name}."(";
	    if (ref $method->{"Params"} ) {
	      my @args = ();
	      foreach my $argument ( @{$method->{"Params"}} ) {
		  push (@args, ((defined ($argument->{Type}) )? $argument->{Type} . " " . $argument->{Name} : $argument->{Name}));
	      }
	      $method_string .= join (", ",@args) if (scalar @args);
	    }
	    $method_string .= " ) : ". (defined $method->{type} ? $method->{type} : '');
	    push (@method_strings,$method_string);
	  }
	  foreach my $method_string ( @method_strings ) {
	    $node .= "$method_string".'\l';
	  }
	}
	$node .= "|";
	if ($config{attributes}) {
	  my ($attributes) = ($Class->Attributes);
	  foreach my $attribute (@$attributes) {
	    next if ($attribute->{visibility} == 1 && $config{public});
	    $node .= ($attribute->{visibility} == 0) ? '+ ' : '- ';
	    $node .= $attribute->{name};

	    # Check if $attribute->{type} is defined.
            # Otherwise we get warnings like:
            if (defined $attribute->{type}) {
              $node .= " : ".$attribute->{type}.'\l';
            } else {
              $node .= '\l';
            }
	  }
	}

	$node .= '}';

	$nodes{$Class->Id} = $node;

	$g->add_node($node,shape=>'record');

      }
    } else {
      return 0;
    }

    unless ($config{skip_superclasses}) {
	my $superclasses = $self->Superclasses;
	if (ref $superclasses) {
	    foreach my $Superclass (@$superclasses) {
		#	warn "superclass name :", $Superclass->Name, " id :", $Superclass->Id, "\n";
		my $node = $Superclass->Name;
		$node=~ s/[\{\}]//g;
		$node = '{'.$node."|\n}";
		#	warn "node : $node\n";
		$nodes{$Superclass->Id} = $node;
		$g->add_node($node,shape=>'record');
	    }
	}
    }


    my $inheritances = $self->Inheritances;
    if (ref $inheritances) {
      foreach my $Inheritance (@$inheritances) {
	  next unless ($nodes{$Inheritance->Parent});
	  #	warn "inheritance parent :", $Inheritance->Parent, " child :", $Inheritance->Child, "\n";
	  $g->add_edge($nodes{$Inheritance->Parent} => $nodes{$Inheritance->Child}, dir => 'back');
      }
    }

    my $relations = $self->Relations;
    if (ref $relations) {
      foreach my $Relation (@$relations) {
	  next unless ($nodes{$Relation->Left});
	  my %edge_args = (dir => 'none', weight => 1.2 );
	  $g->add_edge($nodes{$Relation->Left} => $nodes{$Relation->Right}, %edge_args);      
      }
    }

    unless ($config{skip_packages}) {
	my $components = $self->Components;
	if (ref $components) {
	    foreach my $Component (@$components) {
		#	warn "component name :", $Component->Name, " id :", $Component->Id, "\n";
		my $node = '{'.$Component->Name.'}';
		#	warn "node : $node\n";
		$nodes{$Component->Id} = $node;
		$g->add_node($node, shape=>'record');
	    }
	}
    }

    my $dependancies = $self->Dependancies;
    if (ref $dependancies) {
      foreach my $Dependancy (@$dependancies) {
	  #	warn "dependancy parent ", $Dependancy->Parent, " child :", $Dependancy->Child, "\n";
	  next unless ($nodes{$Dependancy->Parent});
	  $g->add_edge($nodes{$Dependancy->Parent}=>$nodes{$Dependancy->Child}, dir => 'back', style=>'dashed');
      }
    }

    open (FILE,">$output_filename") or die "couldn't open $output_filename file for output : $!\n";
    binmode FILE;
    eval 'print FILE $g->'. $dot_filetypes{$extension};

    close FILE;

    return 1;
  }

sub Warn {
    my ($self,$warning) = @_;
    warn "warning : $warning\n";
    return;
}


########################################################
# export_springgraph - output to file via SpringGraph.pm

sub export_springgraph
  {
    my $self = shift;
    my %config          = %{$self->{_config}};

    require SpringGraph;
    require Data::Dumper;

    my $output_filename = $config{outputfile};
    my ($extension) = reverse (split(/\./,$output_filename));
    $extension = "gif" unless ($dot_filetypes{$extension});
    $output_filename =~ s/\.[^\.]+$/.$extension/;

    my $g = new SpringGraph;

    my %nodes = ();
    my $classes = $self->Classes;
    if (ref $classes) { 
      foreach my $Class (@$classes) {

	my $node = $Class->Name."|";

	if ($config{methods}) {
	  my @method_strings = ();
	  my ($methods) = ($Class->Operations);
	  foreach my $method (@$methods) {
	    next if ($method->{visibility} == 1 && $config{public});
	    my $method_string = ($method->{visibility} == 0) ? '+ ' : '- ';
	    $method_string .= $method->{name}."(";
	    if (ref $method->{"Params"} ) {
	      my @args = ();
	      foreach my $argument ( @{$method->{"Params"}} ) {
		  push (@args, ((defined ($argument->{Type}) )? $argument->{Type} . " " . $argument->{Name} : $argument->{Name}));
	      }
	      $method_string .= join (", ",@args) if (scalar @args);
	    }
	    $method_string .= " ) : ". (defined $method->{type} ? $method->{type} : '');
	    push (@method_strings,$method_string);
	  }
	  foreach my $method_string ( @method_strings ) {
	    $node .= "$method_string\n";
	  }
	}
	$node .= "|";
	if ($config{attributes}) {
	  my ($attributes) = ($Class->Attributes);
	  foreach my $attribute (@$attributes) {
	    next if ($attribute->{visibility} == 1 && $config{public});
	    $node .= "\n" . ($attribute->{visibility} == 0) ? '+ ' : '- ';
	    $node .= $attribute->{name};
	    $node .= " : ".$attribute->{type} if (defined $attribute->{type});
	    $node .= "\n";
	  }
	}

	$nodes{$Class->Id} = $Class->Name;

	$g->add_node($Class->Name, label=>$node,shape=>'record');

      }
    } else {
      return 0;
    }
    unless ($config{skip_superclasses}) {
	my $superclasses = $self->Superclasses;
	if (ref $superclasses) {
	    foreach my $Superclass (@$superclasses) {
		#	warn "superclass name :", $Superclass->Name, " id :", $Superclass->Id, "\n";
		my $node = $Superclass->Name;
		$node=~ s/[\{\}]//g;
		$node .= "|\n";
		#	warn "node : $node\n";
		$nodes{$Superclass->Id} = $node;
		$g->add_node($node,label=>$node,shape=>'record');
	    }
	}
    }
    my $inheritances = $self->Inheritances;
    if (ref $inheritances) {
	foreach my $Inheritance (@$inheritances) {
	    next unless ($nodes{$Inheritance->Parent});
	    #	warn "inheritance parent :", $Inheritance->Parent, " child :", $Inheritance->Child, "\n";
	    $g->add_edge(
			 $nodes{$Inheritance->Parent}=>$nodes{$Inheritance->Child},
			 dir=>'1',
			);
	}
    }

    my $relations = $self->Relations;
    if (ref $relations) {
      foreach my $Relation (@$relations) {
	  next unless ($nodes{$Relation->Left});
	  #	warn "relation left :", $Relation->Left, " right :", $Relation->Right, "\n";
	  my %edge_args = ($nodes{$Relation->Left} => $nodes{$Relation->Right}, style => 'dotted');
	  $g->add_edge(%edge_args);      
      }
    }

    unless ($config{skip_packages}) {
	my $components = $self->Components;
	if (ref $components) {
	    foreach my $Component (@$components) {
		#	warn "component name :", $Component->Name, " id :", $Component->Id, "\n";
		my $node = $Component->Name;
		#	warn "node : $node\n";
		$nodes{$Component->Id} = $node;
		$g->add_node($node,label=>$node, shape=>'record');
	    }
	}
    }

    my $dependancies = $self->Dependancies;
    if (ref $dependancies) {
      foreach my $Dependancy (@$dependancies) {
	  next unless ($nodes{$Dependancy->Parent});
	  #	warn "dependancy parent ", $Dependancy->Parent, " child :", $Dependancy->Child, "\n";
	  $g->add_edge( $nodes{$Dependancy->Parent}=>$nodes{$Dependancy->Child}, style=>'dashed',dir=>1);
      }
    }

    $g->as_png($output_filename);

    return 1;
  }

####################################################
# export_vcg - output to file via VCG.pm and xvcg

sub export_vcg {
  my $self = shift;
  require VCG;
  require Data::Dumper;

  my %config          = %{$self->{_config}};
  my $output_filename = $config{outputfile};
  my ($extension)     = reverse (split(/\./,$output_filename));
  $extension          = "pbm" unless ($vcg_filetypes{$extension});

  $output_filename =~ s/\.[^\.]+$/.$extension/;

  my $vcg     = VCG->new(scale=>100,);
  my %nodes   = ();
  my $classes = $self->Classes;

  if (ref $classes) {
    foreach my $Class (@$classes) {
      #	warn "class name : ", $Class->Name , " id :", $Class->Id, "\n";
      my $node = $Class->Name."\n----------------\n";

      if ($config{methods}) {
	my @method_strings = ();
	my ($methods) = ($Class->Operations);
	foreach my $method (@$methods) {
	  next if ($method->{visibility} == 1 && $config{public});
	  my $method_string = ($method->{visibility} == 0) ? '+ ' : '- ';
	  $method_string .= $method->{name}."(";
	  if (ref $method->{"Params"} ) {
	    my @args = ();
	    foreach my $argument ( @{$method->{"Params"}} ) {
	      push (@args, $argument->{Type} . " " . $argument->{Name});
	    }
	    $method_string .= join (", ",@args);
	  }
	  $method_string .= " ) : ". $method->{type};
	  push (@method_strings,$method_string);
	}
	foreach my $method_string ( @method_strings ) {
	  $node .= "$method_string\n";
	}
      }
      $node .= "----------------\n";
      if ($config{attributes}) {
	my ($attributes) = ($Class->Attributes);
	foreach my $attribute (@$attributes) {
	  next if ($attribute->{visibility} == 1 && $config{public});
	  $node .= ($attribute->{visibility} == 0) ? '+ ' : '- ';
	  $node .= $attribute->{name};
	  $node .= " : $attribute->{type} \n";
	}
      }

      $nodes{$Class->Id} = $node;

      $vcg->add_node(label=>$node, title=>$node);

    }
  } else {
    return 0;
  }

  unless ($config{skip_superclasses}) {
      my $superclasses = $self->Superclasses;

      if (ref $superclasses) {
	  foreach my $Superclass (@$superclasses) {
	      #      warn "superclass name :", $Superclass->Name, " id :", $Superclass->Id, "\n";
	      my $node = $Superclass->Name()."\n----------------\n";
	      $nodes{$Superclass->Id} = $node;
	      $vcg->add_node(title=>$node, label=> $node);
	  }
      }
  }

  my $inheritances = $self->Inheritances;
  if (ref $inheritances) {
      foreach my $Inheritance (@$inheritances) {
	  next unless ($nodes{$Inheritance->Parent});
	  #	warn "inheritance parent :", $Inheritance->Parent, " child :", $Inheritance->Child, "\n";
	  $vcg->add_edge(
			 source=>$nodes{$Inheritance->Parent}, target=>$nodes{$Inheritance->Child},
			);
      }
  }

    my $relations = $self->Relations;
    if (ref $relations) {
	foreach my $Relation (@$relations) {
	    next unless ($nodes{$Relation->Left});
	    #	warn "relation left :", $Relation->Left, " right :", $Relation->Right, "\n";
	    my %edge_args = (source => $nodes{$Relation->Left}, target => $nodes{$Relation->Right});
	    $vcg->add_edge(%edge_args);      
	}
    }


  unless ($config{skip_packages}) {
      my $components = $self->Components;
      if (ref $components) {
	  foreach my $Component (@$components) {
	      #	warn "component name :", $Component->Name, " id :", $Component->Id, "\n";
	      my $node = $Component->Name;
	      $nodes{$Component->Id} = $node;
	      $vcg->add_node(label=>$node, title=>$node);
	  }
      }
  }

  my $dependancies = $self->Dependancies;
  if (ref $dependancies) {
      foreach my $Dependancy (@$dependancies) {
	  next unless ($nodes{$Dependancy->Parent});
	  #	warn "dependancy parent ", $Dependancy->Parent, " child :", $Dependancy->Child, "\n";
	  $vcg->add_edge(
			 source=>$nodes{$Dependancy->Parent}, target=>$nodes{$Dependancy->Child},
			);
      }
  }

  open (FILE,">$output_filename") or die "couldn't open $output_filename file for output : $!\n";
  binmode FILE;
  eval 'print FILE $vcg->'. $vcg_filetypes{$extension} or die "can't eval : $! \n";;

  close FILE;

  return 1;
}


####################################################
# export_xml - output to file via template toolkit


sub export_xml
{
    my $self            = shift;

    my %config          = %{$self->{_config}};

    my $output_filename = $config{outputfile};
    my $template_file   = $config{templatefile} || get_template(%config);

    if ($config{no_deps})
      { $self->_no_deps; }

    my $success = $self->_layout_dia_new;
    return 0 unless $success;

    if (ref $self->Classes) {
      foreach my $Class ( @{$self->Classes} ) {

#	warn "handling $Class->{name}\n";

 	my ($methods) = ($Class->Operations);
	foreach my $method (@$methods) {
	  $method->{name}=xml_escape($method->{name});
	  if (ref $method->{"Params"} ) {
	    foreach my $argument ( @{$method->{"Params"}} ) {
		$argument->{Type} = xml_escape($argument->{Type}) if (defined $argument->{Type});
		$argument->{Name} = xml_escape($argument->{Name});
		$argument->{Kind} = xml_escape($argument->{Kind}) if (defined $argument->{Kind});
	    }
	  }
	}

	my ($attributes) = ($Class->Attributes);
	foreach my $attribute (@$attributes) {
	  $attribute->{name} = xml_escape($attribute->{name});
	}
      }
    }

    print "\n\n" if ($config{use_stdout});

    # use a template for xml output.
    my $template_conf = {
			 POST_CHOMP   => 1,
			 # EVAL_PERL => 1,  # debug
			 # INTERPOLATE =>1, # debug
			 # LOAD_PERL => 1,  # debug
			 ABSOLUTE => 1,
			 OUTPUT_PATH => '.',
		 }; # cleanup whitespace and allow absolute paths
    my $template = Template->new($template_conf);
    my $template_variables = { "diagram" => $self, config => $self->{_config}};

    my @template_args = ($template_file,$template_variables);
    push (@template_args, $output_filename)
      unless ( $config{use_stdout} );

    $template->process(@template_args)
	|| die $template->error();

    return 1;
}

#---------------------------------------------------------------------------------
# Internal Methods

sub _no_deps
  {
    my $self = shift;
    print STDERR "skipping dependancies..\n";
    undef $self->{packages}{dependancy};
    undef $self->{packages}{Component};
    return;
  }

sub _initialise
  {
    my $self = shift;
    $self->{_config} = shift; # ref to %conf
    $self->{"_object_count"} = 0; # keeps count of objects
    $self->{_nodes} = {};
    return;
  }

sub _package_exists # check to see if a package already exists
  {
    my $self = shift;
    my $object = shift;
    my $return = 0;

    # check type of object, and only check for relevent packages.
  SWITCH:
    {
      if ($object->Type eq "class")
	{
	  last SWITCH;
	}
      if ($object->Type eq "superclass")
	{

	  if ($self->{"packages"}{"superclass"}{$object->Name})
	    {
	      $return = $self->{"packages"}{"superclass"}{$object->Name};
	      bless ($return, "Autodia::Diagram::Superclass");
	    }
	  last SWITCH;
	}
       if ($object->Type eq "Component")
	{
	  if ($self->{"packages"}{"Component"}{$object->Name})
	    {
	      $return = $self->{"packages"}{"Component"}{$object->Name};
	      bless ($return, "Autodia::Diagram::Component");
	    }
	  last SWITCH;
	}
    }
    return $return;
  }

sub _object_count
{
    my $self = shift;
    my $id = $self->{"_object_count"};
    $self->{"_object_count"}++;
    return $id;
}

sub _package_add
  {
    my $self = shift;
    my $new_package = shift;
    my @packages;

    if (defined $self->{$new_package->Type})
      { @packages = @{$self->{$new_package->Type}}; }

    push(@packages, $self->{"_object_count"});

    $self->{$new_package->Type} = \@packages;
    $new_package->LocalId(scalar @packages);
    $self->{"packages"}{$new_package->Type}{$new_package->Name} = $new_package;
    if (defined $new_package->Type && defined $new_package->Id) {
	$self->{"package_types"}{$new_package->Type}{$new_package->Id} = 1;
    }

    return 1;
  }

sub _package_remove
  {
    my $self = shift;
    my $package = shift;

    my @packages = @{$self->{$package->Type}};
    $packages[$package->LocalId] = "removed";

    $self->{$package->Type} = \@packages;
    delete $self->{"packages"}{$package->Type}{$package->Name};

    return 1;
  }


sub _get_childless_classes
  {
    my $self = shift;
    my @classes;

    my $childless = $self->Classes;
    if (ref $childless)
      {
	foreach my $class (@$childless)
	  {
	    unless ($class->has_child)
	      { push (@classes, $class); }
	  }
      }
    else { warn "Diagram.pm : _get_childless_classes : no classes!\n"; }
    return @classes;
  }

sub _get_parent_classes
  {
    my $self = shift;
    my @classes;

    my $parents = $self->Classes;
    if (ref $parents)
      {
	foreach my $class (@$parents)
	  {
	    if ($class->has_child)
	      { push (@classes, $class); }
	  }
      }
    else { warn "Diagram.pm : _get_parent_classes : no classes !\n"; }
    return @classes;
  }

sub _sort
  {
    my $self = shift;
    my @classes = @{shift()};

    print "sorting classes alphabetically\n" unless ( $self->{config}->{silent} );
    my @sorted_classes = sort {$a->Name cmp $b->Name} @classes;

    return \@sorted_classes
  }


# now returns 0 if no classes found

sub _layout_dia_new {
  my $self = shift;
  my %config = %{$self->{_config}};
  # build table of nodes and relationships
  my %nodes = ();
  my @edges = ();
  my @rows  = ();
  my @row_heights = ();
  my @row_widths = ();
  # - add classes nodes
  my $classes = $self->Classes;
  if (ref $classes) {
    foreach my $Class (@$classes) {
      # count methods and attributes to give height
      my $height = 23;
      my $width = 3 + ( (length ($Class->Name) - 3) * 0.75 );
      my ($methods) = ($Class->Operations);
      if (uc(ref $methods) eq 'SCALAR') {
	$height += scalar @$methods;
      }
      if ($config{attributes}) {
	my ($attributes) = ($Class->Attributes);
	if (uc(ref $attributes) eq 'SCALAR') {
	  $height += (scalar @$attributes * 3.2);
	}
      }
#      warn "creating node for class : ", $Class->Id, "\n";
      $nodes{$Class->Id} = {parents=>[], weight=>0, center=>[], height=>$height,
			    children=>[], entity=>$Class, width=>$width};
    }
  }
  # - add superclasses nodes
  my $superclasses = $self->Superclasses;
  if (ref $superclasses) {
    foreach my $Superclass (@$superclasses) {
      my $width = 3 + ( (length ($Superclass->Name) - 3) * 0.75 );
#      warn "creating node for class : ", $Superclass->Id, "\n";
      $nodes{$Superclass->Id} = {parents=>[], weight=>0, center=>[], height=>15,
				 children=>[], entity=>$Superclass, width=>$width};
    }
  }
  # - add package nodes
  my $components = $self->Components;
  if (ref $components) {
    foreach my $Component (@$components) {
#      warn "creating node for class : ", $Component->Id, "\n";
      my $width = 3 + ( (length ($Component->Name) - 3) * 0.55 );
      $nodes{$Component->Id} = {parents=>[], weight=>0, center=>[], height=>15,
				children=>[], entity=>$Component, width=>$width};
    }
  }
  # - add inheritance edges
  my $inheritances = $self->Inheritances;
  if (ref $inheritances) {
    foreach my $Inheritance (@$inheritances) {
      push (@edges, { to => $Inheritance->Child, from => $Inheritance->Parent  });
    }
  }
  # - add dependancy edges
  my $dependancies = $self->Dependancies;
  if (ref $dependancies) {
    foreach my $Dependancy (@$dependancies) {
      push (@edges, { to => $Dependancy->Child, from => $Dependancy->Parent  });
    }
  }

   # add realization edges
   my $realizations = $self->Realizations;
   if( ref $realizations ) {
     foreach my $Realization (@$realizations) {
       push( @edges,
         { to => $Realization->Child, from => $Realization->Parent } );
     }
   }


  # add relation edges
  my $relations = $self->Relations;
  if (ref $relations) {
    foreach my $Relation (@$relations) {
      push (@edges, { to => $Relation->Left, from => $Relation->Right  });
    }
  }

  # first pass (build network of edges to and from each node)
  foreach my $edge (@edges) {
#    warn Dumper (edge=>$edge) unless ($edge->{from} && $edge->{to});
    my ($from,$to) = ($edge->{from},$edge->{to});
    push(@{$nodes{$to}{parents}},$from);
    push(@{$nodes{$from}{children}},$to);
  }

  # second pass (establish depth ( ie verticle placement of each node )
  foreach my $node (keys %nodes) {
    my $depth = 0;
    foreach my $parent (@{$nodes{$node}{parents}}) {
      my $newdepth = get_depth($parent,$node,\%nodes);
      $depth = $newdepth if ($depth < $newdepth);
    }
    $nodes{$node}{depth} = $depth;
    push(@{$rows[$depth]},$node)
  }

  # calculate height and width of diagram in discrete steps
  my $i = 0;
  my $widest_row = 0;
  my $total_height = 0;
  my $total_width = 0;
  foreach my $row (@rows) {
    unless (ref $row) { $row = []; next }
    my $tallest_node_height = 0;
    my $widest_node_width = 0;
    $widest_row = scalar @$row if ( scalar @$row > $widest_row );
    my @newrow = ();
    foreach my $node (@$row) {
#      warn Dumper(node=>$node);
      unless (defined $node && defined $nodes{$node}) { warn "warning : empty class/package encountered, skipping"; Dumper(empty_node=>$nodes{$node}); next;}
      $tallest_node_height = $nodes{$node}{height} 
	if ($nodes{$node}{height} > $tallest_node_height);
      $widest_node_width = $nodes{$node}{width}
	if ($nodes{$node}{width} > $widest_node_width);
      push (@newrow,$node);
    }
    $row = \@newrow;
    $row_heights[$i] = $tallest_node_height + 0.5;
    $row_widths[$i] = $widest_node_width;
    $total_height += $tallest_node_height + 0.5 ;
    $total_width += $widest_node_width;
    $i++;
  }

  # prepare table of available positions
  my @positions;
  foreach (@rows) {
    my %available;
    @available{(0 .. ($widest_row + 1))} = 1 x ($widest_row + 1);
    push (@positions,\%available);
  }

  my %done = ();
  $self->{_dia_done} = \%done;
  $self->{_dia_nodes} = \%nodes;
  $self->{_dia_positions} = \@positions;
  $self->{_dia_rows} = \@rows;
  $self->{_dia_row_heights} = \@row_heights;
  $self->{_dia_row_widths} = \@row_widths;
  $self->{_dia_total_height} = $total_height;
  $self->{_dia_total_width} = $total_width;
  $self->{_dia_widest_row} = $widest_row;

  #
  # plot (relative) position of nodes (left to right, follow branch)
  my $side;
  return 0 unless (ref $rows[0]);
  my @toprow = sort {$nodes{$b}{weight} <=> $nodes{$a}{weight} } @{$rows[0]};
  unshift (@toprow, pop(@toprow)) unless (scalar @toprow < 3);
  my $increment = $widest_row / ( scalar @toprow + 1 );
  my $pos = $increment;
  my $y = 0 - ( ( $self->{_dia_total_height} / 2) - 5 );
  my $done2ndrow = 0;
  foreach my $node ( @toprow ) {
      my $x = 0 - ( $self->{_dia_row_widths}[0] * $self->{_dia_widest_row} / 2)
	  + ($pos * $self->{_dia_row_widths}[0]);
      $nodes{$node}{xx} = $x;
      $nodes{$node}{yy} = $y;
      $nodes{$node}{entity}->set_location($x,$y);
      #      if (scalar @{$nodes{$node}{children}} && ( scalar @{$rows[1]} > 0)) {
      if (defined $nodes{$node}{children} && defined $rows[1]) {
	  if (scalar @{$nodes{$node}{children}} && scalar(@rows) && ( scalar @{$rows[1]} > 0)) {

	      my @sorted_children = sort {
		  $nodes{$b}{weight} <=> $nodes{$a}{weight}
	      } @{$nodes{$node}{children}};
	      unshift (@sorted_children, pop(@sorted_children));
	      my $child_increment = $widest_row / (scalar @{$rows[1]});
	      my $childpos = $child_increment;
	      #      foreach my $child (@{$nodes{$node}{children}}) {
	      foreach my $child (@sorted_children) {
		  my $side;
		  if ($childpos <= ( $widest_row * 0.385 ) ) {
		      $side = 'left';
		  } elsif ( $childpos <= ($widest_row * 0.615 ) ) {
		      $side = 'center';
		  } else {
		      $side = 'right';
		  }
		  plot_branch($self,$nodes{$child},$childpos,$side);
		  $childpos += $child_increment;
	      }
	  } elsif ( defined $rows[1] && scalar @{$rows[1]} && $done2ndrow == 0) {
	      $done2ndrow = 1;
	      foreach my $node ( @{$rows[1]} ) {
		  #		warn "handling node in next row\n";
		  #		warn Dumper(node=>$node{$node});
		  my $x = 0 - ( $self->{_dia_row_widths}[1] * $self->{_dia_widest_row} / 2)
		      + ($pos * $self->{_dia_row_widths}[1]);
		  $nodes{$node}{x} = $x;
		  $nodes{$node}{'y'} = $y;
		  if (scalar @{$nodes{$node}{children}} && scalar @{$rows[2]}) {
		      my @sorted_children = sort {
			  $nodes{$b}{weight} <=> $nodes{$a}{weight}
		      } @{$nodes{$node}{children}};
		      unshift (@sorted_children, pop(@sorted_children));
		      my $child_increment = $widest_row / (scalar @{$rows[2]});
		      my $childpos = $child_increment;
		      #      foreach my $child (@{$nodes{$node}{children}}) {
		      foreach my $child (@sorted_children) {
			  #			warn "child : $child\n";
			  next unless ($child);
			  my $side;
			  if ($childpos <= ( $widest_row * 0.385 ) ) {
			      $side = 'left';
			  } elsif ( $childpos <= ($widest_row * 0.615 ) ) {
			      $side = 'center';
			  } else {
			      $side = 'right';
			  }
			  plot_branch($self,$nodes{$child},$childpos,$side);
			  $childpos += $child_increment;
		      }
		  }
	      }
	  }
      }

      $nodes{$node}{pos} = $pos;

      $pos += $increment;
      $done{$node} = 1;
  }
  
  my @relationships = ();

  if (ref $self->Dependancies)
    { push(@relationships, @{$self->Dependancies}); }

  if( ref $self->Realizations ) {
   push( @relationships, @{ $self->Realizations } );}

  if (ref $self->Inheritances)
    { push(@relationships, @{$self->Inheritances}); }

  if (ref $self->Relations)
    { push(@relationships, @{$self->Relations}); }


  foreach my $relationship (@relationships)
    { $relationship->Reposition; }

  $self->{_nodes} = \%nodes;

  return 1;
}

sub object_from_id {
  my ($self, $id) = @_;
  my $object;
  if (ref $self->{_nodes}) {
    $object = $self->{_nodes}{$id}{entity};
  };
  return $object;
}

#
## Functions used by _layout_dia_new method
#

# recursively calculate the depth of a node by following edges to its parents
sub get_depth {
  my ($node,$child,$nodes) = @_;
  my $depth = 0;
  $nodes->{$node}{weight}++;
  if (exists $nodes->{$node}{depth}) {
    $depth = $nodes->{$node}{depth} + 1;
  } else {
    $nodes->{$node}{depth} = 1;
    my @parents = @{$nodes->{$node}{parents}};
    if (scalar @parents > 0) {
      foreach my $parent (@parents) {
	my $newdepth = get_depth($parent,$node,$nodes);
	$depth = $newdepth if ($depth < $newdepth);
      }
      $depth++;
    } else {
      $depth = 1;
      $nodes->{$node}{depth} = 0;
    }
  }
  return $depth;
}

# recursively plot the branches of a tree
sub plot_branch {
  my ($self,$node,$pos,$side) = @_;
#  warn "plotting branch : ", $node->{entity}->Name," , $pos, $side\n";

  my $depth = $node->{depth};
  my $offset = 0.8;
  my $h = 0;
  while ( $h < $depth ) {
    $offset += $self->{_dia_row_heights}[$h++] + 0.1;
  }

#  warn Dumper(node=>$node);
  my (@parents,@children) = ($node->{parents},$node->{children});
  if ( $self->{_dia_done}{$node->{entity}->Id} && (scalar @children < 1) ) {
    if (scalar @parents > 1 ) {
      $self->{_dia_done}{$node}++;
      my $sum = 0;
      foreach my $parent (@parents) {
	return 0 unless (exists $self->{_dia_nodes}{$parent->{entity}->Id}{pos});
	$sum += $self->{_dia_nodes}{$parent->{entity}->Id}{pos};
      }
      $self->{_dia_positions}[$depth]{int($pos)} = 1;
      my $newpos = ( $sum / scalar @parents );
      unless (exists $self->{_dia_positions}[$depth]{int($newpos)}) {
	# use wherever is free if position already taken
	my $best_available = $pos;
	my $diff = ($best_available > $newpos )
	  ? $best_available - $newpos : $newpos - $best_available ;
	foreach my $available (keys %{$self->{_dia_positions}[$depth]}) {
	  my $newdiff = ($available > $newpos ) ? $available - $newpos : $newpos - $available ;
	  if ($newdiff < $diff) {
	    $best_available = $available;
	    $diff = $newdiff;
	  }
	}
	$pos = $best_available;
      } else {
	$pos = $newpos;
      }
    }
    my $y = 0 - ( ( $self->{_dia_total_height} / 2) - 4 ) + $offset;
    print "y : $y\n";
    my $x = 0 - ( $self->{_dia_row_widths}[$depth] * $self->{_dia_widest_row} / 2)
      + ($pos * $self->{_dia_row_widths}[$depth]);
#    my $x = 0 - ( $self->{_dia_widest_row} / 2) + ($pos * $self->{_dia_row_widths}[$depth]);
    $node->{xx} = int($x);
    $node->{yy} = int($y);
    $node->{entity}->set_location($x,$y);
    $node->{pos} = $pos;
    delete $self->{_dia_positions}[$depth]{int($pos)};
#    warn "node ", $node->{entity}->Name(), " : $pos xx : ", $node->{xx} ," yy : ",$node->{yy} ,"\n";
    return 0;
  } elsif ($self->{_dia_done}{$node}) {
#    warn "node ", $node->{entity}->Name(), " : $node->{pos}\n";
    return 0;
  }

  unless (exists $self->{_dia_positions}[$depth]{int($pos)}) {
    my $best_available;
    my $diff = $self->{_dia_widest_row} + 5;
    foreach my $available (keys %{$self->{_dia_positions}[$depth]}) {
      $best_available ||= $available;
      my $newdiff = ($available > $pos ) ? $available - $pos : $pos - $available ;
      if ($newdiff < $diff) {
	$best_available = $available;
	$diff = $newdiff;
      }
    }
    $pos = $best_available;
  }

  delete $self->{_dia_positions}[$depth]{int($pos)};

  my $y = 0 - ( ( $self->{_dia_total_height} / 2) - 1 ) + $offset;
  my $x = 0 - ( $self->{_dia_row_widths}[0] * $self->{_dia_widest_row} / 2)
    + ($pos * $self->{_dia_row_widths}[0]);
#  my $x = 0 - ( $self->{_dia_widest_row} / 2) + ($pos * $self->{_dia_row_widths}[$depth]);
#  my $x = 0 - ( ( $pos * $self->{_dia_row_widths}[0] ) / 2);
  $node->{xx} = int($x);
  $node->{yy} = int($y);
  $node->{entity}->set_location($x,$y);

  $self->{_dia_done}{$node} = 1;
  $node->{pos} = $pos;

  if (scalar @{$node->{children}}) {
    my @sorted_children = sort {
      $self->{_dia_nodes}{$b}{weight} <=> $self->{_dia_nodes}{$a}{weight}
    } @{$node->{children}};
    unshift (@sorted_children, pop(@sorted_children));
    my $child_increment = (ref $self->{_dia_rows}[$depth + 1]) ? $self->{_dia_widest_row} / (scalar @{$self->{_dia_rows}[$depth + 1]} || 1) : 0 ;
    my $childpos = 0;
    if ( $side eq 'left' ) {
      $childpos = 0
    } elsif ( $side eq 'center' ) {
      $childpos = $pos;
    } else {
      $childpos = $pos + $child_increment;
    }
    foreach my $child (@{$node->{children}}) {
      $childpos += $child_increment if (plot_branch($self,$self->{_dia_nodes}{$child},$childpos,$side));
    }
  } elsif ( scalar @parents == 1 ) {
      my $y = 0 - ( ( $self->{_dia_total_height} / 2) - 1 ) + $offset;
      my $x = 0 - ( $self->{_dia_row_widths}[0] * $self->{_dia_widest_row} / 2)
	+ ($pos * $self->{_dia_row_widths}[0]);
#      my $x = 0 - ( $self->{_dia_widest_row} / 2) + ($pos * $self->{_dia_row_widths}[$depth]);
#      my $x = 0 - ( ( $pos * $self->{_dia_row_widths}[0] ) / 2);
      $node->{xx} = int($x);
      $node->{yy} = int($y);
      $node->{entity}->set_location($x,$y);
  }
#  warn "node ", $node->{entity}->Name(), " : $pos xx : ", $node->{xx} ," yy : ",$node->{yy} ,"\n";
  return 1;
}

#
########################################
#

sub _layout {
  my $self = shift;
  my @columns;
  my @orphan_classes;
  my $column_count=0;

  # populate a grid to be used for laying out the diagram.

  # put each parent class in a column
  my @parent_classes = $self->_get_parent_classes;
  my %parent_class;
  foreach my $class (@parent_classes) {
    $parent_class{$class->Id} = $column_count;
    if (defined $columns[$column_count][2][0]) {
      push (@{$columns[$column_count][2]},$class);
    } else {
      $columns[$column_count][2][0] = $class;
    }
    $column_count++;
  }

  $column_count = 0;

  my @childless_classes = $self->_get_childless_classes;
  # put each child class in its parent column
  foreach my $class (@childless_classes) {
    if (defined $class->Inheritances) {
      my ($inheritance) = $class->Inheritances;
      my $parents_column = $parent_class{$inheritance->Parent} || 0;
      push (@{$columns[$parents_column][3]},$class);
    } else {
      push (@orphan_classes,$class);
    }
  }

  $column_count++;

  foreach my $orphan (@orphan_classes) {
    push (@{$columns[$column_count][3]}, $orphan);
  }

  # put components in columns with the most of their kids
  if (ref $self->Components) {
    my @components = @{$self->Components};
    foreach my $component (@components) {
      my $i =0;
      my $current_column = 0;
      my $current_children = 0;
      # find column with most children

      my %child_ids = ();
      my @children = $component->Dependancies;
      foreach my $child (@children) {
	$child_ids{$child->Child} = 1;
      }

      foreach my $column (@columns) {
	if (ref $column) {
	  my @column = @$column;
	  next unless (defined $column);
	  my $children = 0;
	  foreach my $subcolumn (@column) {
	    foreach my $child (@$subcolumn) {
	      if (defined $child_ids{$child->Id}) {
		$children++;
	      }
	    }
	  }
	  if ($children > $current_children) {
	    $current_column = $i; $current_children = $children;
	  }
	  $i++;
	} else {
	  print STDERR "Diagram.pm : _layout() : empty column .. skipping\n";
	}
      }
      push(@{$columns[$current_column][0]},$component);
    }
  } else {
    print STDERR "Diagram.pm : _layout() : no components / dependancies\n";
  }

  if (ref $self->Superclasses) {
    my @superclasses = @{$self->Superclasses};
    # put superclasses in columns with most of their kids
    foreach my $superclass (@superclasses) {
      my $i=0;
      my $current_column = 0;
      my $current_children = 0;
      # find column with most children

      my %child_ids = ();
      my @children = $superclass->Inheritances;
      foreach my $child (@children) {
	$child_ids{$child->Child} = 1;
      }

      foreach my $column (@columns) {
	if (ref $column) {
	  my @column = @$column;
	  my $children = 0;
	  foreach my $subcolumn (@column) {
	    foreach my $child (@$subcolumn) {
	      if (defined $child_ids{$child->Id}) {
		$children++;
	      }
	    }
	  }
	  if ($children > $current_children) {
	    $current_column = $i; $current_children = $children;
	  }
	  $i++;
	} else {
	  print STDERR "Diagram.pm : _layout() : empty column .. skipping\n";
	}
      }
      push(@{$columns[$current_column][1]},$superclass);
    }
  } else {
    print STDERR "Diagram.pm : _layout() : no superclasses / inheritances\n";
  }

  # grid now created - Components in top row, superclasses in second,
  #  classes with subclasses in 3rd row, childless & orphan classes in 4th row.

  # now we position the contents of the grid.
  my $next_row_y = 0;
    my $next_col_x = 0;
    my ($colspace, $rowspace) = (1.5 , 0.5);

  foreach my $column (@columns) {
    my $x = $next_col_x;
    foreach my $subcolumn (@$column) {
      my $count = 0;
      my $y = $next_row_y;
	    $next_row_y += 3;
	    foreach my $entity (@$subcolumn)
	      {
		my $next_xy = $entity->set_location($x,$y);
      ($x,$y) = @$next_xy;
      $x-=3;
      $y-=(2+($entity->Height/5));
      if ($count >= 4) {
	$next_row_y = 0;
		    $y = 0;
		    $x += $colspace;
	$count = 0;
      }
      $count++;
    }
    $y += $rowspace;
  }
  $x += $colspace;
  $next_col_x = $x;
}

my @relationships = ();

    if (ref $self->Dependancies)
      {	push(@relationships, @{$self->Dependancies}); }

    if( ref $self->Realizations ) {
     push( @relationships, @{ $self->Realizations } );}

    if (ref $self->Inheritances)
      { push(@relationships, @{$self->Inheritances}); }

    foreach my $relationship (@relationships)
      { $relationship->Reposition; }

    return 1;
  }

sub xml_escape {
  my $retval = shift;
  return '' unless $retval;

  $retval =~ s/\&/\&amp;/;
  $retval =~ s/\'/\&quot;/;
  $retval =~ s/\"/\&quot;/;
  $retval =~ s/\</\&lt;/;
  $retval =~ s/\>/\&gt;/;

  return $retval;
}


sub get_template {
    my %config = @_;
#    warn "get_template called : outfile -- $config{outputfile}\n";
    my $template;
 TEMPLATE_SWITCH: {
	if ($config{outputfile} =~ /\.xmi$/) {
	    $template = get_umbrello_template($config{outputfile});
	    last TEMPLATE_SWITCH;
	}
	$template = get_default_template($config{outputfile});
    }				# end of TEMPLATE_SWITCH
#    warn "template : ", $template, "\n";
    # NOTE: $template should always be a ref to a string
    return $template;
}

sub get_umbrello_template {
    my $outfile = shift;
    warn "using umbrello template for $outfile\n";
    my $pwd = $ENV{PWD};
    my $template =<<END_UMBRELLO_TEMPLATE;
<?xml version="1.0" encoding="UTF-8"?>
<XMI xmlns:UML="http://schema.omg.org/spec/UML/1.3" verified="false" timestamp="" xmi.version="1.2" >
 <XMI.header>
  <XMI.documentation>
   <XMI.exporter>umbrello uml modeller http://uml.sf.net</XMI.exporter>
   <XMI.exporterVersion>1.1</XMI.exporterVersion>
  </XMI.documentation>
  <XMI.model xmi.name="autodiagenerated-$outfile" href="$pwd/$outfile" />
  <XMI.metamodel xmi.name="UML" href="UML.xml" xmi.version="1.3" />
 </XMI.header>
 <XMI.content>
  <UML:Model isSpecification="false" isLeaf="false" isRoot="false" isAbstract="false" >
   <UML:Namespace.ownedElement>
<!--
    <UML:Stereotype isSpecification="false" isLeaf="false" visibility="public" xmi.id="50000" isRoot="false" isAbstract="false" name="Class" />
    <UML:Stereotype isSpecification="false" isLeaf="false" visibility="public" xmi.id="50001" isRoot="false" isAbstract="false" name="Member_data" />
    <UML:Stereotype isSpecification="false" isLeaf="false" visibility="public" xmi.id="50002" isRoot="false" isAbstract="false" name="Method" />
    <UML:Stereotype isSpecification="false" isLeaf="false" visibility="public" xmi.id="50003" isRoot="false" isAbstract="false" name="Parameter" />
+-->
  [%# -------------------------------------------- %]
  [% classes = diagram.Classes %]
  [% xmictr    = 1 %]
  [% FOREACH class = classes %]
   [% xmictr = xmictr + 1 %]
   <UML:Class stereotype="50000" isSpecification="false" isLeaf="false" visibility="public" xmi.id="[% class.Id %]" isRoot="false" isAbstract="false" name="[% class.Name | html %]" >
    <UML:Classifier.feature>
    [% FOREACH at = class.Attributes %]
    <UML:Attribute isSpecification="false" isLeaf="false" visibility="public" xmi.id="[% at.Id %]" isRoot="false" initialValue="[% at.value %]" type="" isAbstract="false" name="[% at.name | html %]" />
    [% END %]
    [% FOREACH op = class.Operations %]
    <UML:Operation isSpecification="false" isLeaf="false" xmi.id="[% op.Id %]" type="[% op.type | html  %]" isRoot="false" isAbstract="false" name="[% op.name | html  %]" >
     <UML:BehavioralFeature.parameter>
      [% FOREACH par = op.Params %]
      <UML:Parameter isSpecification="false" isLeaf="false" visibility="private" xmi.id="[% par.Id %]" isRoot="false" value="[% par.value %]" type="[% par.type | html  %]" isAbstract="false" name="[% par.name | html %]" />
       [% END %]
     </UML:BehavioralFeature.parameter>
    </UML:Operation>
    [% END %]
    </UML:Classifier.feature>
   </UML:Class>
   [% END %]
   [% SET superclasses = diagram.Superclasses %]
   [% FOREACH superclass = superclasses %]
   <UML:Class stereotype="50000" isSpecification="false" isLeaf="false" visibility="public"  xmi.id="[% superclass.Id %]" isRoot="false" isAbstract="false" name="[% superclass.Name | html  %]" >
   </UML:Class>
   [% END %]
   [% SET components = diagram.Components %]
   [% FOREACH component = components %]
   <UML:Class stereotype="50000" isSpecification="false" isLeaf="false" visibility="public"  xmi.id="[% component.Id %]" isRoot="false" isAbstract="false" name="[% component.Name | html  %]" >
      [% FOREACH at = class.Attributes %]
      [% xmictr = xmictr + 1 %]
      <UML:Attribute stereotype="" package="" xmi.id="[% xmictr %]" value="[% at.value %]" type="[% at.type FILTER html %]" abstract="0"
documentation="" name="[% at.name FILTER html %]" static="0" scope="200" />
      [% END %]
      [% FOREACH op = class.Operations %]
      [% xmictr = xmictr + 1 %]
      <UML:Operation stereotype="" package="" xmi.id="[% xmictr %]" type="[% op.type %]" abstract="0" documentation="" name="[% op.name %]" static="0" scope="200" >
         [% FOREACH par = op.Params %]
         [% xmictr = xmictr + 1 %]
         <UML:Parameter stereotype="" package="" xmi.id="[% xmictr %]" value="[% par.value %]" type="[% par.type  FILTER html %]" abstract="0" documentation="" name="[% par.Name FILTER html %]" static="0" scope="200" />
         [% END %]
      </UML:Operation>
      [% END %]
   </UML:Class>
   [% END %]
    [% SET inheritances = diagram.Inheritances %]
    [% FOREACH inheritance = inheritances %]
      [%- IF inheritance.Parent >0 AND inheritance.Child >0 -%]
<!--
    <UML:Association isSpecification="false" visibility="public" xmi.id="9" name="" >
     <UML:Association.connection>
      <UML:AssociationEnd isSpecification="false" visibility="public" changeability="changeable" isNavigable="false" xmi.id="[% inheritance.Parent %]" aggregation="none" type="95" name="" />
      <UML:AssociationEnd isSpecification="false" visibility="public" changeability="changeable" isNavigable="true" xmi.id="[% inheritance.Child %]" aggregation="none" type="407" name="" />
     </UML:Association.connection>
    </UML:Association>
-->
    <UML:Generalization isSpecification="false" child="[% inheritance.Child %]" visibility="public" xmi.id="[% inheritance.Id %]" parent="[% inheritance.Parent %]" discriminator="" name="" />
     [%- END %]
    [% END %]
    [% SET dependencies = diagram.Dependancies %]
    [% FOREACH dependency = dependencies %]
    <UML:Dependency isSpecification="false" visibility="public" xmi.id="[% dependency.Id %]" client="[% dependency.Child %]" name="" supplier="[% dependency.Parent %]" />
    [% END %]
   </UML:Namespace.ownedElement>
  </UML:Model>
 </XMI.content>
  <XMI.extensions xmi.extender="umbrello" >
   <docsettings viewid="2" documentation="" uniqueid="4" />
   <diagrams>
    <diagram snapgrid="0" showattsig="1" fillcolor="#ffffc0" linewidth="0" zoom="100" showgrid="0" showopsig="1" usefillcolor="1" snapx="10" canvaswidth="989" snapy="10" showatts="1"
                         xmi.id="2" documentation="" type="402" showops="1" showpackage="0" name="class diagram" localid="30000"
                         showstereotype="0" showscope="1" snapcsgrid="0" font="Sans,10,-1,5,50,0,0,0,0,0" linecolor="#ff0000" canvasheight="632" >


    <widgets>
    [%# -------------------------------------------- %]
    [% classes = diagram.Classes %]
    [% FOREACH class = classes %]
     <classwidget usesdiagramfillcolour="0" width="[% class.Width %]" showattsigs="601" usesdiagramusefillcolour="0"
                        x="[% class.left_x %]" linecolour="#ff0000" y="[% class.top_y %]" showopsigs="601" linewidth="none" usesdiagramlinewidth="1" usesdiagramlinecolour="0"
                        fillcolour="#ffffc0" height="[% class.Height %]" usefillcolor="1" showpubliconly="0" showattributes="1" isinstance="0" xmi.id="[% class.Id %]"
                        showoperations="1" showpackage="0" showscope="1" showstereotype="0" font="Sans,10,-1,5,50,0,0,0,0,0" />
    [% END %]
    [% SET superclasses = diagram.Superclasses %]
    [% FOREACH class = superclasses %]
    [% xmictr = xmictr + 1 %]
     <UML:ConceptWidget usesdiagramfillcolour="0" width="[% class.Width %]" showattsigs="601" usesdiagramusefillcolour="0" 
                        x="[% class.left_x %]" linecolour="#ff0000" y="[% class.top_y %]" showopsigs="601" usesdiagramlinecolour="0" 
                        fillcolour="#ffffc0" height="[% class.Height %]" usefillcolor="1" showattributes="1" xmi.id="[% xmictr %]" 
                        showoperations="1" showpackage="0" showscope="1" showstereotype="0" font="Sans,10,-1,5,50,0,0,0,0,0" />

    [% END %]
    </widgets>
    <messages/>
    <associations>
    [% SET inheritances = diagram.Inheritances %]
    [% FOREACH inheritance = inheritances %]
     [%- IF inheritance.Parent >0 AND inheritance.Child >0 -%]
     <assocwidget totalcounta="2" indexa="1" totalcountb="2" indexb="1" widgetbid="[% inheritance.Parent %]" widgetaid="[% inheritance.Child %]" xmi.id="[% inheritance.Id %]" >
      <linepath>
       <startpoint startx="[% inheritance.left_x %]" starty="[% inheritance.top_y %]" />
       <endpoint endx="[% inheritance.right_x %]" endy="[% inheritance.bottom_y %]" />
      </linepath>
     </assocwidget>
     [%- END %]
    [% END %]
    [% SET dependencies = diagram.Dependancies %]
    [% FOREACH dependency = dependencies %]
      [%- IF dependency.Parent >0 AND dependency.Child >0 -%]
     <assocwidget totalcounta="2" indexa="1" totalcountb="2" indexb="1" widgetbid="[% dependency.Parent %]" widgetaid="[% dependency.Child %]" xmi.id="[% dependency.Id %]" >
      <linepath>
       <startpoint startx="[% dependency.left_x %]" starty="[% dependency.top_y %]" />
       <endpoint endx="[% dependency.right_x %]" endy="[% dependency.bottom_y %]" />
      </linepath>
     </assocwidget>
     [%- END %]
    [% END %]
    </associations>
   </diagram>
  </diagrams>
  <listview>
   <listitem open="1" type="800" id="-1" label="Views" >
    <listitem open="1" type="801" id="-1" label="Logical View" >
     <listitem open="0" type="807" id="2" label="class diagram" />
    </listitem>
    <listitem open="1" type="802" id="-1" label="Use Case View" />
    <listitem open="1" type="821" id="-1" label="Component View" />
    <listitem open="1" type="827" id="-1" label="Deployment View" />
   </listitem>
  </listview>
 </XMI.extensions>
</XMI>
END_UMBRELLO_TEMPLATE
    return \$template;
}

sub get_default_template {
    warn "using default (dia) template\n";
    my $template = <<'END_TEMPLATE';
<?xml version="1.0"?>
[%# #################################################### %]
[%# Autodia Template for Dia XML. (c)Copyright 2001-2004 %]
[%# #################################################### %]
<dia:diagram xmlns:dia="http://www.lysator.liu.se/~alla/dia/">
  <dia:diagramdata>
    <dia:attribute name="background">
      <dia:color val="#ffffff"/>
    </dia:attribute>
    <dia:attribute name="paper">
      <dia:composite type="paper">
        <dia:attribute name="name">
          <dia:string>#A4#</dia:string>
        </dia:attribute>
        <dia:attribute name="tmargin">
          <dia:real val="2.82"/>
        </dia:attribute>
        <dia:attribute name="bmargin">
          <dia:real val="2.82"/>
        </dia:attribute>
        <dia:attribute name="lmargin">
          <dia:real val="2.82"/>
        </dia:attribute>
        <dia:attribute name="rmargin">
          <dia:real val="2.82"/>
        </dia:attribute>
        <dia:attribute name="is_portrait">
          <dia:boolean val="true"/>
        </dia:attribute>
        <dia:attribute name="scaling">
          <dia:real val="1"/>
        </dia:attribute>
        <dia:attribute name="fitto">
          <dia:boolean val="false"/>
        </dia:attribute>
      </dia:composite>
    </dia:attribute>
    <dia:attribute name="grid">
      <dia:composite type="grid">
        <dia:attribute name="width_x">
          <dia:real val="1"/>
        </dia:attribute>
        <dia:attribute name="width_y">
          <dia:real val="1"/>
        </dia:attribute>
        <dia:attribute name="visible_x">
          <dia:int val="1"/>
        </dia:attribute>
        <dia:attribute name="visible_y">
          <dia:int val="1"/>
        </dia:attribute>
      </dia:composite>
    </dia:attribute>
    <dia:attribute name="guides">
      <dia:composite type="guides">
        <dia:attribute name="hguides"/>
        <dia:attribute name="vguides"/>
      </dia:composite>
    </dia:attribute>
  </dia:diagramdata>
  <dia:layer name="Background" visible="true">
[%# -------------------------------------------- %]
[% classes = diagram.Classes %]
[% FOREACH class = classes %]
    <dia:object type="UML - Class" version="0" id="O[% class.Id %]">
      <dia:attribute name="obj_pos">
        <dia:point val="[% class.TopLeftPos %]"/>
      </dia:attribute>
      <dia:attribute name="obj_bb">
        <dia:rectangle val="[% class.TopLeftPos %];[% class.BottomRightPos %]"/>
      </dia:attribute>
      <dia:attribute name="elem_corner">
        <dia:point val="[% class.TopLeftPos %]"/>
      </dia:attribute>
      <dia:attribute name="elem_width">
        <dia:real val="[% class.Width %]"/>
      </dia:attribute>
      <dia:attribute name="elem_height">
        <dia:real val="[% class.Height %]"/>
      </dia:attribute>
      <dia:attribute name="name">
        <dia:string>#[% class.Name | html  %]#</dia:string>
      </dia:attribute>
      <dia:attribute name="stereotype">
      [% IF class.Parent %]
        <dia:string>#[% class.Parent | html %]#</dia:string>
      [% ELSE %]
        <dia:string/>
      [% END %]
      </dia:attribute>
      <dia:attribute name="abstract">
        <dia:boolean val="false"/>
      </dia:attribute>
      <dia:attribute name="suppress_attributes">
        <dia:boolean val="false"/>
      </dia:attribute>
      <dia:attribute name="suppress_operations">
        <dia:boolean val="false"/>
      </dia:attribute>
      <dia:attribute name="visible_attributes">
        <dia:boolean val="true"/>
      </dia:attribute>
      <dia:attribute name="visible_operations">
        <dia:boolean val="true"/>
      </dia:attribute>
      <dia:attribute name="foreground_color">
        <dia:color val="#000000"/>
      </dia:attribute>
      <dia:attribute name="background_color">
        <dia:color val="#ffffff"/>
      </dia:attribute>

      [% IF class.Attributes %]
      <dia:attribute name="attributes">
        [% FOREACH at = class.Attributes %]
        <dia:composite type="umlattribute">
          <dia:attribute name="name">
            <dia:string>#[% at.name FILTER html %]#</dia:string>
          </dia:attribute>
          <dia:attribute name="type">
            <dia:string>#[% at.type FILTER html %]#</dia:string>
          </dia:attribute>
          <dia:attribute name="value">
            <dia:string>[% at.value | html %]</dia:string>
          </dia:attribute>
          <dia:attribute name="visibility">
            <dia:enum val="[% at.visibility %]"/>
          </dia:attribute>
          <dia:attribute name="abstract">
            <dia:boolean val="false"/>
          </dia:attribute>
          <dia:attribute name="class_scope">
            <dia:boolean val="false"/>
          </dia:attribute>
        </dia:composite>
        [% END %]
      </dia:attribute>
      [% ELSE %]
      <dia:attribute name = "attributes"/>
      [% END %]
      [% IF class.Operations %]
      <dia:attribute name="operations">
        [% FOREACH op = class.Operations %]
        <dia:composite type="umloperation">
          <dia:attribute name="name">
            <dia:string>#[% op.name FILTER html %]#</dia:string>
          </dia:attribute>
          <dia:attribute name="type">
	  [% IF op.type %]
            <dia:string>#[% op.type  FILTER html %]#</dia:string>
	  [% ELSE %]
	     <dia:string/>
	  [% END %]
          </dia:attribute>
          <dia:attribute name="visibility">
            <dia:enum val="[% op.visibility %]"/>
          </dia:attribute>
          <dia:attribute name="abstract">
            <dia:boolean val="false"/>
          </dia:attribute>
          <dia:attribute name="class_scope">
            <dia:boolean val="false"/>
          </dia:attribute>
	  [% IF op.Params.0 %]
          <dia:attribute name="parameters">
            [% FOREACH par = op.Params %] 
            <dia:composite type="umlparameter">
              <dia:attribute name="name">
                <dia:string>#[% par.Name FILTER html %]#</dia:string>
              </dia:attribute>
              <dia:attribute name="type">
                <dia:string>#[% par.Type FILTER html %]#</dia:string>
              </dia:attribute>
              <dia:attribute name="value">
             [% IF par.Value %]
                <dia:enum val="[% par.Value %]"/>
             [% ELSE %]
                 <dia:enum val="0"/>
              [% END %]
              </dia:attribute>
              <dia:attribute name="kind">
             [% IF par.Kind %]
                <dia:enum val="[% par.Kind %]"/>
             [% ELSE %]
                 <dia:enum val="0"/>
              [% END %]
              </dia:attribute>
            </dia:composite>
            [% END %]
          </dia:attribute>
	  [% ELSE %]
	  <dia:attribute name = "parameters"/>
	  [% END %]
        </dia:composite>
        [% END %]
      </dia:attribute>
      [% ELSE %]
      <dia:attribute name="operations"/>
      [% END %]
      <dia:attribute name="template">
        <dia:boolean val="false"/>
      </dia:attribute>
      <dia:attribute name="templates"/>
    </dia:object>
[% END %]
[%#%]
[% UNLESS config.skip_packages %]
[% SET components = diagram.Components %]
[%#%]
[% FOREACH component = components %]
 <dia:object type="UML - SmallPackage" version="0" id="O[% component.Id %]">
   <dia:attribute name="obj_pos">
       <dia:point val="[% component.TopLeftPos %]"/>
   </dia:attribute>
   <dia:attribute name="obj_bb">
       <dia:rectangle val="[% component.TopLeftPos %];[% component.BottomRightPos %]"/>
   </dia:attribute>
   <dia:attribute name="elem_corner">
      <dia:point val="[% component.TopLeftPos %]"/>
   </dia:attribute>
   <dia:attribute name="elem_width">
      <dia:real val="component.Width"/>
   </dia:attribute>
   <dia:attribute name="elem_height">
      <dia:real val="component.Height"/>
   </dia:attribute>
   <dia:attribute name="text">
     <dia:composite type="text">
       <dia:attribute name="string">
         <dia:string>#[% component.Name | html %]#</dia:string>
       </dia:attribute>
       <dia:attribute name="font">
         <dia:font name="Courier"/>
       </dia:attribute>
       <dia:attribute name="height">
          <dia:real val="0.8"/>
       </dia:attribute>
       <dia:attribute name="pos">
          <dia:point val="[% component.TextPos %]"/>
       </dia:attribute>
       <dia:attribute name="color">
          <dia:color val="#000000"/>
       </dia:attribute>
       <dia:attribute name="alignment">
          <dia:enum val="0"/>
       </dia:attribute>
     </dia:composite>
   </dia:attribute>
 </dia:object>
[% END %]
[% # %]
[% SET realizations = diagram.Realizations %]
[% # %]
[% FOREACH realization = realizations %]
 <dia:object type="UML - Realizes" version="0" id="O[% realization.Id %]">
   <dia:attribute name="obj_pos">
     <dia:point val="[% realization.Orth_Top_Right %]"/>
   </dia:attribute>
   <dia:attribute name="obj_bb">
     <dia:rectangle val="[% realization.Orth_Top_Right %];[% realization.Orth_Bottom_Left %]"/>
   </dia:attribute>
   <dia:attribute name="orth_points">
     <dia:point val="[% realization.Orth_Bottom_Left%]"/>
     <dia:point val="[% realization.Orth_Mid_Left %]"/>
     <dia:point val="[% realization.Orth_Mid_Right %]"/>
     <dia:point val="[% realization.Orth_Top_Right%]"/>
   </dia:attribute>
   <dia:attribute name="orth_orient">
     <dia:enum val="1"/>
     <dia:enum val="0"/>
     <dia:enum val="1"/>
   </dia:attribute>
   <dia:attribute name="draw_arrow">
     <dia:boolean val="true"/>
   </dia:attribute>
   <dia:attribute name="name">
     <dia:string/>
   </dia:attribute>
   <dia:attribute name="stereotype">
     <dia:string/>
   </dia:attribute>
   <dia:connections>
     <dia:connection handle="1" to="O[% realization.Child %]" connection="6"/>
     <dia:connection handle="0" to="O[% realization.Parent %]" connection="1"/>
   </dia:connections>
 </dia:object>
[% END %]
[% # %]
[% SET dependancies = diagram.Dependancies %]
[% # %]
[% FOREACH dependancy = dependancies %]
 <dia:object type="UML - Dependency" version="0" id="O[% dependancy.Id %]">
   <dia:attribute name="obj_pos">
     <dia:point val="[% dependancy.Orth_Top_Right %]"/>
   </dia:attribute>
   <dia:attribute name="obj_bb">
     <dia:rectangle val="[% dependancy.Orth_Top_Right %];[% dependancy.Orth_Bottom_Left %]"/>
   </dia:attribute>
   <dia:attribute name="orth_points">
     <dia:point val="[% dependancy.Orth_Bottom_Left%]"/>
     <dia:point val="[% dependancy.Orth_Mid_Left %]"/>
     <dia:point val="[% dependancy.Orth_Mid_Right %]"/>
     <dia:point val="[% dependancy.Orth_Top_Right%]"/>
   </dia:attribute>
   <dia:attribute name="orth_orient">
     <dia:enum val="1"/>
     <dia:enum val="0"/>
     <dia:enum val="1"/>
   </dia:attribute>
   <dia:attribute name="draw_arrow">
     <dia:boolean val="true"/>
   </dia:attribute>
   <dia:attribute name="name">
     <dia:string/>
   </dia:attribute>
   <dia:attribute name="stereotype">
     <dia:string/>
   </dia:attribute>
   <dia:connections>
     <dia:connection handle="1" to="O[% dependancy.Parent %]" connection="6"/>
     <dia:connection handle="0" to="O[% dependancy.Child %]" connection="1"/>
   </dia:connections>
 </dia:object>
[% END %]
[% END %]
[% # %]
[% UNLESS config.skip_superclasses %]
[% SET superclasses = diagram.Superclasses %]
[% # %]
[% FOREACH superclass = superclasses %]
 <dia:object type="UML - Class" version="0" id="O[% superclass.Id %]">
   <dia:attribute name="obj_pos">
     <dia:point val="[% superclass.TopLeftPos %]"/>
   </dia:attribute>
   <dia:attribute name="obj_bb">
     <dia:rectangle val="[% superclass.TopLeftPos %];[% superclass.BottomRightPos %]"/>
   </dia:attribute>
   <dia:attribute name="elem_corner">
     <dia:point val="[% superclass.TopLeftPos %]"/>
   </dia:attribute>
   <dia:attribute name="elem_width">
     <dia:real val="[% superclass.Width %]"/>
   </dia:attribute>
   <dia:attribute name="elem_height">
     <dia:real val="[% superclass.Height %]"/>
   </dia:attribute>
   <dia:attribute name="name">
     <dia:string>#[% superclass.Name  %]#</dia:string>
   </dia:attribute>
   <dia:attribute name="stereotype">
     <dia:string/>
   </dia:attribute>
   <dia:attribute name="abstract">
     <dia:boolean val="false"/>
   </dia:attribute>
   <dia:attribute name="suppress_attributes">
     <dia:boolean val="false"/>
   </dia:attribute>
   <dia:attribute name="suppress_operations">
     <dia:boolean val="false"/>
   </dia:attribute>
   <dia:attribute name="visible_attributes">
     <dia:boolean val="true"/>
   </dia:attribute>
   <dia:attribute name="visible_operations">
     <dia:boolean val="true"/>
   </dia:attribute>
   <dia:attribute name="attributes"/>
   <dia:attribute name="operations"/>
   <dia:attribute name="template">
     <dia:boolean val="false"/>
   </dia:attribute>
   <dia:attribute name="templates"/>
 </dia:object>
[% END %]
[% END %]
[% #### %]
[% SET inheritances = diagram.Inheritances %]
[% FOREACH inheritance = inheritances %]
 [% IF config.skip_superclasses %]
   [% SET parent = inheritance.Parent %]
   [% UNLESS diagram.package_types.class.$parent %] [% NEXT %] [% END %]
 [% END %]
 <dia:object type="UML - Generalization" version="0" id="O[% inheritance.Id  %]">
   <dia:attribute name="obj_pos">
     <dia:point val="[% inheritance.Orth_Top_Left %]"/>
   </dia:attribute>
   <dia:attribute name="obj_bb">
     <dia:rectangle val="[% inheritance.Orth_Top_Left %];[% inheritance.Orth_Bottom_Right %]"/>
   </dia:attribute>
   <dia:attribute name="orth_points">
     <dia:point val="[% inheritance.Orth_Top_Left %]"/>
     <dia:point val="[% inheritance.Orth_Mid_Left %]"/>
     <dia:point val="[% inheritance.Orth_Mid_Right %]"/>
     <dia:point val="[% inheritance.Orth_Bottom_Right %]"/>
   </dia:attribute>
   <dia:attribute name="orth_orient">
     <dia:enum val="1"/>
     <dia:enum val="0"/>
     <dia:enum val="1"/>
   </dia:attribute>
   <dia:attribute name="autorouting">
      <dia:boolean val="true"/>
   </dia:attribute>
   <dia:attribute name="name">
     <dia:string/>
   </dia:attribute>
   <dia:attribute name="stereotype">
      <dia:string/>
   </dia:attribute>
   <dia:connections>
     <dia:connection handle="0" to="O[% inheritance.Parent %]" connection="6"/>
     <dia:connection handle="1" to="O[% inheritance.Child %]" connection="1"/>
    </dia:connections>
 </dia:object>
[% END %]

[% SET relations = diagram.Relations %]
[% FOREACH relation = relations %]
    <dia:object type="UML - Association" version="1" id="[% relation.Id %]">
      <dia:attribute name="obj_pos">
        <dia:point val="[% relation.Orth_Top_Left %]"/>
      </dia:attribute>
      <dia:attribute name="obj_bb">
        <dia:rectangle val="[% relation.Orth_Top_Left %];[% relation.Orth_Bottom_Right %]"/>
      </dia:attribute>
      <dia:attribute name="orth_points">
        <dia:point val="[% relation.Orth_Mid_Left %]"/>
        <dia:point val="[% relation.Orth_Top_Left %]"/>
        <dia:point val="[% relation.Orth_Bottom_Right %]"/>
        <dia:point val="[% relation.Orth_Mid_Right %]"/>
      </dia:attribute>
      <dia:attribute name="orth_orient">
         <dia:enum val="0"/>
         <dia:enum val="1"/>
         <dia:enum val="0"/>
      </dia:attribute>
      <dia:attribute name="autorouting">
        <dia:boolean val="true"/>
      </dia:attribute>
      <dia:attribute name="name">
        <dia:string>##</dia:string>
      </dia:attribute>
      <dia:attribute name="direction">
        <dia:enum val="0"/>
      </dia:attribute>
      <dia:attribute name="ends">
        <dia:composite>
          <dia:attribute name="role">
            <dia:string>##</dia:string>
          </dia:attribute>
          <dia:attribute name="multiplicity">
            <dia:string>##</dia:string>
          </dia:attribute>
          <dia:attribute name="arrow">
            <dia:boolean val="false"/>
          </dia:attribute>
          <dia:attribute name="aggregate">
            <dia:enum val="0"/>
          </dia:attribute>
          <dia:attribute name="visibility">
            <dia:enum val="0"/>
          </dia:attribute>
        </dia:composite>
        <dia:composite>
          <dia:attribute name="role">
            <dia:string>##</dia:string>
          </dia:attribute>
          <dia:attribute name="multiplicity">
            <dia:string>##</dia:string>
          </dia:attribute>
          <dia:attribute name="arrow">
            <dia:boolean val="false"/>
          </dia:attribute>
          <dia:attribute name="aggregate">
            <dia:enum val="0"/>
          </dia:attribute>
          <dia:attribute name="visibility">
            <dia:enum val="0"/>
          </dia:attribute>
        </dia:composite>
      </dia:attribute>
      <dia:connections>
        <dia:connection handle="0" to="O[% relation.left %]" connection="8"/>
        <dia:connection handle="1" to="O[% relation.right %]" connection="8"/>
      </dia:connections>
    </dia:object>
[% END %]

 </dia:layer>
</dia:diagram>
END_TEMPLATE

    return \$template;
}

1;

##################################################################

=head2 See Also

Autodia

Autodia::Diagram::Object

Autodia::Diagram::Class 

Autodia::Diagram::Superclass 

Autodia::Diagram::Component 

Autodia::Diagram::Inheritance

Autodia::Diagram::Relation

Autodia::Diagram::Dependancy

=head1 AUTHOR

Aaron Trevena, E<lt>aaron.trevena@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Aaron Trevena

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

########################################################################






